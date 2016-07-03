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
    string css_dat = "";
    bool done_load = false;
    int load_counter = 0;
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

    public void import(File file)
    {
        Xml.Doc* doc = Xml.Parser.parse_file(file.get_path());
        if(doc == null)
            return; // TODO: We should put an error here
        /* opml.import(doc->children); */
        delete doc; // FIXME: Some stray docs may be floating around from older xml code. Kill them.
    }

    public void export(File file)
    {
        // TODO: Make this a tree eventually
        ArrayList<Feed> feed_list = new ArrayList<Feed>();
        bool should_continue = true;
        /* for(MapIterator<int, Feed> iter = feeds.map_iterator(); should_continue && (iter.valid || iter.has_next()); should_continue = iter.next()) { */
        /*     if(!iter.valid) */
        /*         continue; */
        /*     feed_list.add(iter.get_value()); */
        /* } */
        /* opml.export(file, feed_list); */
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
    public async Gee.List<Item?> query_items(CollectionNode node, bool unread_only, bool starred_only)
    {
        return yield m_database.load_items_for_node(node, unread_only, starred_only);
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

    // Signals ----------------------------------------------------------------
    public signal void load_status_changed(LoadStatus status);

    // Private section --------------------------------------------------------
    private GlobalSettings         m_global_settings;
    private SessionSettings        m_session_settings;
    private DatabaseManager        m_database;
    private FeedCollection         m_feeds;
    private CollectionTreeStore?   m_feed_store = null;
    private UpdateQueue            m_update_queue;
    private LoadStatus             m_current_load_status = LoadStatus.NOT_STARTED;

    private void start_run()
    {
        DataLocator loc = new DataLocator(m_session_settings);

        m_database = new DatabaseManager(m_session_settings, loc.data_location);
        load_status_changed(LoadStatus.STARTED);
        m_update_queue = new UpdateQueue();

        m_update_queue.update_processed.connect((pak) =>
        {
            if(pak.contents == UpdatePackage.PackageContents.FEED_UPDATE) {
                m_database.save_updates(pak);
            } else if(pak.contents == UpdatePackage.PackageContents.ERROR_DATA) {
                warning("Can't update feed %s: %s", pak.feed.title, pak.message);
            }
        });

        m_database.load_feeds.begin((obj, res) =>
        {
            m_feeds = m_database.load_feeds.end(res);
            if(m_feed_store == null)
                m_feed_store = new CollectionTreeStore.from_collection(m_feeds);
            else
                m_feed_store.append_root_collection(m_feeds);

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
            if(f != null)
                m_update_queue.request_update(f);
        });
        this.add_window(window);
    }

    private void cleanup()
    {
    }
}
}
