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

class SingularityApp : Gtk.Application
{
    // Public section ---------------------------------------------------------
    public bool init_success { get { return m_init_success; } }




    private HashMap<int, Feed> feeds;
    private MainWindow main_window;

    private StreamViewBuilder  stream_builder;
    private GridViewBuilder    grid_builder;

    private MainLoop ml;
    string css_dat = "";
    private ArrayList<Item> view_list;
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
        for(MapIterator<int, Feed> iter = feeds.map_iterator(); should_continue && (iter.valid || iter.has_next()); should_continue = iter.next()) {
            if(!iter.valid)
                continue;
            feed_list.add(iter.get_value());
        }
        /* opml.export(file, feed_list); */
    }

    public Feed getFeed(int feed_index)
    {
        return feeds[feed_index];
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
            Timeout.add_seconds(timeout_value, update);
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

    public void addToView(Item i)
    {
        view_list.add(i);
    }

    public bool update()
    {
            // TODO: verbose
        /* if(verbose) */
        /*     stderr.printf("Running updates on %d feeds...\n", feeds.size); */
        bool should_continue = true;
        MapIterator<int, Feed> iter = feeds.map_iterator();
        do {
            if(!iter.valid) {
                should_continue = iter.next();
                continue;
            }
            Feed f = iter.get_value();
            /* m_database.loadFeedItems.begin(f, -1, (obj, res) => { */
            /*     load_counter++; */
            /*     f.updateFromWeb.begin(m_database, (obj, res) => { */
            /*         load_counter--; */
            /*         if(load_counter <= 0) { */
            /*             load_counter = 0; */
            /*             done_load = true; */
            /*             if(!m_session_settings.background) { */
            /*             // TODO: Readd this */
            /*                 //int unread_count = main_window.get_unread_count(); */
            /*                 //if(unread_count != 0) { */
            /*                     //try { */
            /*                         //update_complete_notification.update("Update Complete", "You have " + unread_count.to_string() + " unread item" + (unread_count > 1 ? "s." : "."), null); */
            /*                         //update_complete_notification.show(); */
            /*                     //} catch(GLib.Error e) { */
            /*                         //stderr.printf("Error displaying notification: %s.\n", e.message); */
            /*                     //} */
            /*                 //} */
            /*             } else { */
            /*                 ml.quit(); */
            /*             } */
            /*         } */
            /*     }); */
            /* }); */
            should_continue = iter.next();
        } while(should_continue);
        if(feeds.size == 0)
            done_load = true;
        update_running = m_global_settings.auto_update;
        if(update_running && update_next != timeout_value) {
            update_next = timeout_value;
            Timeout.add_seconds(timeout_value, update);
            return false;
        }
        return m_global_settings.auto_update;
    }

    // Private section --------------------------------------------------------
    private GlobalSettings         m_global_settings;
    private SessionSettings        m_session_settings;
    private DatabaseManager        m_database;
    private FeedCollection         m_feeds;
    private CollectionTreeStore    m_feed_store;
    private UpdateQueue            m_update_queue;
    private bool                   m_init_success = false;

    private void start_run()
    {
        DataLocator loc = new DataLocator(m_session_settings);
        if(loc.data_location == null)
           return;

        m_database = new DatabaseManager(m_session_settings, loc.data_location);
        m_database.load_feeds.begin((obj, res) =>
        {
            m_feeds = m_database.load_feeds.end(res);
            m_feed_store = new CollectionTreeStore.from_collection(m_feeds);

            m_init_success = true;
        });
    }

    private void activate_response()
    {
        // TODO: Create the window
    }

    private void cleanup()
    {
    }
}
}
