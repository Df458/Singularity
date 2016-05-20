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
    private OPML opml;

    private StreamViewBuilder  stream_builder;
    private GridViewBuilder    grid_builder;

    private MainLoop ml;
    string css_dat = "";
    private ArrayList<Item> view_list;
    bool done_load = false;
    int load_counter = 0;
    public bool auto_update = true;
    public bool start_update = true;
    public uint timeout_value = 600;
    public bool update_running = true;
    public uint update_next = 600;
    public bool get_location = true;
    public string default_location;
    public string link_command = "xdg-open %s";
    public bool download_attachments = true;
    //public Notify.Notification update_complete_notification;
    //Count, Increment(d,m,y), action(nothing,read(unread only),delete)
    public int[] unread_rule = {0, 0, 0};
    public int[] read_rule   = {0, 0, 0};

    public SingularityApp(SessionSettings settings)
    {
        Object(application_id: APP_ID);

        m_global_settings = new Settings(APP_ID);
        m_session_settings = settings;

        this.startup.connect(start_run);
        this.shutdown.connect(cleanup);

        // feeds = new HashMap<int, Feed>();
        // opml = new OPML();
        //download_attachments = m_global_settings.get_boolean("download-attachments");
        //default_location = m_global_settings.get_string("default-download-location");
        //link_command = m_global_settings.get_string("link-command");
        //get_location = m_global_settings.get_boolean("ask-download-location");
        //if(default_location == "")
        //    default_location = Environment.get_home_dir() + "/Downloads";
        //auto_update = m_global_settings.get_boolean("auto-update");
        //start_update = m_global_settings.get_boolean("start-update");
        //if(settings.background) {
        //    auto_update = false;
        //    start_update = true;
        //}
        //timeout_value = m_global_settings.get_uint("auto-update-freq") * 60;
        //var u_val = m_global_settings.get_value("unread-rule");
        //var u_iter = u_val.iterator();
        //u_iter.next("i", &unread_rule[0]);
        //u_iter.next("i", &unread_rule[1]);
        //u_iter.next("i", &unread_rule[2]);
        //var r_val = m_global_settings.get_value("read-rule");
        //var r_iter = r_val.iterator();
        //r_iter.next("i", &read_rule[0]);
        //r_iter.next("i", &read_rule[1]);
        //r_iter.next("i", &read_rule[2]);

        //Notify.init("Singularity");
        //update_complete_notification = new Notify.Notification("Update Complete", "You have new feeds", null);

        //m_database.loadFeeds.begin((obj, res) =>{
        //    ArrayList<Feed> feed_list = m_database.loadFeeds.end(res);
        //    foreach(Feed f in feed_list) {
        //        feeds.set(f.id, f);
        //    }
        //    if(main_window != null)
        //        main_window.add_feeds(feed_list);
        //    if(start_update)
        //        update();
        //    else {
        //        bool should_continue = true;
        //        MapIterator<int, Feed> iter = feeds.map_iterator();
        //        do {
        //            if(!iter.valid) {
        //                should_continue = iter.next();
        //                continue;
        //            }
        //            Feed f = iter.get_value();
        //            m_database.loadFeedItems.begin(f, -1, (obj, res) => {
        //                updateFeedItems(f);
        //            });
        //            int unread_count = main_window.get_unread_count();
        //            if(unread_count != 0) {
        //                try {
        //                    update_complete_notification.update("Update Complete", "You have " + unread_count.to_string() + " unread item" + (unread_count > 1 ? "s." : "."), null);
        //                    update_complete_notification.show();
        //                } catch(GLib.Error e) {
        //                    stderr.printf("Error displaying notification: %s.\n", e.message);
        //                }
        //            }
        //            should_continue = iter.next();
        //        } while(should_continue);
        //    }
        //});
        //if(!settings.background) {
        //    File file = File.new_for_path(settings.user_css);
        //    if(!file.query_exists()) {
        //        warning("Custom CSS path(" + settings.user_css + ") not found. Reverting to default.");
        //        file = File.new_for_path("/usr/local/share/singularity/default.css");
        //    }
        //    try {
        //        DataInputStream stream = new DataInputStream(file.read());
        //        string indat;
        //        while((indat = stream.read_line()) != null)
        //            css_dat += indat;
        //    } catch (Error e) {
        //        error("%s", e.message);
        //    }

        //    main_window = new MainWindow(this);
        //    view_list = new ArrayList<Item>();
        //    if(auto_update)
        //        Timeout.add_seconds(timeout_value, update);

        //    stream_builder = new StreamViewBuilder(css_dat, star_icon_base64);
        //    grid_builder = new GridViewBuilder(css_dat, star_icon_base64);
        //}
    }

    /* public string constructFeedHtml(int feed_id, ViewType view) */
    /* { */
    /*     view_list.clear(); */
    /*     //string html_str = "<html><head><style>" + css_dat + "</style></head><body>" + feeds[feed_id].constructHtml(m_database) + js_str + "</body></html>"; */
    /*     ViewBuilder? chosen_builder = null; */
    /*     switch(view) { */
    /*         case ViewType.STREAM: */
    /*             chosen_builder = stream_builder; */
    /*             break; */
    /*         case ViewType.GRID: */
    /*             chosen_builder = grid_builder; */
    /*             break; */
    /*     } */
    /*     if(chosen_builder == null) */
    /*         return ""; */
    /*     string html_str = chosen_builder.buildHTML(feeds[feed_id].items); */
    /*     main_window.updateFeedItem(feeds[feed_id], feed_id); */
    /*     return html_str; */
    /* } */

    /* public string constructUnreadHtml() */
    /* { */
    /*     view_list.clear(); */
    /*     string html_str = "<html><head><style>" + css_dat + "</style></head><body><br/>"; */
    /*     bool should_continue = true; */
    /*     for(MapIterator<int, Feed> iter = feeds.map_iterator(); should_continue && (iter.valid || iter.has_next()); should_continue = iter.next()) { */
    /*         if(!iter.valid) */
    /*             continue; */
    /*         Feed f = iter.get_value(); */
    /*         html_str += f.constructUnreadHtml(m_database); */
    /*     } */
    /*     html_str += js_str + "</body></html>"; */
    /*     return html_str; */
    /* } */

    public string constructFrontPage()
    {
        view_list.clear();
        string html_str = "<html><head><style>" + css_dat + "</style></head><body>" + js_str + "</body></html>";
        return html_str;
    }

    /* public string constructAllHtml() */
    /* { */
    /*     view_list.clear(); */
    /*     string html_str = "<html><head><style>" + css_dat + "</style></head><body>"; */
    /*     bool should_continue = true; */
    /*     for(MapIterator<int, Feed> iter = feeds.map_iterator(); should_continue && (iter.valid || iter.has_next()); should_continue = iter.next()) { */
    /*         if(!iter.valid) */
    /*             continue; */
    /*         Feed f = iter.get_value(); */
    /*         html_str += f.constructHtml(m_database); */
    /*         main_window.updateFeedItem(f, f.id); */
    /*     } */
    /*     html_str += js_str + "</body></html>"; */
    /*     return html_str; */
    /* } */

    /* public string constructStarredHtml() */
    /* { */
    /*     view_list.clear(); */
    /*     string html_str = "<html><head><style>" + css_dat + "</style></head><body><br/>"; */
    /*     bool should_continue = true; */
    /*     for(MapIterator<int, Feed> iter = feeds.map_iterator(); should_continue && (iter.valid || iter.has_next()); should_continue = iter.next()) { */
    /*         if(!iter.valid) */
    /*             continue; */
    /*         Feed f = iter.get_value(); */
    /*         html_str += f.constructStarredHtml(m_database); */
    /*     } */
    /*     html_str += js_str + "</body></html>"; */
    /*     return html_str; */
    /* } */

    public void import(File file)
    {
        Xml.Doc* doc = Xml.Parser.parse_file(file.get_path());
        if(doc == null)
            return; // TODO: We should put an error here
        opml.import(doc->children);
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
        opml.export(file, feed_list);
    }

    // TODO: Separate this from subscription so that it just returns a new feed
    /* public void createFeed(string url, string? title = null) */
    /* { */
    /*     Feed f = new Feed(m_database.next_id); */
    /*     m_database.next_id++; */
    /*     f.origin_link = url; */
    /*     if(title != null) */
    /*         f.title = title; */
    /*     m_database.addFeed(f); */
    /*         // TODO: verbose */
    /*     //getXmlData.begin(url, (obj, res) => { */
    /*         //Xml.Doc* doc = getXmlData.end(res); */
    /*         //if(doc == null || doc->get_root_element() == null) { */
    /*             //stderr.printf("Error: doc is null\n"); */
    /*             //return; */
    /*         //} */
    /*         //Feed f = new Feed.from_xml(doc->get_root_element(), url, m_database.next_id); */
    /*     f.updateFromWeb.begin(m_database, () => */
    /*     { */
    /*         //if(f.status == 3) */
    /*             //return; */
    /*         //m_database.saveFeed.begin(f); */
    /*         feeds.set(f.id, f); */
    /*         main_window.add_feed(f, f.id); */
    /*         //main_window.updateFeedItem(f, f.id); */
    /*     }); */
    /*     //}); */
    /* } */

    public Feed getFeed(int feed_index)
    {
        return feeds[feed_index];
    }

    /* public void removeFeed(int feed_index) */
    /* { */
    /*     Feed f; */
    /*     feeds.unset(feed_index, out f); */
    /*     m_database.removeFeed.begin(f); */
    /* } */

    public void update_settings()
    {
        m_global_settings.set_boolean("auto-update", auto_update);
        m_global_settings.set_boolean("start-update", start_update);
        m_global_settings.set_uint("auto-update-freq", timeout_value / 60);
        m_global_settings.set_value("unread-rule", new Variant("(iii)",unread_rule[0],unread_rule[1],unread_rule[2]));
        m_global_settings.set_value("read-rule", new Variant("(iii)",read_rule[0],read_rule[1],read_rule[2]));
        m_global_settings.set_boolean("download-attachments", download_attachments);
        m_global_settings.set_boolean("ask-download-location", get_location);
        m_global_settings.set_string("default-download-location", default_location);
        m_global_settings.set_string("link-command", link_command);
        if(auto_update && !update_running) {
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

    /* public void updateFeedItems(Feed f) */
    /* { */
    /*     if(!m_session_settings.background) */
    /*         main_window.updateFeedItem(f, f.id); */
    /* } */

/*     public void interpretUriEncodedAction(string action) */
/*     { */
/*         string[] args = action.split("/"); */
/*             // TODO: verbose */
/*         switch(args[0]) { */
/*             case "read": */
/*                 int pos = int.parse(args[1]); */
/*                 Gee.ArrayList<Item> to_mark = new Gee.ArrayList<Item>(); */
/*                 for(int i = 0; i <= pos; ++i) { */
/*                     if(view_list[i].unread == true) { */
/*                         view_list[i].unread = false; */
/*                         to_mark.add(view_list[i]); */
/*                     } */
/*                 } */
/*                 m_database.updateUnread.begin(new Feed(), to_mark, () => { */
/*                     foreach(var item in to_mark) { */
/*                         item.feed.removeUnreadItem(item); */
/*                         updateFeedItems(item.feed); */
/*                     } */
/*                 }); */
/*             break; */
/*  */
/*             case "toggleRead": */
/* //:TODO: 29.12.14 14:30:40, df458 */
/* // Finish this when the time to add a button for this feature arrives */
/* // For now, it shouldn't save this change, so nothing permanent should happen */
/* // if it gets activated by accident :) */
/*                 int pos = int.parse(args[1]); */
/*                 view_list[pos].unread = !view_list[pos].unread; */
/*             break; */
/*             case "toggleStarred": */
/*                 int pos = int.parse(args[1]); */
/*                 Feed f = view_list[pos].feed; */
/*                 f.toggleStar(view_list[pos]); */
/*                 m_database.updateStarred.begin(f, view_list[pos]); */
/*             break; */
/*         } */
/*     } */

    /* public void downloadAttachment(string att) */
    /* { */
    /*     bool getl = get_location; */
    /*     string default_loc = default_location; */
    /*  */
    /*     int id = -1; */
    /*     string action = ""; */
    /*     att.scanf("%d_", &id); */
    /*     action = att.substring(id.to_string().length + 1); */
    /*     Feed tocheck = null; */
    /*     tocheck = feeds.get(id); */
    /*     if(tocheck != null && tocheck.override_location) { */
    /*         getl = tocheck.get_location; */
    /*         default_loc = tocheck.default_location; */
    /*     } */
    /*     try { */
    /*         if(!download_attachments) */
    /*             GLib.Process.spawn_command_line_async("xdg-open " + action); */
    /*         else { */
    /*             if(getl) { */
    /*                 Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog("Download attachment", main_window, Gtk.FileChooserAction.SELECT_FOLDER, "Cancel", Gtk.ResponseType.CANCEL, "Download here", Gtk.ResponseType.ACCEPT); */
    /*                 dialog.set_current_folder(default_loc); */
    /*                 if(dialog.run() == Gtk.ResponseType.ACCEPT) { */
    /*                     GLib.Process.spawn_command_line_async("wget -b -o'/tmp/singularity-wget-log' -P '" + dialog.get_filename() +  "' '" + action + "'"); */
    /*                 } */
    /*                 dialog.close(); */
    /*             } else */
    /*                 GLib.Process.spawn_command_line_async("wget -b -P '" + default_loc +  "' '" + action + "'"); */
    /*         } */
    /*     } catch(GLib.SpawnError e) { */
    /*         stderr.printf("Failed to spawn %s: %s\n", (download_attachments ? "wget" : "xdg-open"), e.message); */
    /*     } */
    /* } */

    /* public void markAllAsRead() */
    /* { */
    /*     stdout.printf("Clearing %d items:\n", view_list.size); */
    /*     Gee.ArrayList<Item> to_mark = new Gee.ArrayList<Item>(); */
    /*     for(int i = 0; i < view_list.size; ++i) { */
    /*         if(view_list[i].unread == true) { */
    /*             view_list[i].unread = false; */
    /*             to_mark.add(view_list[i]); */
    /*         } */
    /*     } */
    /*     m_database.updateUnread.begin(new Feed(), to_mark, () => { */
    /*         stdout.printf("Removing items\n"); */
    /*         foreach(var item in to_mark) { */
    /*             item.feed.removeUnreadItem(item); */
    /*             updateFeedItems(item.feed); */
    /*         } */
    /*         stdout.printf("Items removed\n"); */
    /*     }); */
    /*     stdout.printf("done. Waiting...\n"); */
    /* } */

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
        update_running = auto_update;
        if(update_running && update_next != timeout_value) {
            update_next = timeout_value;
            Timeout.add_seconds(timeout_value, update);
            return false;
        }
        return auto_update;
    }



    // Private section --------------------------------------------------------
    private Settings m_global_settings;
    private SessionSettings m_session_settings;
    private DatabaseManager m_database;
    private bool m_init_success = false;

    private void start_run()
    {
        if(!prepare_data_directory())
            return;

        // TODO: Removal time should be variable
        m_database = new DatabaseManager(m_session_settings);
        m_database.removeOldItems.begin(new DateTime.now_utc().add_months(-1));

        m_init_success = true;
    }

    private void activate_response()
    {
        // TODO: Create the window
    }

    private void cleanup()
    {
    }

    // TODO: Refactor this function to be in its own path class
    private bool prepare_data_directory()
    {
        string? default_data_path = Environment.get_user_data_dir() + "/singularity";
        try {
            File default_data_file = File.new_for_path(default_data_path);
            if(!default_data_file.query_exists()) {
                if(m_session_settings.verbose)
                    stderr.printf("Default data location does not exist, and will be created.\n");
                default_data_file.make_directory_with_parents();
            }
        } catch(Error e) {
            stderr.printf("Error: Failed to initialize the directory at %s: %s\n", default_data_path, e.message);
            return false;
        }

        return true;
    }
}
}
