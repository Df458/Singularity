/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2017  Hugues Ross <hugues.ross@gmail.com>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
using Gee;

const string APP_ID = "org.df458.singularity";

namespace Singularity
{
// The primary application class
public class SingularityApp : Gtk.Application
{
    public enum LoadStatus
    {
        NOT_STARTED,
        STARTED,
        COMPLETED,
        FAILED,
        COUNT
    }

    // Public section ---------------------------------------------------------
    public bool init_success { get; private set; }
    public bool has_subscriptions { get { return m_feeds.nodes.size > 0; } }
    private Gdk.Pixbuf icon { get; private set; }

    private MainLoop ml;
    public uint timeout_value = 600;
    public bool update_running = true;
    public uint update_next = 600;

    public SingularityApp()
    {
        Object(application_id: APP_ID);

        this.startup.connect(start_run);
        this.activate.connect(activate_response);
        this.shutdown.connect(cleanup);
    }

    public void opml_import(File file)
    {
        Xml.Doc* doc = Xml.Parser.parse_file(file.get_path());
        if(doc == null) {
            warning("Can't parse XML file");
            return;
        }
        OPMLFeedDataSource opml = new OPMLFeedDataSource();
        opml.parse_data(doc);
        foreach(CollectionNode node in opml.data) {
            if(node.data is Feed)
                subscribe_to_feed(node.data as Feed, false);
            else
                add_collection(node.data as FeedCollection);
        }
        delete doc; // FIXME: Some stray docs may be floating around from older xml code. Kill them.
    }

    public void opml_export(File file)
    {
        OPMLFeedDataSource opml = new OPMLFeedDataSource();
        Xml.Doc* doc = opml.encode_data(m_feeds.nodes);

        /* XmlDocWriter.write_document(doc, file); */
        FileStream fstream = FileStream.open(file.get_path(), "w");
        doc->dump(fstream);
    }

    public void update_settings()
    {
        /* AppSettings.set_boolean("auto-update", auto_update); */
        /* AppSettings.set_boolean("start-update", start_update); */
        /* AppSettings.set_uint("auto-update-freq", timeout_value / 60); */
        /* AppSettings.set_value("unread-rule", new Variant("(iii)",unread_rule[0],unread_rule[1],unread_rule[2])); */
        /* AppSettings.set_value("read-rule", new Variant("(iii)",read_rule[0],read_rule[1],read_rule[2])); */
        /* AppSettings.set_boolean("download-attachments", download_attachments); */
        /* AppSettings.set_boolean("ask-download-location", get_location); */
        /* AppSettings.set_string("default-download-location", default_location); */
        /* AppSettings.set_string("link-command", link_command); */
        AppSettings.save();
        m_update_queue.update_cookie_path();
        if(AppSettings.auto_update && !update_running) {
            update_running = true;
            update_next = timeout_value;
            /* Timeout.add_seconds(timeout_value, update); */
        }
    }

    public int runall()
    {
        if(!AppSettings.Arguments.background)
            Gtk.main();
        else {
            ml = new MainLoop();
            TimeoutSource time = new TimeoutSource(900000);
            time.set_callback(() => {
                stderr.printf("Operation is taking too long. Exiting...\n");
                ml.quit();
                return false;
            });
            TimeoutSource counter = new TimeoutSource(5000);
            counter.set_callback(() => {
                return true;
            });
            time.attach(ml.get_context());
            counter.attach(ml.get_context());
            ml.run();
        }
        return 0;
    }

    public void exit()
    {
    }

    public CollectionTreeStore get_feed_store()
    {
        return m_feed_store;
    }

    public void subscribe_to_feed(Feed f, bool loaded, FeedCollection? parent = null, Gee.List<Item?>? items = null)
    {
        CollectionNode node = new CollectionNode(f);
        node.data.parent = parent;

        SubscribeRequest req = new SubscribeRequest(node);
        m_database.execute_request.begin(req, RequestPriority.MEDIUM, () =>
        {
            Gtk.TreeIter? iter = null;

            // FIXME: Looks suspicious. Did I miss something?
            m_feed_store.append_node(node, iter);
            if(!loaded) {
                m_update_queue.request_update(f, true);
            } else if(items != null){
                foreach(Item i in items)
                    f.add_item(i);
                UpdatePackage new_package = new UpdatePackage.success(f, items, new ArrayList<Item?>());
                UpdatePackageRequest ureq = new UpdatePackageRequest(new_package, false);
                m_database.execute_request.begin(ureq, RequestPriority.MEDIUM, () =>
                {
                    m_feed_store.set_unread_count(ureq.unread_count, new_package.feed.id, false);
                });
            }

            subscribe_done(f);
        });
    }

    public void add_collection(FeedCollection c, FeedCollection? parent = null)
    {
        CollectionNode node = new CollectionNode(c);
        node.data.parent = parent;

        SubscribeRequest req = new SubscribeRequest(node);
        m_database.execute_request.begin(req, RequestPriority.MEDIUM, () =>
        {
            // FIXME: Looks suspicious. Did I miss something?
            Gtk.TreeIter? iter = null;

            m_feed_store.append_node(node, iter);
        });
    }

    public void check_for_updates(bool force = false)
    {
        if(m_feed_store == null)
            return;

        m_feed_store.foreach((model, path, iter) =>
        {
            Feed? feed = m_feed_store.get_data_from_iter(iter) as Feed;
            if(feed != null && (feed.should_update || force)) {
                m_update_queue.request_update(feed);
                m_current_update_progress.updates_started();
            } 

            return false;
        });

        update_progress_changed(m_current_update_progress);
    }

    public void view_items(Item[] items)
    {
        string[] guids = new string[items.length];
        for(int i = 0; i < items.length; ++i) {
            m_feed_store.set_unread_count(-1, items[i].owner.id, true);
            items[i].unread = false;
            guids[i] = items[i].guid;
        }
        ItemViewRequest req = new ItemViewRequest(guids);
        m_database.queue_request(req);
    }

    public void toggle_unread(Item i)
    {
        ItemToggleRequest req = new ItemToggleRequest(i.guid, ItemToggleRequest.ToggleField.UNREAD);
        m_feed_store.set_unread_count(i.unread ? -1 : 1, i.owner.id, true);
        m_database.queue_request(req);

        i.unread = !i.unread;
    }

    public void toggle_star(Item i)
    {
        ItemToggleRequest req = new ItemToggleRequest(i.guid, ItemToggleRequest.ToggleField.STARRED);
        m_database.queue_request(req);
        m_feed_store.set_unread_count(-1, i.owner.id, true);
    }

    // Signals ----------------------------------------------------------------
    public signal void load_status_changed(LoadStatus status);
    public signal void update_progress_changed(UpdateProgress val);
    public signal void subscribe_done(Feed f);

    // Private section --------------------------------------------------------
    private DatabaseManager        m_database;
    private FeedCollection         m_feeds;
    private CollectionTreeStore?   m_feed_store = null;
    private UpdateQueue            m_update_queue;
    private UpdateProgress         m_current_update_progress;

    private void start_run()
    {
        AppSettings.load(APP_ID);

        m_database = new DatabaseManager.from_path(AppSettings.Arguments.database_path);
        load_status_changed(LoadStatus.STARTED);
        m_update_queue = new UpdateQueue();
        m_current_update_progress = UpdateProgress();

        m_update_queue.update_processed.connect((pak) =>
        {
            if(pak.contents == UpdatePackage.PackageContents.FEED_UPDATE) {
                UpdatePackageRequest req = new UpdatePackageRequest(pak);
                m_database.execute_request.begin(req, RequestPriority.DEFAULT, () =>
                {
                    m_current_update_progress.updates_finished();
                    update_progress_changed(m_current_update_progress);
                    if(req.unread_count != 0)
                        m_feed_store.set_unread_count(req.unread_count, pak.feed.id);
                });
            } else if(pak.contents == UpdatePackage.PackageContents.ERROR_DATA) {
                warning("Can't update feed %s: %s", pak.feed.to_string(), pak.message);
                m_feed_store.set_failed(pak.feed.id);
                m_current_update_progress.updates_finished();
                update_progress_changed(m_current_update_progress);
            }
        });

        LoadFeedsRequest req = new LoadFeedsRequest();
        m_database.execute_request.begin(req, RequestPriority.HIGH, () =>
        {
            m_feeds = req.feeds;
            if(m_feed_store == null)
                m_feed_store = new CollectionTreeStore.from_collection(m_feeds);
            else
                m_feed_store.append_root_collection(m_feeds);

            foreach(Gee.Map.Entry<int, int> e in req.count_map.entries) {
                m_feed_store.set_unread_count(e.value, e.key);
            }

            if(AppSettings.start_update)
                check_for_updates();

            load_status_changed(LoadStatus.COMPLETED);
            init_success = true;
        });

        GLib.SimpleAction import_action = new GLib.SimpleAction("import", null);
        import_action.activate.connect(() => {
            ImportDialog dialog = new ImportDialog(get_active_window());
            dialog.import_request.connect(opml_import);
            dialog.run();
        });
        add_action(import_action);

        GLib.SimpleAction export_action = new GLib.SimpleAction("export", null);
        export_action.activate.connect(() => {
            ExportDialog dialog = new ExportDialog(get_active_window());
            dialog.export_request.connect(opml_export);
            dialog.run();
        });
        add_action(export_action);

        GLib.SimpleAction update_action = new GLib.SimpleAction("check_full", null);
        update_action.activate.connect(() => { check_for_updates(); });
        add_action(update_action);

        GLib.SimpleAction preferences_action = new GLib.SimpleAction("preferences", null);
        preferences_action.activate.connect(() => { (get_active_window() as MainWindow).preferences(); });
        add_action(preferences_action);

        GLib.SimpleAction about_action = new GLib.SimpleAction("about", null);
        about_action.activate.connect(() => {
            Gtk.show_about_dialog(get_active_window(),
                program_name: "Singularity",
                logo: icon,
                authors: new string[]{ "Hugues Ross (df458)" },
                website: "http://github.com/Df458/Singularity",
                website_label: ("Github"),
                comments: "A simple webfeed aggregator",
                version: "0.3",
                license_type: (Gtk.License.GPL_3_0),
                copyright: "Copyright © 2014-2017 Hugues Ross"
            );
        });
        add_action(about_action);

        GLib.SimpleAction quit_action = new GLib.SimpleAction("quit", null);
        quit_action.activate.connect(this.quit);
        set_accels_for_action("quit", { "<Control>q", null });
        add_action(quit_action);

        try {
            icon = new Gdk.Pixbuf.from_resource("/org/df458/Singularity/icon.svg");
        } catch(Error e) {
            warning(e.message);
        }
    }

    private void activate_response()
    {
        if(m_feed_store == null) {
            m_feed_store = new CollectionTreeStore();
            m_feed_store.parent_changed.connect((node, id) =>
            {
                UpdateParentRequest req = new UpdateParentRequest(node, id);
                m_database.execute_request.begin(req, RequestPriority.HIGH);
            });
        }

        MainWindow window = new MainWindow(this);
        window.icon = icon;
        window.update_requested.connect((f) =>
        {
            if(f != null) {
                m_update_queue.request_update(f, true);
                m_current_update_progress.updates_started();
                update_progress_changed(m_current_update_progress);
            }
        });

        window.unsub_requested.connect((f) =>
        {
            if(f != null) {
                UnsubscribeRequest req = new UnsubscribeRequest(f);
                m_database.execute_request.begin(req, RequestPriority.HIGH, () =>
                {
                    m_feed_store.remove_data(f);
                });
            }
        });

        window.delete_collection_requested.connect((c) =>
        {
            if(c != null) {
                DeleteCollectionRequest req = new DeleteCollectionRequest(c);
                m_database.execute_request.begin(req, RequestPriority.HIGH, () =>
                {
                    m_feed_store.remove_data(c);
                });
            }
        });

        window.new_collection_requested.connect((parent) =>
        {
            CollectionRequest req = new CollectionRequest(new CollectionNode(new FeedCollection("Untitled")), parent.id);
            m_database.execute_request.begin(req, RequestPriority.HIGH, () =>
            {
                m_feed_store.append_node(req.node, m_feed_store.get_iter_from_data(parent));
            });
        });

        window.rename_node_requested.connect((node, title) =>
        {
            RenameRequest req = new RenameRequest(node, title);
            m_database.execute_request.begin(req, RequestPriority.HIGH, () =>
            {
                node.data.title = title;
                m_feed_store.set(m_feed_store.get_iter_from_node(node), CollectionTreeStore.Column.TITLE, title, -1);
            });
        });

        this.add_window(window);
    }

    private void cleanup()
    {
    }
}

// Item for tracking the feed update status
public struct UpdateProgress
{
    public SingularityApp.LoadStatus status { get; private set;}
    public float percentage { get; private set;}
    public int update_count { get; private set;}
    public int finished_count { get; private set;}

    public UpdateProgress()
    {
        status = SingularityApp.LoadStatus.NOT_STARTED;
        percentage = 0;
        update_count = 0;
        finished_count = 0;
    }

    public void updates_started(int count = 1)
    {
        update_count += count;

        if(status != SingularityApp.LoadStatus.STARTED) {
            status = SingularityApp.LoadStatus.STARTED;
            update_count = count;
            finished_count = 0;
            percentage = 0;
        }

        calcPercentage();
    }

    public void updates_finished(int count = 1)
    {
        finished_count += count;
        if(update_count <= finished_count) {
            update_count = finished_count;
            status = SingularityApp.LoadStatus.COMPLETED;
        }

        calcPercentage();
    }

    private void calcPercentage()
    {
        float p;
        if(update_count == 0)
            p = 0;
        else
            p = (float)finished_count / (float)update_count;

        percentage = p;
    }
}
}
