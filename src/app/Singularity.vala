/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

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

static const string APP_ID = "org.df458.singularity";

namespace Singularity
{

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

    private MainLoop ml;
    public uint timeout_value = 600;
    public bool update_running = true;
    public uint update_next = 600;

    public SingularityApp(SessionSettings settings)
    {
        Object(application_id: APP_ID);

        m_global_settings = new GlobalSettings(APP_ID);
        m_session_settings = settings;

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
            if(node.contents == CollectionNode.Contents.FEED)
                subscribe_to_feed(node.feed, false);
            else if(node.contents == CollectionNode.Contents.COLLECTION)
                add_collection(node.collection);
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
        /* m_global_settings.set_boolean("auto-update", auto_update); */
        /* m_global_settings.set_boolean("start-update", start_update); */
        /* m_global_settings.set_uint("auto-update-freq", timeout_value / 60); */
        /* m_global_settings.set_value("unread-rule", new Variant("(iii)",unread_rule[0],unread_rule[1],unread_rule[2])); */
        /* m_global_settings.set_value("read-rule", new Variant("(iii)",read_rule[0],read_rule[1],read_rule[2])); */
        /* m_global_settings.set_boolean("download-attachments", download_attachments); */
        /* m_global_settings.set_boolean("ask-download-location", get_location); */
        /* m_global_settings.set_string("default-download-location", default_location); */
        /* m_global_settings.set_string("link-command", link_command); */
        m_global_settings.save();
        if(m_global_settings.auto_update && !update_running) {
            update_running = true;
            update_next = timeout_value;
            /* Timeout.add_seconds(timeout_value, update); */
        }
    }

    public void update_feed_settings(Feed f)
    {
        // TODO: Re-enable once feed rules are updated
        //string outrule = "%d %d %d\n%d %d %d\n%d %d %d\n%d %d %d".printf(f.unread_unstarred_rule[0], f.unread_unstarred_rule[1], f.unread_unstarred_rule[2], f.unread_starred_rule[0], f.unread_starred_rule[1], f.unread_starred_rule[2], f.read_unstarred_rule[0], f.read_unstarred_rule[1], f.read_unstarred_rule[2], f.read_starred_rule[0], f.read_starred_rule[1], f.read_starred_rule[2]);
        //if(!f.override_rules)
            //outrule = "";
        //m_database.updateFeedSettings.begin(f, outrule);
    }

    // TODO: Make this take a query object with more limits and settings
    public async Gee.List<Item?> query_items(CollectionNode? node, bool unread_only, bool starred_only)
    {
        ItemListRequest req = new ItemListRequest(node);
        if(unread_only) {
            if(starred_only)
                req.item_filter = ItemListRequest.Filter.UNREAD_AND_STARRED;
            else
                req.item_filter = ItemListRequest.Filter.UNREAD_ONLY;
        } else if(starred_only)
                req.item_filter = ItemListRequest.Filter.STARRED_ONLY;
        yield m_database.execute_request(req);

        foreach(Item i in req.item_list) {
            i.owner = m_feed_store.get_feed_from_id(req.item_id_map[i]);
        }

        return req.item_list;
    }

    public int runall()
    {
        if(!m_session_settings.background)
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
            // TODO: verbose
                /* if(verbose) */
                /*     stderr.printf("Loading %d feeds...\n", load_counter); */
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
        // TODO: Figure out a way to pass loaded items along
        CollectionNode node = new CollectionNode.with_feed(f);
        if(parent != null)
            node.set_parent(parent);

        SubscribeRequest req = new SubscribeRequest(node);
        m_database.execute_request.begin(req, RequestPriority.MEDIUM, () =>
        {
            Gtk.TreeIter? iter = null;

            m_feed_store.append_node(node, iter);
            if(!loaded) {
                m_update_queue.request_update(f, true);
            } else if(items != null){
                foreach(Item i in items) {
                    i.owner = node.feed;
                }
                UpdatePackage new_package = new UpdatePackage.success(node.feed, items);
                UpdatePackageRequest ureq = new UpdatePackageRequest(new_package, m_global_settings, false);
                m_database.queue_request(ureq, RequestPriority.MEDIUM);
            }
        });
    }

    public void add_collection(FeedCollection c, FeedCollection? parent = null)
    {
        CollectionNode node = new CollectionNode.with_collection(c);
        if(parent != null)
            node.set_parent(parent);

        SubscribeRequest req = new SubscribeRequest(node);
        m_database.execute_request.begin(req, RequestPriority.MEDIUM, () =>
        {
            Gtk.TreeIter? iter = null;

            m_feed_store.append_node(node, iter);
            // TODO: Figure out how to get the new feeds and update them
        });
    }

    public void check_for_updates(bool force = false)
    {
        if(m_feed_store == null)
            return;

        m_feed_store.foreach((model, path, iter) =>
        {
            Feed? feed = m_feed_store.get_feed_from_iter(iter);
            if(feed != null && (feed.get_should_update() || force)) {
                m_update_queue.request_update(feed);
                m_current_update_progress.updates_started();
            } 

            return false;
        });

        update_progress_changed(m_current_update_progress);
    }

    public void view_item(Item i)
    {
        ItemViewRequest req = new ItemViewRequest(i.id);
        m_database.queue_request(req);
        m_feed_store.set_unread_count(-1, -1, true);
        m_feed_store.set_unread_count(-1, i.owner.id, true);
    }

    public void toggle_unread(Item i)
    {
        ItemToggleRequest req = new ItemToggleRequest(i.id, ItemToggleRequest.ToggleField.UNREAD);
        m_database.queue_request(req);
        m_feed_store.set_unread_count(-1, -1, true);
        m_feed_store.set_unread_count(-1, i.owner.id, true);
    }

    public void toggle_star(Item i)
    {
        ItemToggleRequest req = new ItemToggleRequest(i.id, ItemToggleRequest.ToggleField.STARRED);
        m_database.queue_request(req);
        m_feed_store.set_unread_count(-1, -1, true);
        m_feed_store.set_unread_count(-1, i.owner.id, true);
    }

    public GlobalSettings get_global_settings() { return m_global_settings; }

    // Signals ----------------------------------------------------------------
    public signal void load_status_changed(LoadStatus status);
    public signal void update_progress_changed(UpdateProgress val);

    // Private section --------------------------------------------------------
    private GlobalSettings         m_global_settings;
    private SessionSettings        m_session_settings;
    private DatabaseManager        m_database;
    private FeedCollection         m_feeds;
    private CollectionTreeStore?   m_feed_store = null;
    private UpdateQueue            m_update_queue;
    private LoadStatus             m_current_load_status = LoadStatus.NOT_STARTED;
    private UpdateProgress         m_current_update_progress;

    private void start_run()
    {
        DataLocator loc = new DataLocator(m_session_settings);
        m_global_settings.load();

        m_database = new DatabaseManager.from_path(m_global_settings, loc.data_location);
        load_status_changed(LoadStatus.STARTED);
        m_update_queue = new UpdateQueue();
        m_current_update_progress = UpdateProgress();

        m_update_queue.update_processed.connect((pak) =>
        {
            if(pak.contents == UpdatePackage.PackageContents.FEED_UPDATE) {
                UpdatePackageRequest req = new UpdatePackageRequest(pak, m_global_settings);
                m_database.execute_request.begin(req, RequestPriority.DEFAULT, () =>
                {
                    m_current_update_progress.updates_finished();
                    update_progress_changed(m_current_update_progress);
                    if(req.unread_count != 0) {
                        stderr.printf("S Unread: %d, %d\n", pak.feed.id, req.unread_count);
                        m_feed_store.set_unread_count(req.unread_count, -1, true);
                        m_feed_store.set_unread_count(req.unread_count, pak.feed.id, true);
                    }
                });
            } else if(pak.contents == UpdatePackage.PackageContents.ERROR_DATA) {
                warning("Can't update feed %s: %s", pak.feed.title, pak.message);
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

            m_feed_store.set_unread_count(req.unread_count);
            foreach(Gee.Map.Entry<int, int> e in req.count_map.entries) {
                m_feed_store.set_unread_count(e.value, e.key);
            }

            if(m_global_settings.start_update)
                check_for_updates();

            load_status_changed(LoadStatus.COMPLETED);
            init_success = true;
        });
    }

    private void activate_response()
    {
        if(m_feed_store == null)
            m_feed_store = new CollectionTreeStore();

        MainWindow window = new MainWindow(this);
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
                    m_feed_store.remove_feed(f);
                });
            }
        });
        this.add_window(window);
    }

    private void cleanup()
    {
    }
}

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
