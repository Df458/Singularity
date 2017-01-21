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

        m_item_view = new StreamItemView(owner_app.get_global_settings());
        m_settings_view = new SettingsView(app.get_global_settings());
        view_stack.add_named(m_item_view, "items");
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
            feed_pane.expand();
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
        app.query_items.begin(node, m_item_view.get_important_only(), false, (obj, res) =>
        {
            Gee.List<Item?> item_list = app.query_items.end(res);
            m_item_view.view_items(item_list);
        });
    }
    
    public signal void update_requested(Feed? feed);
    public signal void unsub_requested(Feed? feed);

    [GtkCallback]
    public void add_clicked()
    {
        m_feed_builder.show_all();
    }

    public void preferences() {
        m_settings_view.sync();
        view_stack.set_visible_child_name("settings");
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
