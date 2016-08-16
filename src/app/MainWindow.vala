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

using Gtk;
using Gdk;

namespace Singularity
{
enum ViewType
{
    GRID,
    COLUMN,
    STREAM
}

public class MainWindow : Gtk.ApplicationWindow
{
    private Box   main_box;
    private Paned main_paned;
    private SingularityApp app;
    /* private string current_view = "grid"; */
    /* private bool   toggle_lock = false; // Prevents extra button toggle changes when selecting a view */

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
    /* private SimpleAction mkread_action; */
    private SimpleAction about_action;

    // Search
    private SearchBar   item_search_bar;
    private SearchEntry item_search_entry;
    /* private Gtk.Menu feed_menu; */

    private FeedPane feed_pane;

    private Popover     feed_popover;
    private FeedBuilder feed_builder;

    // Statusbar
    private ActionBar    status_bar;
    private Box          view_switcher;
    private ToggleButton grid_view_button;
    private ToggleButton column_view_button;
    private ToggleButton stream_view_button;
    private Label        status_label;
    private Revealer     progress_revealer;
    private Spinner      progress_spinner;
    private ProgressBar  progress_bar;
    // Views
    private Stack    view_stack;
    private ItemView m_item_view;
    private SettingsPane settings;
    private FeedSettingsPane feed_settings;
    private AddPane add_pane;

    private CollectionNode? m_last_displayed_node;

    static const string[] authorstr = { "Hugues Ross(df458)" };

    private enum FeedColumn
    {
        WORKING = 0,
        TITLE,
        UNREAD_COUNT,
        SHOW_UNREAD_COUNT,
        FEED_ID,
        STARRED_COUNT
    }

    public MainWindow(SingularityApp owner_app)
    {
        app = owner_app;
        window_position = WindowPosition.CENTER;
        set_default_size(1024, 768);

        m_last_displayed_node = null;

        init_structure();
        init_content(owner_app.get_feed_store());
        connect_signals();
        add_actions();
        init_menus();

        /* resize_columns(128); */
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

    // TODO: Allow filtering unread/starred
    public void display_node(CollectionNode? node)
    {
        m_last_displayed_node = node;
        app.query_items.begin(node, m_item_view.unread_only, false, (obj, res) =>
        {
            Gee.List<Item?> item_list = app.query_items.end(res);
            m_item_view.view_items(item_list);
        });
    }
    
    public signal void update_requested(Feed? feed);
    public signal void unsub_requested(Feed? feed);


    private void init_structure()
    {
        top_bar = new HeaderBar();
        main_box = new Box(Orientation.VERTICAL, 0);
        main_paned = new Paned(Orientation.HORIZONTAL);
        item_search_bar = new SearchBar();
        status_bar = new ActionBar();
        view_stack = new Stack();
        progress_revealer = new Revealer();
        progress_revealer.transition_type = RevealerTransitionType.SLIDE_RIGHT;
        progress_revealer.reveal_child = false;

        top_bar.set_title("Singularity");
        main_paned.position = 128;

        main_paned.pack2(view_stack, true, true);
        main_box.pack_start(item_search_bar, false, false);
        main_box.pack_start(main_paned, true, true);
        status_bar.pack_end(progress_revealer);
        main_box.pack_start(status_bar, false, false);
        this.add(main_box);
        this.set_titlebar(top_bar);
    }

    private void init_content(CollectionTreeStore store)
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
        m_item_view         = new ItemView(app.get_global_settings());
        settings            = new SettingsPane(app.get_global_settings());
        feed_settings       = new FeedSettingsPane();
        add_pane            = new AddPane();
        feed_pane           = new FeedPane(this, store);
        feed_popover        = new Popover(add_button);
        feed_builder        = new FeedBuilder();

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

        grid_view_button.active = true;

        item_search_bar.add(item_search_entry);
        item_search_bar.connect_entry(item_search_entry);
        view_switcher.add(grid_view_button);
        view_switcher.add(column_view_button);
        view_switcher.add(stream_view_button);
        view_stack.add_named(m_item_view, "items");
        view_stack.add_named(settings, "settings");
        view_stack.add_named(feed_settings, "feed_settings");
        view_stack.add_named(add_pane, "add");
        m_item_view.show_all();
        view_stack.set_visible_child(m_item_view);
        status_bar.set_center_widget(status_label);
        status_bar.pack_start(view_switcher);
        status_bar.pack_end(progress_spinner);
        progress_revealer.add(progress_bar);
        top_bar.pack_start(add_button);
        top_bar.pack_end(menu_button);
        top_bar.pack_end(item_search_toggle);
        feed_popover.add(feed_builder);
        main_paned.pack1(feed_pane, true, true);
    }

    private void connect_signals()
    {
        add_button.clicked.connect((ev) =>
        {
            feed_popover.show_all();
        });

        feed_builder.subscription_added.connect((feed, loaded, items) =>
        {
            app.subscribe_to_feed(feed, loaded, null, items);
            feed_popover.hide();
        });

        feed_builder.cancelled.connect(() =>
        {
            feed_popover.hide();
        });

        m_item_view.item_viewed.connect((i) =>
        {
            app.view_item(i);
        });

        m_item_view.item_read_toggle.connect((i) =>
        {
            app.toggle_unread(i);
        });

        m_item_view.item_star_toggle.connect((i) =>
        {
            app.toggle_star(i);
        });

        m_item_view.unread_mode_changed.connect((mode) => { display_node(m_last_displayed_node); });

        app.update_progress_changed.connect((val) =>
        {
            progress_bar.fraction = val.percentage;
            progress_revealer.reveal_child = val.status == SingularityApp.LoadStatus.STARTED;
        });

        app.load_status_changed.connect((val) =>
        {
            feed_pane.expand();
        });

    /*     main_paned.notify.connect((spec, prop) => */
    /*     { */
    /*         if(prop.name == "position") { */
    /*             resize_columns(main_paned.get_position()); */
    /*         } */
    /*     }); */
    /*  */
    /*     feed_list_scroll.size_allocate.connect(() => */
    /*     { */
    /*         resize_columns(main_paned.get_position()); */
    /*     }); */
    /*  */
    /*     item_search_toggle.toggled.connect(() => */
    /*     { */
    /*         item_search_bar.search_mode_enabled = item_search_toggle.active; */
    /*     }); */
    /*  */
        settings.done.connect(() =>
        {
            view_stack.set_visible_child(m_item_view);
            preferences_action.set_enabled(true);
        });

    /*     grid_view_button.toggled.connect(() => */
    /*     { */
    /*         if(toggle_lock) */
    /*             return; */
    /*  */
    /*         if(grid_view_button.active) { */
    /*             toggle_lock = true; */
    /*             column_view_button.active = false; */
    /*             stream_view_button.active = false; */
    /*             toggle_lock = false; */
    /*             view_stack.set_visible_child_name("grid"); */
    /*         } else */
    /*             grid_view_button.active = true; */
    /*     }); */
    /*  */
    /*     column_view_button.toggled.connect(() => */
    /*     { */
    /*         if(toggle_lock) */
    /*             return; */
    /*  */
    /*         if(column_view_button.active) { */
    /*             toggle_lock = true; */
    /*             grid_view_button.active = false; */
    /*             stream_view_button.active = false; */
    /*             toggle_lock = false; */
    /*             view_stack.set_visible_child_name("column"); */
    /*         } else */
    /*             column_view_button.active = true; */
    /*     }); */
    /*  */
    /*     stream_view_button.toggled.connect(() => */
    /*     { */
    /*         if(toggle_lock) */
    /*             return; */
    /*  */
    /*         if(stream_view_button.active) { */
    /*             toggle_lock = true; */
    /*             grid_view_button.active = false; */
    /*             column_view_button.active = false; */
    /*             toggle_lock = false; */
    /*             view_stack.set_visible_child_name("stream"); */
    /*         } else */
    /*             stream_view_button.active = true; */
    /*     }); */
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
                    app.opml_import(file);
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
                    app.opml_export(file);
                }
            });
            dialog.run();
        });
        this.add_action(export_action);
        refresh_action = new GLib.SimpleAction("refresh-feeds", null);
        refresh_action.set_enabled(true);
        refresh_action.activate.connect(() =>
        {
            app.check_for_updates(true);
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
    /*     mkread_action = new GLib.SimpleAction("mark-read", null); */
    /*     mkread_action.set_enabled(false); */
    /*     mkread_action.activate.connect(() => */
    /*     { */
    /*         app.markAllAsRead(); */
    /*     }); */
    /*     this.add_action(mkread_action); */
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

    /*     SimpleActionGroup feed_group = new SimpleActionGroup(); */
    /*     unsubscribe_action = new GLib.SimpleAction("unsubscribe", null); */
    /*     unsubscribe_action.activate.connect(() => */
    /*     { */
    /*         TreeIter iter; */
    /*         TreePath path; */
    /*         TreeViewColumn column; */
    /*         feed_list.get_cursor(out path, out column); */
    /*         feed_data.get_iter(out iter, path); */
    /*  */
    /*         string name; */
    /*         int id; */
    /*         feed_data.get(iter, 1, out name, 4, out id); */
    /*  */
    /*         MessageDialog confirm = new MessageDialog(this, DialogFlags.MODAL, MessageType.QUESTION, ButtonsType.YES_NO, "Are you sure you want to unsubscribe from %s?", name); */
    /*         confirm.response.connect((response) => { */
    /*             if(response == Gtk.ResponseType.YES) { */
    /*                 app.removeFeed(id); */
    /*                 feed_data.remove(ref iter); */
    /*             } */
    /*             confirm.destroy(); */
    /*         }); */
    /*         confirm.show_all(); */
    /*     }); */
    /*     feed_group.add_action(unsubscribe_action); */
    /*     feed_list.insert_action_group("feed", feed_group); */
    }

    private void init_menus()
    {
        GLib.Menu menu = new GLib.Menu();
        menu.append_item(new GLib.MenuItem("Import Feeds\u2026", "win.import"));
        menu.append_item(new GLib.MenuItem("Export Feeds\u2026", "win.export"));
        menu.append_item(new GLib.MenuItem("Check for Updates", "win.refresh-feeds"));
        menu.append_item(new GLib.MenuItem("Preferences", "win.app-preferences"));
    /*     menu.append_item(new GLib.MenuItem("Mark All as Read", "win.mark-read")); */
        menu.append_item(new GLib.MenuItem("About", "win.about"));
        menu_button.set_menu_model(menu);

    /*     GLib.Menu feed_model = new GLib.Menu(); */
    /*     feed_model.append_item(new GLib.MenuItem("Unsubscribe", "feed.unsubscribe")); */
    /*     feed_menu = new Gtk.Menu.from_model(feed_model); */

    /*     feed_menu.attach_to_widget(feed_list, null); */
    }
    /*  */
    /* private void resize_columns(int size) */
    /* { */
    /*     int w = size - col_count.get_width(); */
    /*     if(w < 0) */
    /*         w = 0; */
    /*     col_name.set_fixed_width(w); */
    /* } */
    /*  */
    /* public void updateSubtitle() */
    /* { */
    /*     // TODO: Update this to display unread items */
    /*     //if(feed_items.size > 1) { */
    /*         //top_bar.set_subtitle("You have " + feed_items.size.to_string() + " subscriptions"); */
    /*     //} else if(feed_items.size == 1) { */
    /*         //top_bar.set_subtitle("You have 1 subscription"); */
    /*     //} else { */
    /*         //top_bar.set_subtitle("You have no subscriptions"); */
    /*         //firststart = true; */
    /*     //} */
    /* } */
}
}
