/*
     Singularity - A web newsfeed aggregator
     Copyright (C) 2017  Hugues Ross <hugues.ross@gmail.com>

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
using Singularity;

enum ViewType {
    GRID,
    COLUMN,
    STREAM
}

// The primary application window
[GtkTemplate (ui = "/org/df458/Singularity/MainWindow.ui")]
public class MainWindow : Gtk.ApplicationWindow {
    public bool important_view {
        get { return _important_view; }
        set {
            if (_important_view != value) {
                _important_view = value;
                display_node (m_last_displayed_node);
            }
        }
    }
    private bool _important_view = true;
    public bool search_mode {
        get { return _search_mode; }
        set {
            if (_search_mode != value) {
                _search_mode = value;
                // TODO
            }
        }
    }
    private bool _search_mode = false;

    public MainWindow (SingularityApp owner_app) {
        app = owner_app;
        window_position = WindowPosition.CENTER;
        set_default_size (1024, 768);

        var group = new SimpleActionGroup ();
        group.add_action (new PropertyAction ("important", this, "important_view"));
        /* group.add_action (new PropertyAction ("search_mode", this, "search_mode")); */
        insert_action_group ("view", group);

        m_last_displayed_node = null;

        StreamItemView stream_view = new StreamItemView ();
        stream_view.items_viewed.connect ( (i) =>
        {
            app.view_items (i);
        });
        stream_view.item_read_toggle.connect ( (i) =>
        {
            app.toggle_unread (i);
        });
        stream_view.item_star_toggle.connect ( (i) =>
        {
            app.toggle_star (i);
        });
        view_stack.add_named (stream_view, "items_stream");

        ColumnItemView column_view = new ColumnItemView ();
        column_view.items_viewed.connect ( (i) =>
        {
            app.view_items (i);
        });
        column_view.item_read_toggle.connect ( (i) =>
        {
            app.toggle_unread (i);
        });
        column_view.item_star_toggle.connect ( (i) =>
        {
            app.toggle_star (i);
        });
        view_stack.add_named (column_view, "items_column");

        GridItemView grid_view = new GridItemView ();
        grid_view.items_viewed.connect ( (i) =>
        {
            app.view_items (i);
        });
        grid_view.item_read_toggle.connect ( (i) =>
        {
            app.toggle_unread (i);
        });
        grid_view.item_star_toggle.connect ( (i) =>
        {
            app.toggle_star (i);
        });
        view_stack.add_named (grid_view, "items_grid");

        m_item_view = stream_view;
        m_settings_view = new SettingsView ();
        view_stack.add_named (m_settings_view, "settings");
        feed_pane.init (this, app.get_feed_store ());
        m_feed_builder = new FeedBuilder ();

        app.update_progress_changed.connect ( (val) =>
        {
            progress_bar.fraction = val.percentage;
            progress_revealer.reveal_child = val.status == SingularityApp.LoadStatus.STARTED;
        });

        app.load_status_changed.connect ( (val) =>
        {
            feed_pane.expand_base ();
            if (val == SingularityApp.LoadStatus.COMPLETED) {
                if (app.has_subscriptions)
                    view_stack.set_visible_child (m_item_view);
                else
                    view_stack.visible_child_name = "welcome";
            }
        });

        app.subscribe_done.connect ( (f) =>
        {
            if (view_stack.visible_child_name == "welcome") {
                view_stack.set_visible_child (m_item_view);
                feed_pane.expand_base ();
            }
        });

        m_feed_builder.subscription_added.connect ( (feed, loaded, items) =>
        {
            app.subscribe_to_feed (feed, loaded, null, items);

            m_feed_builder.hide ();
        });

        m_feed_builder.cancelled.connect ( () =>
        {
            m_feed_builder.hide ();
        });

        m_settings_view.done.connect ( () =>
        {
            if (!app.init_success) {
                view_stack.visible_child_name = "loading";
            } else if (!app.has_subscriptions) {
                view_stack.visible_child_name = "welcome";
            } else {
                view_stack.set_visible_child (m_item_view);
            }
        });

        if (!app.init_success)
            view_stack.visible_child_name = "loading";

        this.show_all ();

        /*
        //Button settings_button = new Button.from_icon_name ("gtk-preferences", IconSize.MENU);
        //settings_button.set_tooltip_text ("Feed settings");
        //settings_button.set_sensitive (false);
        //settings_button.clicked.connect ( (ev) => {
            ////feed_settings.sync (app.getFeed (feed_items.index_of (feed_list.selected)));
            ////set_content (feed_settings);
            //warning ("settings_button click callback is a stub");
        //});
        */
    }

    public void display_node (CollectionNode? node) {
        m_last_displayed_node = node;

        if (node != null) {
            Gee.Iterator<Item> iter = node.data.get_items ().iterator ();
            if (important_view)
                iter = iter.filter ( (i) => { return i.unread || i.starred; });
            else {
                iter = iter.order_by ( (i1, i2) => {
                    if (i1.unread) {
                        if (!i2.unread)
                            return -1;
                    } else if (i2.unread)
                        return 1;

                    return strcmp (i1.owner.title, i2.owner.title);
                });
            }
            m_item_view.view_items (iter, node.data.title, (node.data is Feed) ? (node.data as Feed).description : "");
        }
    }

    public signal void update_requested (Feed? feed);
    public signal void unsub_requested (Feed? feed);
    public signal void new_collection_requested (FeedCollection? parent);
    public signal void rename_node_requested (CollectionNode? node, string title);
    public signal void delete_collection_requested (FeedCollection? collection);

    [GtkCallback]
    public void add_clicked (Gtk.Button button) {
        m_feed_builder.relative_to = button;
        m_feed_builder.show_all ();
    }

    [GtkCallback]
    public void on_add_requested (Widget target) {
        m_feed_builder.relative_to = target;
        m_feed_builder.show_all ();
    }

    [GtkCallback]
    public void stream_view_selected () {
        if (view_stack.visible_child_name != "welcome")
            view_stack.set_visible_child_name ("items_stream");
        m_item_view = view_stack.get_child_by_name ("items_stream") as ItemView;
        display_node (m_last_displayed_node);
    }

    [GtkCallback]
    public void column_view_selected () {
        if (view_stack.visible_child_name != "welcome")
            view_stack.set_visible_child_name ("items_column");
        m_item_view = view_stack.get_child_by_name ("items_column") as ItemView;
        display_node (m_last_displayed_node);
    }

    [GtkCallback]
    public void grid_view_selected () {
        if (view_stack.visible_child_name != "welcome")
            view_stack.set_visible_child_name ("items_grid");
        m_item_view = view_stack.get_child_by_name ("items_grid") as ItemView;
        display_node (m_last_displayed_node);
    }

    public void preferences () {
        m_settings_view.sync ();
        view_stack.set_visible_child_name ("settings");
    }

    [GtkChild]
    private Revealer progress_revealer;
    [GtkChild]
    private ProgressBar progress_bar;
    [GtkChild]
    private Stack view_stack;
    [GtkChild]
    private FeedPane feed_pane;

    private SingularityApp app;
    private SettingsView m_settings_view;

    private ItemView m_item_view;

    private FeedBuilder m_feed_builder;

    private CollectionNode? m_last_displayed_node;

    private enum FeedColumn {
        WORKING = 0,
        TITLE,
        UNREAD_COUNT,
        SHOW_UNREAD_COUNT,
        FEED_ID,
        STARRED_COUNT
    }

}
