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

class MainWindow : Gtk.ApplicationWindow {
    private HeaderBar top_bar;
    private ThinPaned content_pane;
    private WebKit.WebView web_view;
    private SourceList feed_list;
    private SourceList.ExpandableItem category_all;
    private SourceList.ExpandableItem category_collection;
    private SourceList.Item unread_item;
    private SourceList.Item all_item;
    private SourceList.Item starred_item;
    private StatusBar status_bar;
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

    private Welcome welcome_view;
    private SettingsPane settings;
    private AddPopupWindow add_win;

    public MainWindow(Gtk.Application owner_app) {
        feed_items = new Gee.ArrayList<SourceList.Item>();
        window_position = WindowPosition.CENTER;
        set_default_size(800, 600);

        GLib.Menu menu = new GLib.Menu();
        GLib.MenuItem refresh_item = new GLib.MenuItem("Refresh", "win.refresh-feeds");
        GLib.MenuItem preferences_item = new GLib.MenuItem("Preferences", "win.app-preferences");
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
        menu.append_item(refresh_item);
        menu.append_item(preferences_item);
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

        content_pane = new ThinPaned();
        content_fill.add(content_pane);

        add_win = new AddPopupWindow(this);

        Button add_button = new Button.from_icon_name("add", IconSize.MENU);
        Button rm_button = new Button.from_icon_name("remove", IconSize.MENU);
        rm_button.set_sensitive(false);
        rm_button.clicked.connect((ev) => {
            var f = feed_list.selected;
            app.removeFeed(feed_items.index_of(f));
            category_all.remove(f);
            feed_items.remove(f);
            updateSubtitle();
        });
        add_button.clicked.connect((ev) => {
            add_win.show_all();
        });
        status_bar = new StatusBar();
        status_bar.insert_widget(add_button, true);
        status_bar.insert_widget(rm_button, true);
        content_fill.add(status_bar);

        feed_list = new SourceList();
        category_collection = new SourceList.ExpandableItem("Collections");
        unread_item = new SourceList.Item("Unread");
        all_item = new SourceList.Item("All");
        starred_item = new SourceList.Item("Starred");
        category_collection.add(all_item);
        category_collection.add(unread_item);
        category_collection.add(starred_item);
        category_all = new SourceList.ExpandableItem("Subscriptions");
        feed_list.root.add(category_collection);
        feed_list.root.add(category_all);
        feed_list.root.expand_all();
        content_pane.pack1(feed_list, true, false);
        //starred_item.badge = "0";
        feed_list.item_selected.connect((item) => {
            rm_button.set_sensitive(false);
            if(item == unread_item)
                web_view.load_html(app.constructUnreadHtml(), "");
            else if(item == all_item)
                web_view.load_html(app.constructAllHtml(), "");
            else if(item == starred_item)
                web_view.load_html(app.constructStarredHtml(), "");
            else {
            if(feed_items.index_of(item) < 0)
                return;
                web_view.load_html(app.constructFeedHtml(feed_items.index_of(item)), "");
                rm_button.set_sensitive(true);
            }
            set_content(web_view);
        });

        web_view = new WebKit.WebView();
        WebKit.Settings view_settings = new WebKit.Settings();
        view_settings.enable_javascript = true;
        web_view.set_settings(view_settings);
//:TODO: 16.09.14 18:52:26, Hugues Ross
// Add a custom right-click menu
        //web_view.context_menu.connect(()=>{
            //return true;
        //});
        web_view.decide_policy.connect((decision, type) => {
            if(type == WebKit.PolicyDecisionType.NAVIGATION_ACTION) {
            WebKit.NavigationPolicyDecision nav_dec = (WebKit.NavigationPolicyDecision) decision;
            if(nav_dec.get_navigation_action().get_request().uri.has_prefix("command://")) {
                app.interpretUriEncodedAction(nav_dec.get_navigation_action().get_request().uri.substring(10));
                nav_dec.ignore();
                return true;
            }
            if(nav_dec.get_navigation_action().get_navigation_type() != WebKit.NavigationType.LINK_CLICKED)
                return false;
            try {
                GLib.Process.spawn_command_line_async("xdg-open " + nav_dec.get_navigation_action().get_request().uri);
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
            add_win.show_all();
        });
        content_pane.pack2(welcome_view, true, true);
        current_view = welcome_view;

        settings = new SettingsPane();
        settings.done.connect(() => {
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

    public void set_content(Gtk.Widget widget) {
        content_pane.remove(current_view);
        content_pane.set_position(0);
        content_pane.pack2(widget, true, false);
        current_view = widget;
        this.show_all();
    }

    public void updateSubtitle() {
        if(feed_items.size > 1) {
            top_bar.set_subtitle("You have " + feed_items.size.to_string() + " subscriptions");
        } else if(feed_items.size == 1) {
            top_bar.set_subtitle("You have 1 subscription");
        } else {
            top_bar.set_subtitle("You have no subscriptions");
            firststart = true;
        }
    }

    public void add_feeds(Gee.ArrayList<Feed> feeds) {
        foreach(Feed f in feeds) {
            add_feed(f);
        }
    }

    public void add_feed(Feed f) {
        SourceList.Item feed_item = new SourceList.Item(f.title);
        feed_item.badge = f.unread_count.to_string();
        category_all.add(feed_item);
        unread_item.badge = (int.parse(unread_item.badge) + f.unread_count).to_string();
        //starred_item.badge = (int.parse(starred_item.badge) + f.starred_count).to_string();
        feed_items.add(feed_item);
        updateSubtitle();
        if(firststart) {
            firststart = false;
            refresh_action.set_enabled(true);
            set_content(web_view);
        }
    }

    public void updateFeedItem(Feed f, int index) {
        int unread_diff = f.unread_count - int.parse(feed_items[index].badge);
        unread_item.badge = (int.parse(unread_item.badge) + unread_diff).to_string();
        feed_items[index].badge = f.unread_count.to_string();
    }

    public void updateFeedIcon(int index, int icon) {
        switch(icon) {
            case 0:
            feed_items[index].icon = null;
            break;
            case 1:
            feed_items[index].icon = icon_download;
            break;
            case 2:
            feed_items[index].icon = icon_success;
            break;
            case 3:
            feed_items[index].icon = icon_failure;
            break;
        }
    }
}
