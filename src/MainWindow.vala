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

using Gtk;
using Gdk;
using Granite.Widgets;

class MainWindow : Gtk.ApplicationWindow
{
    private HeaderBar top_bar;
    private Paned content_pane;
    private WebKit.WebView web_view;
    //private SourceList feed_list;
    //private SourceList.ExpandableItem category_all;
    //private SourceList.ExpandableItem category_collection;
    //private SourceList.Item unread_item;
    //private SourceList.Item all_item;
    //private SourceList.Item starred_item;

    private TreeView feed_list;
    private TreeStore feed_data;
    private TreeIter category_all;
    private TreeIter category_collection;
    private TreeIter all_item;
    private TreeIter unread_item;
    private TreeIter starred_item;
    private ScrolledWindow feed_list_scroll;

    private ActionBar status_bar;
    private Label status_label;
    private Box content_fill;
    private Gee.ArrayList<SourceList.Item> feed_items;
    private Gdk.Pixbuf icon_download;
    private Gdk.Pixbuf icon_success;
    private Gdk.Pixbuf icon_failure;
    private bool firststart = true;
    private MenuButton app_menu;
    private Gtk.Widget current_view;

    private SimpleAction refresh_action;
    private SimpleAction preferences_action;
    private SimpleAction mkread_action;
    private SimpleAction about_action;

    private Welcome welcome_view;
    private SettingsPane settings;
    private FeedSettingsPane feed_settings;
    private AddPane add_pane;

    string[] authorstr = { "Hugues Ross(df458)" };

    public MainWindow(Singularity owner_app)
    {
        feed_items = new Gee.ArrayList<SourceList.Item>();
        window_position = WindowPosition.CENTER;
        set_default_size(800, 600);

        GLib.Menu menu = new GLib.Menu();
        GLib.MenuItem refresh_item = new GLib.MenuItem("Refresh", "win.refresh-feeds");
        GLib.MenuItem preferences_item = new GLib.MenuItem("Preferences", "win.app-preferences");
        GLib.MenuItem mkread_item = new GLib.MenuItem("Mark All as Read", "win.mark-read");
        GLib.MenuItem about_item = new GLib.MenuItem("About", "win.about");
        refresh_action = new GLib.SimpleAction("refresh-feeds", null);
        refresh_action.set_enabled(false);
        refresh_action.activate.connect(() => {
            app.update();
        });
        this.add_action(refresh_action);
        preferences_action = new GLib.SimpleAction("app-preferences", null);
        preferences_action.activate.connect(() => {
            settings.sync();
            set_content(settings);
        });
        this.add_action(preferences_action);
        mkread_action = new GLib.SimpleAction("mark-read", null);
        mkread_action.set_enabled(false);
        mkread_action.activate.connect(() => {
            app.markAllAsRead();
        });
        this.add_action(mkread_action);
        about_action = new GLib.SimpleAction("about", null);
        about_action.activate.connect(() => {
            Gtk.show_about_dialog(this,
                "program-name", ("Singularity"),
                "authors", (authorstr),
                "website", ("http://github.com/Df458/Singularity"),
                "website-label", ("Github"),
                "comments", ("A simple webfeed aggregator"),
                "version", ("0.2"),
                "license-type", ((Gtk.License)License.GPL_3_0),
                "copyright", ("Copyright © 2014 Hugues Ross"));
        });
        this.add_action(about_action);
        menu.append_item(refresh_item);
        menu.append_item(preferences_item);
        menu.append_item(mkread_item);
        menu.append_item(about_item);
        app_menu = new MenuButton();
        app_menu.set_menu_model(menu);

        top_bar = new HeaderBar();
        top_bar.set_title("Singularity");
        top_bar.set_subtitle("You have no subscriptions");
        top_bar.set_show_close_button(true);
        top_bar.pack_end(app_menu);
        set_titlebar(top_bar);

        content_fill = new Box(Orientation.VERTICAL, 0);
        this.add(content_fill);

        content_pane = new Paned(Orientation.HORIZONTAL);
        content_pane.position = 100;
        content_fill.pack_start(content_pane, true, true);

        Button add_button = new Button.from_icon_name("add", IconSize.MENU);
        add_button.set_tooltip_text("Subscribe to a new feed");
        Button rm_button = new Button.from_icon_name("remove", IconSize.MENU);
        rm_button.set_tooltip_text("Unsubscribe from this feed");
        Button settings_button = new Button.from_icon_name("gtk-preferences", IconSize.MENU);
        settings_button.set_tooltip_text("Feed settings");
        rm_button.set_sensitive(false);
        settings_button.set_sensitive(false);
        rm_button.clicked.connect((ev) => {
            //var f = feed_list.selected;
            //MessageDialog confirm = new MessageDialog(this, DialogFlags.MODAL, MessageType.QUESTION, ButtonsType.YES_NO, "Are you sure you want to unsubscribe from %s?", f.name);
            //confirm.response.connect((response) => {
                //if(response == Gtk.ResponseType.YES) {
                    //app.removeFeed(feed_items.index_of(f));
                    //category_all.remove(f);
                    //feed_items.remove(f);
                    //updateSubtitle();
                //}
                //confirm.destroy();
            //});
            //confirm.show_all();
            warning("rm_button click callback is a stub");
        });
        add_button.clicked.connect((ev) => {
            set_content(add_pane);
        });
        settings_button.clicked.connect((ev) => {
            //feed_settings.sync(app.getFeed(feed_items.index_of(feed_list.selected)));
            //set_content(feed_settings);
            warning("settings_button click callback is a stub");
        });
        status_bar = new ActionBar();
        status_label = new Label("");
        status_bar.pack_start(add_button);
        status_bar.pack_start(rm_button);
        status_bar.pack_start(settings_button);
        status_bar.set_center_widget(status_label);
        content_fill.pack_end(status_bar, false, false);

        //feed_list = new SourceList();
        //category_collection = new SourceList.ExpandableItem("Collections");
        //unread_item = new SourceList.Item("Unread");
        //all_item = new SourceList.Item("All");
        //starred_item = new SourceList.Item("Starred");
        //category_collection.add(all_item);
        //category_collection.add(unread_item);
        //category_collection.add(starred_item);
        //category_all = new SourceList.ExpandableItem("Subscriptions");
        //feed_list.root.add(category_collection);
        //feed_list.root.add(category_all);
        //feed_list.root.expand_all();
        //content_pane.pack1(feed_list, true, false);
        //starred_item.badge = "0";
        //feed_list.item_selected.connect((item) => {
            //rm_button.set_sensitive(false);
            //settings_button.set_sensitive(false);
            //mkread_action.set_enabled(true);
            //if(item == unread_item) {
                //web_view.load_html(app.constructUnreadHtml(), "");
                //status_label.label = "Unread Feeds";
            //} else if(item == all_item) {
                //web_view.load_html(app.constructAllHtml(), "");
                //status_label.label = "All Feeds";
            //} else if(item == starred_item) {
                //web_view.load_html(app.constructStarredHtml(), "");
                //status_label.label = "Starred Feeds";
            //} else {
            //if(feed_items.index_of(item) < 0)
                //return;
                //web_view.load_html(app.constructFeedHtml(feed_items.index_of(item)), "");
                //rm_button.set_sensitive(true);
                //settings_button.set_sensitive(true);
                //status_label.label = "";
            //}
            //set_content(web_view);
        //});

        // Spinner, Name, Unread Badge, Show Badge, Feed Id, Starred Count
        feed_data = new TreeStore(6, typeof(bool), typeof(string), typeof(int), typeof(bool), typeof(int), typeof(int));
        feed_data.set_sort_column_id(1, Gtk.SortType.ASCENDING);
        feed_list = new TreeView.with_model(feed_data);
        feed_list.set_headers_visible(false);
        CellRendererSpinner spin = new CellRendererSpinner();
        Gtk.TreeViewColumn col_load = new Gtk.TreeViewColumn.with_attributes("Loading", spin, "active", 0, null);
        feed_list.insert_column(col_load, -1);
        Gtk.TreeViewColumn col_name = new Gtk.TreeViewColumn.with_attributes("Name", new CellRendererText(), "text", 1, null);
        feed_list.insert_column(col_name, -1);
        Gtk.TreeViewColumn col_count = new Gtk.TreeViewColumn.with_attributes("Count", new CellRendererText(), "text", 2, "visible", 3, null);
        feed_list.insert_column(col_count, -1);
        feed_data.append(out category_collection, null);
        feed_data.set(category_collection, 1, "Collections", 3, false, -1);
        feed_data.append(out all_item, category_collection);
        feed_data.set(all_item, 1, "All Feeds", 3, false, -1);
        feed_data.append(out unread_item, category_collection);
        feed_data.set(unread_item, 1, "Unread Feeds", 3, true, -1);
        feed_data.append(out starred_item, category_collection);
        feed_data.set(starred_item, 1, "Starred Feeds", 3, true, -1);
        feed_data.append(out category_all, null);
        feed_data.set(category_all, 1, "Subscriptions", 3, false, -1);
        feed_list.expand_all();
        feed_list.cursor_changed.connect(() => {
            TreePath path;
            feed_list.get_cursor(out path, null);
            TreeIter iter;
            feed_data.get_iter(out iter, path);
            rm_button.set_sensitive(false);
            settings_button.set_sensitive(false);
            mkread_action.set_enabled(true);
            if(iter == unread_item) {
                web_view.load_html(app.constructUnreadHtml(), "");
                status_label.label = "Unread Feeds";
            } else if(iter == all_item) {
                web_view.load_html(app.constructAllHtml(), "");
                status_label.label = "All Feeds";
            } else if(iter == starred_item) {
                web_view.load_html(app.constructStarredHtml(), "");
                status_label.label = "Starred Feeds";
            } else if(iter == category_all || iter == category_collection) {
                return;
            }  else {
                int id = 0;
                string name = "";
                feed_data.get(iter, 1, out name, 4, out id);
                web_view.load_html(app.constructFeedHtml(id), "");
                rm_button.set_sensitive(true);
                settings_button.set_sensitive(true);
                status_label.label = name;
            }
            set_content(web_view);
        });
        feed_list_scroll = new ScrolledWindow(null, null);
        feed_list_scroll.add(feed_list);
        content_pane.pack1(feed_list_scroll, true, false);

        web_view = new WebKit.WebView();
        WebKit.Settings view_settings = new WebKit.Settings();
        view_settings.enable_javascript = true;
        view_settings.enable_developer_extras = true;
        web_view.set_settings(view_settings);
//:TODO: 16.09.14 18:52:26, Hugues Ross
// Add a custom right-click menu
        web_view.context_menu.connect(()=>{
            return true;
        });
        web_view.decide_policy.connect((decision, type) => {
            if(type == WebKit.PolicyDecisionType.NAVIGATION_ACTION) {
            WebKit.NavigationPolicyDecision nav_dec = (WebKit.NavigationPolicyDecision) decision;
            if(nav_dec.get_navigation_action().get_request().uri.has_prefix("command://")) {
                app.interpretUriEncodedAction(nav_dec.get_navigation_action().get_request().uri.substring(10));
                nav_dec.ignore();
                return true;
            }

            if(nav_dec.get_navigation_action().get_request().uri.has_prefix("download-attachment")) {
                app.downloadAttachment(nav_dec.get_navigation_action().get_request().uri.substring(19));
                nav_dec.ignore();
                return true;
            }

            if(nav_dec.get_navigation_action().get_navigation_type() != WebKit.NavigationType.LINK_CLICKED)
                return false;
            try {
                GLib.Process.spawn_command_line_async(app.link_command.printf(nav_dec.get_navigation_action().get_request().uri));
                nav_dec.ignore();
            } catch(Error e) {
                stderr.printf(e.message);
            }
            return true;
            }
            return false;
        });
        welcome_view = new Welcome("Welcome", "You have no subscriptions");
        welcome_view.append("add", "Add", "Subscribe to a new feed.");
        welcome_view.activated.connect( () => {
            set_content(add_pane);
        });
        content_pane.pack2(welcome_view, true, true);
        current_view = welcome_view;
        web_view.load_html(owner_app.constructFrontPage(), "");

        settings = new SettingsPane();
        settings.done.connect(() => {
            if(firststart)
                set_content(welcome_view);
            else
                set_content(web_view);
        });

        feed_settings = new FeedSettingsPane();
        feed_settings.done.connect(() => {
            set_content(web_view);
        });
        
        add_pane = new AddPane();
        add_pane.done.connect(() => {
            if(firststart)
                set_content(welcome_view);
            else
                set_content(web_view);
        });

        this.destroy.connect(() => {
            Gtk.main_quit();
        });

        try {
            icon_download = new Pixbuf.from_file("/usr/local/share/singularity/emblem_download.png");
            icon_failure = new Pixbuf.from_file("/usr/local/share/singularity/emblem_failure.png");
            icon_success = new Pixbuf.from_file("/usr/local/share/singularity/emblem_success.png");
        } catch(Error e) {
            stderr.printf(e.message);
        }
        this.show_all();
    }

    public void set_content(Gtk.Widget widget)
    {
        int pos = content_pane.get_position();
        if(widget == web_view)
            mkread_action.set_enabled(true);
        else
            mkread_action.set_enabled(false);
        content_pane.remove(current_view);
        content_pane.set_position(0);
        content_pane.pack2(widget, true, false);
        current_view = widget;
        content_pane.set_position(pos);
        this.show_all();
    }

    public void updateSubtitle()
    {
        if(feed_items.size > 1) {
            top_bar.set_subtitle("You have " + feed_items.size.to_string() + " subscriptions");
        } else if(feed_items.size == 1) {
            top_bar.set_subtitle("You have 1 subscription");
        } else {
            top_bar.set_subtitle("You have no subscriptions");
            firststart = true;
        }
    }

    public void add_feeds(Gee.ArrayList<Feed> feeds)
    {
        for(int i = 0; i < feeds.size; ++i) {
            add_feed(feeds[i], i);
        }
    }

    public void add_feed(Feed f, int index)
    {
        //SourceList.Item feed_item = new SourceList.Item(f.title);
        //feed_item.badge = f.unread_count.to_string();
        //category_all.add(feed_item);
        //unread_item.badge = (int.parse(unread_item.badge) + f.unread_count).to_string();
        //starred_item.badge = (int.parse(starred_item.badge) + f.starred_count).to_string();
        int count = 0;
        feed_data.get(unread_item, 2, out count);
        feed_data.set(unread_item, 2, count + f.unread_count, -1);
        count = 0;
        feed_data.get(starred_item, 2, out count);
        feed_data.set(starred_item, 2, count + f.starred_count, -1);
        TreeIter iter;
        feed_data.append(out iter, category_all);
        feed_data.set(iter, 1, f.title, 2, f.unread_count, 3, true, 4, index, 5, f.starred_count, -1);
        updateSubtitle();
        if(firststart) {
            firststart = false;
            refresh_action.set_enabled(true);
            set_content(web_view);
        }
    }

    public void updateFeedItem(Feed f, int index)
    {
        feed_data.foreach((model, path, iter) => {
            int id = 0;
            feed_data.get(iter, 4, out id);
            if(id == index) {
                int last_count = 0;
                int last_starred = 0;
                feed_data.get(iter, 2, out last_count, 5, out last_starred, -1);
                int count = 0;
                feed_data.get(unread_item, 2, out count);
                feed_data.set(unread_item, 2, count + (f.unread_count - last_count), -1);
                count = 0;
                feed_data.get(starred_item, 2, out count);
                feed_data.set(starred_item, 2, count + (f.starred_count - last_starred), -1);
                feed_data.set(iter, 2, f.unread_count, -1);
                feed_data.set(iter, 5, f.starred_count, -1);
                return true;
            }
            return false;
        });
    }

    public int get_unread_count()
    {
        int count = 0;
        feed_data.get(unread_item, 2, out count);
        return count;
    }

    public void updateFeedIcon(int index, int icon)
    {
        feed_data.foreach((model, path, iter) => {
            int id = 0;
            feed_data.get(iter, 4, out id);
            if(id == index) {
                if(icon == 1)
                    feed_data.set(iter, 0, true, -1);
                else
                    feed_data.set(iter, 0, false, -1);
                return true;
            }
            return false;
        });
        // TODO: Implement this
        //warning("MainWindow.updateFeedIcon(int, int) is a stub");
        //switch(icon) {
            //case 0:
            //feed_items[index].icon = null;
            //break;
            //case 1:
            //feed_items[index].icon = icon_download;
            //break;
            //case 2:
            //feed_items[index].icon = icon_success;
            //break;
            //case 3:
            //feed_items[index].icon = icon_failure;
            //break;
        //}
    }
}
