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
//:TODO: 27.08.14 15:35:13, Hugues Ross
// Add a variable for auto-delete time
    private ArrayList<Feed> feeds;
    private DatabaseManager db_man;
    private MainWindow main_window;
    string css_path;
    string css_dat = "";
    private ArrayList<Item> view_list;
    private Settings app_settings;
    public bool auto_update = true;
    public uint timeout_value = 600;
    public bool update_running = true;
    public uint update_next = 600;
    //Count, Increment(m,h,d,m,y), action(nothing,read/unread,star/unstar,delete)
    public int[] unread_unstarred_rule = {7, 3, 1}; //1 week, read
    public int[] unread_starred_rule   = {0, 0, 0}; //nothing
    public int[] read_unstarred_rule   = {1, 4, 3}; //1 minute, delete
    public int[] read_starred_rule     = {6, 4, 2}; //6 months, unstar

    public Singularity(string[] args) {
        Object(application_id: "org.df458.singularity");
        Granite.Services.Paths.initialize("singularity", Environment.get_user_data_dir());
        Granite.Services.Paths.ensure_directory_exists(Granite.Services.Paths.user_data_folder);

        string db_path = Environment.get_user_data_dir() + "/singularity/feeds.db";
        css_path = Environment.get_user_data_dir() + "/singularity/default.css";

        app_settings = new Settings("org.df458.singularity");
        auto_update = app_settings.get_boolean("auto-update");
        timeout_value = app_settings.get_uint("auto-update-freq") * 60;
        if(args.length > 1)
            db_path = args[1];
        if(args.length > 2)
            css_path = args[2];
        db_man = new DatabaseManager.from_path(db_path);
        File file = File.new_for_path(css_path);
        if(!file.query_exists()) {
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
        return "<html><head><style>" + css_dat + "</style></head><body><p>Starred view not implemented yet.</p></body></html>";
    }

    public void createFeed(string url) {
        getXmlData.begin(url, (obj, res) => {
            Xml.Doc* doc = getXmlData.end(res);
            if(doc == null || doc->get_root_element() == null) {
                stderr.printf("Error: doc is null\n");
                return;
            }
//:FIXME: 23.10.14 14:18:53, df458
// Setting the id to feeds.size causes overlap
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
