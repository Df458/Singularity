/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2014  Hugues Ross <hugues.ross@gmail.com>

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

// modules: webkit2gtk-4.0 libsoup-2.4 granite libxml-2.0 sqlheavy-0.1 glib-2.0 gee-0.8

using Gee;

class Singularity : Gtk.Application {
    private ArrayList<Feed> feeds;
    private DatabaseManager db_man;
    private MainWindow main_window;
    string css_dat = "";
    private ArrayList<Item> view_list;
    private Settings app_settings;
    public bool auto_update = true;
    public uint timeout_value = 600;
    public bool update_running = true;
    public uint update_next = 600;
    public bool get_location = true;
    public string default_location;
    public bool download_attachments = true;
    //Count, Increment(m,h,d,m,y), action(nothing,read/unread,star/unstar,delete)
    public int[] unread_unstarred_rule = {0, 0, 0}; //1 week, read
    public int[] unread_starred_rule   = {0, 0, 0}; //nothing
    public int[] read_unstarred_rule   = {0, 0, 0}; //1 month, delete
    public int[] read_starred_rule     = {0, 0, 0}; //6 months, unstar

    public Singularity() {
        Object(application_id: "org.df458.singularity");
        Granite.Services.Paths.initialize("singularity", Environment.get_user_data_dir());
        Granite.Services.Paths.ensure_directory_exists(Granite.Services.Paths.user_data_folder);
        app_settings = new Settings("org.df458.singularity");
        download_attachments = app_settings.get_boolean("download-attachments");
        default_location = app_settings.get_string("default-download-location");
        get_location = app_settings.get_boolean("ask-download-location");
        if(default_location == "")
            default_location = Environment.get_home_dir() + "/Downloads";
        auto_update = app_settings.get_boolean("auto-update");
        timeout_value = app_settings.get_uint("auto-update-freq") * 60;
        var uu_val = app_settings.get_value("unread-unstarred-rule");
        var uu_iter = uu_val.iterator();
        uu_iter.next("i", &unread_unstarred_rule[0]);
        uu_iter.next("i", &unread_unstarred_rule[1]);
        uu_iter.next("i", &unread_unstarred_rule[2]);
        var us_val = app_settings.get_value("unread-starred-rule");
        var us_iter = us_val.iterator();
        us_iter.next("i", &unread_starred_rule[0]);
        us_iter.next("i", &unread_starred_rule[1]);
        us_iter.next("i", &unread_starred_rule[2]);
        var ru_val = app_settings.get_value("read-unstarred-rule");
        var ru_iter = ru_val.iterator();
        ru_iter.next("i", &read_unstarred_rule[0]);
        ru_iter.next("i", &read_unstarred_rule[1]);
        ru_iter.next("i", &read_unstarred_rule[2]);
        var rs_val = app_settings.get_value("read-starred-rule");
        var rs_iter = rs_val.iterator();
        rs_iter.next("i", &read_starred_rule[0]);
        rs_iter.next("i", &read_starred_rule[1]);
        rs_iter.next("i", &read_starred_rule[2]);

        //if(args.length > 1)
            //db_path = args[1];
        //if(args.length > 2)
            //css_path = args[2];
        db_man = new DatabaseManager.from_path(db_path);
        File file = File.new_for_path(css_path);
        if(!file.query_exists()) {
            warning("Custom CSS path(" + css_path + ") not found. Reverting to default.");
            file = File.new_for_path("/usr/local/share/singularity/default.css");
        }
        try {
            DataInputStream stream = new DataInputStream(file.read());
            string indat;
            while((indat = stream.read_line()) != null)
            css_dat += indat;
        } catch (Error e) {
            error("%s", e.message);
        }

        db_man.removeOld.begin();
        db_man.loadFeeds.begin((obj, res) =>{
            feeds = db_man.loadFeeds.end(res);
            main_window.add_feeds(feeds);
            update();
        });
        main_window = new MainWindow(this);
        view_list = new ArrayList<Item>();
        if(auto_update)
            Timeout.add_seconds(timeout_value, update);
    }

    public string constructFeedHtml(int feed_id) {
        view_list.clear();
        string html_str = "<html><head><style>" + css_dat + "</style></head><body>" + feeds[feed_id].constructHtml(db_man) + js_str + "</body></html>";
        main_window.updateFeedItem(feeds[feed_id], feed_id);
        return html_str;
    }

    public string constructUnreadHtml() {
        view_list.clear();
        string html_str = "<html><head><style>" + css_dat + "</style></head><body><br/>";
        foreach(Feed f in feeds) {
            html_str += f.constructUnreadHtml(db_man);
        }
        html_str += js_str + "</body></html>";
        return html_str;
    }

    public string constructAllHtml() {
        view_list.clear();
        string html_str = "<html><head><style>" + css_dat + "</style></head><body>";
        foreach(Feed f in feeds) {
            html_str += f.constructHtml(db_man);
            main_window.updateFeedItem(f, feeds.index_of(f));
        }
        html_str += js_str + "</body></html>";
        return html_str;
    }

    public string constructStarredHtml() {
        view_list.clear();
        string html_str = "<html><head><style>" + css_dat + "</style></head><body><br/>";
        foreach(Feed f in feeds) {
            html_str += f.constructStarredHtml(db_man);
        }
        html_str += js_str + "</body></html>";
        return html_str;
    }

    public void createFeed(string url) {
        if(verbose)
            stdout.printf("Fetching feed data from %s...", url);
        getXmlData.begin(url, (obj, res) => {
            Xml.Doc* doc = getXmlData.end(res);
            if(doc == null || doc->get_root_element() == null) {
                stderr.printf("Error: doc is null\n");
                return;
            }
            Feed f = new Feed.from_xml(doc->get_root_element(), url, db_man.next_id);
            db_man.next_id++;
            if(f.status == 3)
                return;
            db_man.saveFeed.begin(f, true);
            feeds.add(f);
            main_window.add_feed(f);
            main_window.updateFeedItem(f, feeds.index_of(f));
            delete doc;
        });
    }

    public void removeFeed(int feed_index) {
        Feed f = feeds[feed_index];
        db_man.removeFeed.begin(f);
        feeds.remove(f);
    }

    public void update_settings() {
        app_settings.set_boolean("auto-update", auto_update);
        app_settings.set_uint("auto-update-freq", timeout_value / 60);
        app_settings.set_value("unread-unstarred-rule", new Variant("(iii)",unread_unstarred_rule[0],unread_unstarred_rule[1],unread_unstarred_rule[2]));
        app_settings.set_value("read-unstarred-rule", new Variant("(iii)",read_unstarred_rule[0],read_unstarred_rule[1],read_unstarred_rule[2]));
        app_settings.set_value("unread-starred-rule", new Variant("(iii)",unread_starred_rule[0],unread_starred_rule[1],unread_starred_rule[2]));
        app_settings.set_value("read-starred-rule", new Variant("(iii)",read_starred_rule[0],read_starred_rule[1],read_starred_rule[2]));
        app_settings.set_boolean("download-attachments", download_attachments);
        app_settings.set_boolean("ask-download-location", get_location);
        app_settings.set_string("default-download-location", default_location);
        if(auto_update && !update_running) {
            update_running = true;
            update_next = timeout_value;
            Timeout.add_seconds(timeout_value, update);
        }
    }

    public int runall() {
        Gtk.main();
        exit();
        return 0;
    }

    public void updateFeedItems(Feed f) {
        main_window.updateFeedItem(f, feeds.index_of(f));
    }

    public void updateFeedIcons(Feed f) {
        main_window.updateFeedIcon(feeds.index_of(f), f.status);
    }

    public void interpretUriEncodedAction(string action) {
        string[] args = action.split("/");
        if(verbose)
            stderr.printf("calling function %s...\n", action);
        switch(args[0]) {
            case "read":
                int pos = int.parse(args[1]);
                Gee.ArrayList<Item> to_mark = new Gee.ArrayList<Item>();
                for(int i = 0; i <= pos; ++i) {
                    if(view_list[i].unread == true) {
                        view_list[i].unread = false;
                        to_mark.add(view_list[i]);
                    }
                }
                db_man.updateUnread.begin(new Feed(), to_mark, () => {
                    foreach(var item in to_mark) {
                        item.feed.removeUnreadItem(item);
                        updateFeedItems(item.feed);
                    }
                });
            break;

            case "toggleRead":
                int pos = int.parse(args[1]);
                view_list[pos].unread = !view_list[pos].unread;
//:TODO: 29.12.14 14:30:40, df458
// Finish this when the time to add a button for this feature arrives
// For now, it shouldn't save this change, so nothing permanent should happen
// if it gets activated by accident :)
            break;
            case "toggleStarred":
                int pos = int.parse(args[1]);
                Feed f = view_list[pos].feed;
                f.toggleStar(view_list[pos]);
                db_man.updateStarred.begin(f, view_list[pos]);
            break;
        }
    }

    public void downloadAttachment(string action) {
        try {
            if(!download_attachments)
                GLib.Process.spawn_command_line_async("xdg-open " + action);
            else {
                if(get_location) {
                    Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog("Download attachment", main_window, Gtk.FileChooserAction.SELECT_FOLDER, "Cancel", Gtk.ResponseType.CANCEL, "Download here", Gtk.ResponseType.ACCEPT);
                    dialog.set_current_folder(default_location);
                    if(dialog.run() == Gtk.ResponseType.ACCEPT) {
                        GLib.Process.spawn_command_line_async("wget -b -P '" + dialog.get_filename() +  "' '" + action + "'");
                    }
                    dialog.close();
                } else
                    GLib.Process.spawn_command_line_async("wget -b -P '" + default_location +  "' '" + action + "'");
            }
        } catch(GLib.SpawnError e) {
            stderr.printf("Failed to spawn %s: %s\n", (download_attachments ? "wget" : "xdg-open"), e.message);
        }
    }

    public void markAllAsRead() {
        stdout.printf("Clearing %d items:\n", view_list.size);
        Gee.ArrayList<Item> to_mark = new Gee.ArrayList<Item>();
        for(int i = 0; i < view_list.size; ++i) {
            if(view_list[i].unread == true) {
                view_list[i].unread = false;
                to_mark.add(view_list[i]);
            }
        }
        db_man.updateUnread.begin(new Feed(), to_mark, () => {
            stdout.printf("Removing 1 item\n");
            foreach(var item in to_mark) {
                item.feed.removeUnreadItem(item);
                updateFeedItems(item.feed);
            }
        });
        stdout.printf("done. Waiting...\n");
    }

    public void exit() {
        db_man.clearExpunged();
    }

    public void addToView(Item i) {
        view_list.add(i);
    }

    public bool update() {
        foreach(Feed f in feeds) {
            db_man.loadFeedItems.begin(f, -1, -1, (obj, res) => {
                f.updateFromWeb.begin(db_man);
            });
        }
        update_running = auto_update;
        if(update_running && update_next != timeout_value) {
            update_next = timeout_value;
            Timeout.add_seconds(timeout_value, update);
            return false;
        }
        return auto_update;
    }
}
