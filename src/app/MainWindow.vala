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
using Singularity;

enum ViewType
{
    GRID,
    COLUMN,
    STREAM
}

[GtkTemplate (ui = "/org/df458/Singularity/MainWindow.ui")]
public class MainWindow : Gtk.ApplicationWindow
{
    public MainWindow(SingularityApp owner_app)
    {
        app = owner_app;
        window_position = WindowPosition.CENTER;
        set_default_size(1024, 768);

        m_last_displayed_node = null;

        StreamItemView stream_view = new StreamItemView();
        stream_view.items_viewed.connect((i) =>
        {
            app.view_items(i);
        });
        stream_view.item_read_toggle.connect((i) =>
        {
            app.toggle_unread(i);
        });
        stream_view.item_star_toggle.connect((i) =>
        {
            app.toggle_star(i);
        });
        stream_view.unread_mode_changed.connect((mode) => { display_node(m_last_displayed_node); });
        view_stack.add_named(stream_view, "items_stream");

        ColumnItemView column_view = new ColumnItemView();
        column_view.items_viewed.connect((i) =>
        {
            app.view_items(i);
        });
        column_view.item_read_toggle.connect((i) =>
        {
            app.toggle_unread(i);
        });
        column_view.item_star_toggle.connect((i) =>
        {
            app.toggle_star(i);
        });
        column_view.unread_mode_changed.connect((mode) => { display_node(m_last_displayed_node); });
        view_stack.add_named(column_view, "items_column");

        m_item_view = stream_view;
        m_settings_view = new SettingsView();
        view_stack.add_named(m_settings_view, "settings");
        feed_pane = new FeedPane(this, app.get_feed_store());
        view_pane.pack_start(feed_pane, true, true);
        m_feed_builder = new FeedBuilder();
        m_feed_builder.set_relative_to(add_button);

        app.update_progress_changed.connect((val) =>
        {
            progress_bar.fraction = val.percentage;
            progress_revealer.reveal_child = val.status == SingularityApp.LoadStatus.STARTED;
        });

        app.load_status_changed.connect((val) =>
        {
            feed_pane.expand_base();
            view_stack.set_visible_child(m_item_view);
        });

        m_feed_builder.subscription_added.connect((feed, loaded, items) =>
        {
            app.subscribe_to_feed(feed, loaded, null, items);
            m_feed_builder.hide();
        });

        m_feed_builder.cancelled.connect(() =>
        {
            m_feed_builder.hide();
        });

        m_settings_view.done.connect(() =>
        {
            view_stack.set_visible_child(m_item_view);
        });

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

    public void display_node(CollectionNode? node)
    {
        m_last_displayed_node = node;

        if(node != null) {
            warning(node.data.title);
            Gee.Iterator<Item> iter = node.data.get_items().iterator();
            if(m_item_view.get_important_only())
                iter = iter.filter((i) => { return i.unread || i.starred; });
            else {
                iter = iter.order_by((i1, i2) => {
                    if(i1.unread) {
                        if(!i2.unread)
                            return -1;
                    } else if(i2.unread)
                        return 1;

                    return strcmp(i1.owner.title, i2.owner.title);
                });
            }
            m_item_view.view_items(iter, node.data.title, (node.data is Feed) ? (node.data as Feed).description : "");
        }
    }
    
    public signal void update_requested(Feed? feed);
    public signal void unsub_requested(Feed? feed);
    public signal void new_collection_requested(FeedCollection? parent);
    public signal void rename_node_requested(CollectionNode? node, string title);
    public signal void delete_collection_requested(FeedCollection? collection);

    [GtkCallback]
    public void add_clicked()
    {
        m_feed_builder.show_all();
    }

    [GtkCallback]
    public void stream_view_selected()
    {
        view_stack.set_visible_child_name("items_stream");
        m_item_view = view_stack.get_child_by_name("items_stream") as ItemView;
        display_node(m_last_displayed_node);
    }

    [GtkCallback]
    public void column_view_selected()
    {
        view_stack.set_visible_child_name("items_column");
        m_item_view = view_stack.get_child_by_name("items_column") as ItemView;
        display_node(m_last_displayed_node);
    }

    [GtkCallback]
    public void grid_view_selected()
    {
        view_stack.set_visible_child_name("items_grid");
        m_item_view = view_stack.get_child_by_name("items_grid") as ItemView;
        display_node(m_last_displayed_node);
    }

    public void preferences()
    {
        m_settings_view.sync();
        view_stack.set_visible_child_name("settings");
    }

    public void show_properties(Feed f)
    {
        PropertiesWindow properties_window = new PropertiesWindow();
        properties_window.set_feed(f);
        properties_window.present();
    }

    [GtkChild]
    private Box view_pane;
    [GtkChild]
    private Revealer     progress_revealer;
    [GtkChild]
    private ProgressBar  progress_bar;
    [GtkChild]
    private Stack    view_stack;
    [GtkChild]
    private Button add_button;

    private SingularityApp app;
    private FeedPane feed_pane;
    private SettingsView m_settings_view;

    private ItemView m_item_view;

    private FeedBuilder m_feed_builder;

    private CollectionNode? m_last_displayed_node;

    private enum FeedColumn
    {
        WORKING = 0,
        TITLE,
        UNREAD_COUNT,
        SHOW_UNREAD_COUNT,
        FEED_ID,
        STARRED_COUNT
    }

}
