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

using Gtk;
using Gdk;

class MainWindow : Gtk.ApplicationWindow
{
    private Box   main_box;
    private Paned main_paned;
    private Singularity app;
    private string current_view = "grid";
    private bool   toggle_lock = false; // Prevents extra button toggle changes when selecting a view

    // Headerbar
    private HeaderBar    top_bar;
    private Button       add_button;
    private MenuButton   menu_button;
    private ToggleButton item_search_toggle;

    // Actions
    private SimpleAction import_action;
    private SimpleAction export_action;
    private SimpleAction refresh_action;
    private SimpleAction preferences_action;
    private SimpleAction mkread_action;
    private SimpleAction about_action;
    private SimpleAction unsubscribe_action;

    // Search
    private SearchBar   item_search_bar;
    private SearchEntry item_search_entry;
    private Gtk.Menu feed_menu;

    // Statusbar
    private ActionBar    status_bar;
    private Box          view_switcher;
    private ToggleButton grid_view_button;
    private ToggleButton column_view_button;
    private ToggleButton stream_view_button;
    private Label        status_label;
    private Spinner      progress_spinner;
    private ProgressBar  progress_bar;

    // Feed List
    private ScrolledWindow feed_list_scroll;
    private TreeView       feed_list;
    private TreeViewColumn col_name;
    private TreeViewColumn col_count;
    private TreeStore      feed_data;
    private TreeIter       category_all;
    private TreeIter       category_collection;
    private TreeIter       all_item;
    private TreeIter       unread_item;
    private TreeIter       starred_item;

    // Views
    private Stack          view_stack;
    private WebKit.WebView grid_view;
    private Box            column_view_box;
    private ListBox        item_column_box;
    private WebKit.WebView column_view_display;
    private WebKit.WebView stream_view;
    private SettingsPane settings;
    private FeedSettingsPane feed_settings;
    private AddPane add_pane;

    string[] authorstr = { "Hugues Ross(df458)" };

    private enum FeedColumn
    {
        WORKING = 0,
        TITLE,
        UNREAD_COUNT,
        SHOW_UNREAD_COUNT,
        FEED_ID,
        STARRED_COUNT
    }

    public MainWindow(Singularity owner_app)
    {
        app = owner_app;
        window_position = WindowPosition.CENTER;
        set_default_size(1024, 768);

        init_structure();
        init_content();
        connect_signals();
        add_actions();
        init_menus();

        resize_columns(128);
        this.show_all();

        /*
        //Button settings_button = new Button.from_icon_name("gtk-preferences", IconSize.MENU);
        //settings_button.set_tooltip_text("Feed settings");
        //settings_button.set_sensitive(false);
        //settings_button.clicked.connect((ev) => {
            ////feed_settings.sync(app.getFeed(feed_items.index_of(feed_list.selected)));
            ////set_content(feed_settings);
            //warning("settings_button click callback is a stub");
        //});
        //welcome_view = new Welcome("Welcome", "You have no subscriptions");
        //welcome_view.append("add", "Add", "Subscribe to a new feed.");
        //welcome_view.activated.connect( () => {
            //set_content(add_pane);
        //});
        */
    }

    private void init_structure()
    {
        top_bar = new HeaderBar();
        main_box = new Box(Orientation.VERTICAL, 0);
        main_paned = new Paned(Orientation.HORIZONTAL);
        // TODO: Remove "Gtk." once Granite is removed
        item_search_bar = new Gtk.SearchBar();
        status_bar = new ActionBar();
        feed_list_scroll = new ScrolledWindow(null, null);
        view_stack = new Stack();

        top_bar.set_title("Singularity");
        top_bar.set_show_close_button(true);
        feed_list_scroll.hscrollbar_policy = PolicyType.NEVER;
        main_paned.position = 128;

        main_paned.pack1(feed_list_scroll, true, true);
        main_paned.pack2(view_stack, true, true);
        main_box.pack_start(item_search_bar, false, false);
        main_box.pack_start(main_paned, true, true);
        main_box.pack_start(status_bar, false, false);
        this.add(main_box);
        this.set_titlebar(top_bar);
    }

    private void init_content()
    {
        view_switcher       = new Box(Orientation.HORIZONTAL, 0);
        add_button          = new Button.from_icon_name("list-add-symbolic");
        item_search_toggle  = new ToggleButton();
        item_search_entry   = new SearchEntry();
        menu_button         = new MenuButton();
        grid_view_button    = new ToggleButton();
        column_view_button  = new ToggleButton();
        stream_view_button  = new ToggleButton();
        progress_spinner    = new Spinner();
        progress_bar        = new ProgressBar();
        status_label        = new Label(null);
        column_view_box     = new Box(Orientation.HORIZONTAL, 6);
        grid_view           = new WebKit.WebView();
        column_view_display = new WebKit.WebView();
        stream_view         = new WebKit.WebView();
        settings            = new SettingsPane();
        feed_settings       = new FeedSettingsPane();
        add_pane            = new AddPane();

        add_button.get_style_context().add_class(STYLE_CLASS_SUGGESTED_ACTION);
        add_button.set_tooltip_text("Subscribe to a new feed");
        item_search_toggle.set_image(new Image.from_icon_name("edit-find-symbolic", IconSize.BUTTON));
        item_search_toggle.set_tooltip_text("Search for items");
        menu_button.set_direction(ArrowType.DOWN);
        menu_button.set_image       (new Image.from_icon_name("open-menu-symbolic", IconSize.BUTTON));
        view_switcher.get_style_context().add_class(STYLE_CLASS_LINKED);
        grid_view_button.set_image  (new Image.from_icon_name("view-grid-symbolic", IconSize.BUTTON));
        grid_view_button.set_tooltip_text("Grid view");
        grid_view_button.can_focus = false;
        column_view_button.set_image(new Image.from_icon_name("view-column-symbolic", IconSize.BUTTON));
        column_view_button.set_tooltip_text("Column view");
        column_view_button.can_focus = false;
        stream_view_button.set_image(new Image.from_icon_name("view-continuous-symbolic", IconSize.BUTTON));
        stream_view_button.set_tooltip_text("Stream view");
        stream_view_button.can_focus = false;
        progress_bar.valign  = Align.CENTER;

        WebKit.Settings view_settings = new WebKit.Settings();
        view_settings.enable_javascript = true;
        view_settings.enable_developer_extras = true;
        view_settings.enable_smooth_scrolling = true;
        grid_view.set_settings(view_settings);
        column_view_display.set_settings(view_settings);
        stream_view.set_settings(view_settings);
//:TODO: 16.09.14 18:52:26, Hugues Ross
// Add a custom right-click menu
        grid_view.load_html(app.constructFrontPage(), "");
        column_view_display.load_html(app.constructFrontPage(), "");
        stream_view.load_html(app.constructFrontPage(), "");
        init_feed_pane();
        grid_view_button.active = true;

        item_search_bar.add(item_search_entry);
        item_search_bar.connect_entry(item_search_entry);
        column_view_box.pack_end(column_view_display);
        feed_list_scroll.add(feed_list);
        view_switcher.add(grid_view_button);
        view_switcher.add(column_view_button);
        view_switcher.add(stream_view_button);
        view_stack.add_named(grid_view, "grid");
        view_stack.add_named(column_view_box, "column");
        view_stack.add_named(stream_view, "stream");
        view_stack.add_named(settings, "settings");
        view_stack.add_named(feed_settings, "feed_settings");
        view_stack.add_named(add_pane, "add");
        grid_view.show_all();
        view_stack.set_visible_child(grid_view);
        status_bar.set_center_widget(status_label);
        status_bar.pack_start(view_switcher);
        status_bar.pack_end(progress_spinner);
        //status_bar.pack_end(progress_bar);
        top_bar.pack_start(add_button);
        top_bar.pack_end(menu_button);
        top_bar.pack_end(item_search_toggle);
    }

    private bool policy_decision(WebKit.PolicyDecision decision, WebKit.PolicyDecisionType type)
    {
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
    }

    private void init_feed_pane()
    {
        // Spinner, Name, Unread Badge, Show Badge, Feed Id, Starred Count
        feed_data = new TreeStore(6, typeof(bool), typeof(string), typeof(int), typeof(bool), typeof(int), typeof(int));
        feed_data.set_sort_column_id(FeedColumn.TITLE, Gtk.SortType.ASCENDING);
        feed_list = new TreeView.with_model(feed_data);
        feed_list.set_headers_visible(false);
        CellRendererSpinner spin = new CellRendererSpinner();
        //Gtk.TreeViewColumn col_load = new Gtk.TreeViewColumn.with_attributes("Loading", spin, "active", FeedColumn.WORKING, null);
        //feed_list.insert_column(col_load, -1);
        CellRendererText name_renderer = new CellRendererText();
        name_renderer.ellipsize = Pango.EllipsizeMode.END;
        col_name = new Gtk.TreeViewColumn.with_attributes("Name", name_renderer, "text", FeedColumn.TITLE, null);
        feed_list.insert_column(col_name, -1);
        col_count = new Gtk.TreeViewColumn.with_attributes("Count", new CellRendererText(), "text", FeedColumn.UNREAD_COUNT, "visible", FeedColumn.SHOW_UNREAD_COUNT, null);
        feed_list.set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        feed_list.insert_column(col_count, -1);
        feed_data.append(out category_collection, null);
        feed_data.set(category_collection, FeedColumn.TITLE, "Collections", FeedColumn.SHOW_UNREAD_COUNT, false, -1);
        feed_data.append(out all_item, category_collection);
        feed_data.set(all_item, FeedColumn.TITLE, "All Feeds", FeedColumn.SHOW_UNREAD_COUNT, false, -1);
        feed_data.append(out unread_item, category_collection);
        feed_data.set(unread_item, FeedColumn.TITLE, "Unread Feeds", FeedColumn.SHOW_UNREAD_COUNT, true, -1);
        feed_data.append(out starred_item, category_collection);
        feed_data.set(starred_item, FeedColumn.TITLE, "Starred Feeds", FeedColumn.SHOW_UNREAD_COUNT, true, -1);
        feed_data.append(out category_all, null);
        feed_data.set(category_all, FeedColumn.TITLE, "Subscriptions", FeedColumn.SHOW_UNREAD_COUNT, false, -1);
        feed_list.expand_all();
        feed_list.cursor_changed.connect(() =>
        {
            TreePath path;
            feed_list.get_cursor(out path, null);
            TreeIter iter;
            feed_data.get_iter(out iter, path);
            mkread_action.set_enabled(true);
            // TODO: Redo this
            if(iter == unread_item) {
                grid_view.load_html(app.constructUnreadHtml(), "");
            } else if(iter == all_item) {
                grid_view.load_html(app.constructAllHtml(), "");
            } else if(iter == starred_item) {
                grid_view.load_html(app.constructStarredHtml(), "");
            } else if(iter == category_all || iter == category_collection) {
                return;
            }  else {
                int id = 0;
                string name = "";
                feed_data.get(iter, FeedColumn.TITLE, out name, FeedColumn.FEED_ID, out id);
                grid_view.load_html(app.constructFeedHtml(id), "");
            }
        });
    }

    private void connect_signals()
    {
        this.destroy.connect(() =>
        {
            Gtk.main_quit();
        });

        add_button.clicked.connect((ev) =>
        {
            view_stack.set_visible_child_name("add");
        });

        main_paned.notify.connect((spec, prop) =>
        {
            if(prop.name == "position") {
                resize_columns(main_paned.get_position());
            }
        });

        feed_list_scroll.size_allocate.connect(() =>
        {
            resize_columns(main_paned.get_position());
        });

        item_search_toggle.toggled.connect(() =>
        {
            item_search_bar.search_mode_enabled = item_search_toggle.active;
        });

        grid_view.context_menu.connect(() => { return true; });
        column_view_display.context_menu.connect(() => { return true; });
        stream_view.context_menu.connect(() => { return true; });
        grid_view.decide_policy.connect((decision, type) => { return policy_decision(decision, type); });
        column_view_display.decide_policy.connect((decision, type) => { return policy_decision(decision, type); });
        stream_view.decide_policy.connect((decision, type) => { return policy_decision(decision, type); });

        settings.done.connect(() =>
        {
            view_stack.set_visible_child_name(current_view);
            preferences_action.set_enabled(true);
        });

        feed_settings.done.connect(() =>
        {
            view_stack.set_visible_child_name(current_view);
        });
        
        add_pane.done.connect(() =>
        {
            view_stack.set_visible_child_name(current_view);
        });

        grid_view_button.toggled.connect(() =>
        {
            if(toggle_lock)
                return;

            if(grid_view_button.active) {
                toggle_lock = true;
                column_view_button.active = false;
                stream_view_button.active = false;
                toggle_lock = false;
                view_stack.set_visible_child_name("grid");
            } else
                grid_view_button.active = true;
        });

        column_view_button.toggled.connect(() =>
        {
            if(toggle_lock)
                return;

            if(column_view_button.active) {
                toggle_lock = true;
                grid_view_button.active = false;
                stream_view_button.active = false;
                toggle_lock = false;
                view_stack.set_visible_child_name("column");
            } else
                column_view_button.active = true;
        });

        stream_view_button.toggled.connect(() =>
        {
            if(toggle_lock)
                return;

            if(stream_view_button.active) {
                toggle_lock = true;
                grid_view_button.active = false;
                column_view_button.active = false;
                toggle_lock = false;
                view_stack.set_visible_child_name("stream");
            } else
                stream_view_button.active = true;
        });

        feed_list.button_press_event.connect((event) =>
        {
            TreePath? path;
            TreeIter? iter;
            feed_list.get_cursor(out path, null);
            feed_data.get_iter(out iter, path);
            if(event.button == 3 && path != null && iter != all_item && iter != unread_item && iter != starred_item && iter != category_all && iter != category_collection) {
                feed_list.popup_menu();
            }
            return false;
        });
        feed_list.popup_menu.connect(() =>
        {
            feed_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
            return false;
        });
    }

    private void add_actions()
    {
        import_action = new GLib.SimpleAction("import", null);
        import_action.activate.connect(() =>
        {
            FileChooserDialog dialog = new FileChooserDialog("Select a file to import", this, FileChooserAction.OPEN);
            dialog.add_button("Import", ResponseType.OK);
            dialog.add_button("Cancel", ResponseType.CANCEL);
            dialog.response.connect((r) =>
            {
                dialog.close();
                if(r == ResponseType.OK) {
                    File file = dialog.get_file();
                    app.import(file);
                }
            });
            dialog.run();
        });
        this.add_action(import_action);
        export_action = new GLib.SimpleAction("export", null);
        export_action.activate.connect(() =>
        {
            FileChooserDialog dialog = new FileChooserDialog("Export to\u2026", this, FileChooserAction.SAVE);
            dialog.add_button("Export", ResponseType.OK);
            dialog.add_button("Cancel", ResponseType.CANCEL);
            dialog.response.connect((r) =>
            {
                dialog.close();
                if(r == ResponseType.OK) {
                    File file = dialog.get_file();
                    app.export(file);
                }
            });
            dialog.run();
        });
        this.add_action(export_action);
        refresh_action = new GLib.SimpleAction("refresh-feeds", null);
        refresh_action.set_enabled(false);
        refresh_action.activate.connect(() =>
        {
            app.update();
        });
        this.add_action(refresh_action);
        preferences_action = new GLib.SimpleAction("app-preferences", null);
        preferences_action.activate.connect(() =>
        {
            settings.sync();
            view_stack.set_visible_child_name("settings");
            preferences_action.set_enabled(false);
        });
        this.add_action(preferences_action);
        mkread_action = new GLib.SimpleAction("mark-read", null);
        mkread_action.set_enabled(false);
        mkread_action.activate.connect(() =>
        {
            app.markAllAsRead();
        });
        this.add_action(mkread_action);
        about_action = new GLib.SimpleAction("about", null);
        about_action.activate.connect(() =>
        {
            Gtk.show_about_dialog(this,
                "program-name", ("Singularity"),
                "authors", (authorstr),
                "website", ("http://github.com/Df458/Singularity"),
                "website-label", ("Github"),
                "comments", ("A simple webfeed aggregator"),
                "version", ("0.3"),
                "license-type", ((Gtk.License)License.GPL_3_0),
                "copyright", ("Copyright © 2014-2016 Hugues Ross"));
        });
        this.add_action(about_action);

        SimpleActionGroup feed_group = new SimpleActionGroup();
        unsubscribe_action = new GLib.SimpleAction("unsubscribe", null);
        unsubscribe_action.activate.connect(() =>
        {
            TreeIter iter;
            TreePath path;
            TreeViewColumn column;
            feed_list.get_cursor(out path, out column);
            feed_data.get_iter(out iter, path);

            string name;
            int id;
            feed_data.get(iter, 1, out name, 4, out id);

            MessageDialog confirm = new MessageDialog(this, DialogFlags.MODAL, MessageType.QUESTION, ButtonsType.YES_NO, "Are you sure you want to unsubscribe from %s?", name);
            confirm.response.connect((response) => {
                if(response == Gtk.ResponseType.YES) {
                    app.removeFeed(id);
                    feed_data.remove(ref iter);
                }
                confirm.destroy();
            });
            confirm.show_all();
        });
        feed_group.add_action(unsubscribe_action);
        feed_list.insert_action_group("feed", feed_group);
    }

    private void init_menus()
    {
        GLib.Menu menu = new GLib.Menu();
        menu.append_item(new GLib.MenuItem("Import Feeds\u2026", "win.import"));
        menu.append_item(new GLib.MenuItem("Export Feeds\u2026", "win.export"));
        menu.append_item(new GLib.MenuItem("Refresh", "win.refresh-feeds"));
        menu.append_item(new GLib.MenuItem("Preferences", "win.app-preferences"));
        menu.append_item(new GLib.MenuItem("Mark All as Read", "win.mark-read"));
        menu.append_item(new GLib.MenuItem("About", "win.about"));
        menu_button.set_menu_model(menu);

        GLib.Menu feed_model = new GLib.Menu();
        feed_model.append_item(new GLib.MenuItem("Unsubscribe", "feed.unsubscribe"));
        feed_menu = new Gtk.Menu.from_model(feed_model);

        feed_menu.attach_to_widget(feed_list, null);
    }

    private void resize_columns(int size)
    {
        int w = size - col_count.get_width();
        if(w < 0)
            w = 0;
        col_name.set_fixed_width(w);
    }

    public void updateSubtitle()
    {
        // TODO: Update this to display unread items
        //if(feed_items.size > 1) {
            //top_bar.set_subtitle("You have " + feed_items.size.to_string() + " subscriptions");
        //} else if(feed_items.size == 1) {
            //top_bar.set_subtitle("You have 1 subscription");
        //} else {
            //top_bar.set_subtitle("You have no subscriptions");
            //firststart = true;
        //}
    }

    public void add_feeds(Gee.ArrayList<Feed> feeds)
    {
        for(int i = 0; i < feeds.size; ++i) {
            add_feed(feeds[i], feeds[i].id);
        }
    }

    public void add_feed(Feed f, int index)
    {
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
        // TODO: Redo this
        //if(firststart) {
            //firststart = false;
            //refresh_action.set_enabled(true);
            //set_content(web_view);
        //}
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
}
