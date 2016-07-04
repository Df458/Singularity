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

namespace Singularity
{
public class FeedPane : Gtk.Box
{
    public Feed? selected_feed { get; private set; }

    public FeedPane(MainWindow owner_window, CollectionTreeStore store)
    {
        owner = owner_window;
        orientation = Orientation.VERTICAL;
        spacing     = 12;
        homogeneous = false;

        feed_data = store;
        feed_model = new TreeModelFilter(store, null);

        init_structure();
        init_content();
        connect_signals();
        add_actions();
        init_menus();
    }

    public signal void selection_changed(int selection_id);

    private ScrolledWindow       scroll;
    private TreeModelFilter      feed_model;
    private TreeView             feed_list;
    private CellRendererText     title_renderer;
    private TreeViewColumn       title_column;
    private CollectionTreeStore  feed_data;
    private unowned MainWindow   owner;

    private Gtk.Menu feed_menu;

    private void init_structure()
    {
        scroll = new ScrolledWindow(null, null);
        scroll.hscrollbar_policy = PolicyType.NEVER;
        this.pack_start(scroll, true, true);
    }

    private void init_content()
    {
        feed_list      = new TreeView.with_model(feed_model);
        title_renderer = new CellRendererText();
        title_column   = new TreeViewColumn.with_attributes("Title", title_renderer, "markup", CollectionTreeStore.Column.TITLE, null);

        title_column.sizing = TreeViewColumnSizing.FIXED;

        feed_list.append_column(title_column);
        feed_list.headers_visible   = false;
        feed_list.fixed_height_mode = true;
        feed_list.tooltip_column    = CollectionTreeStore.Column.TITLE;

        scroll.add(feed_list);
    }

    private void connect_signals()
    {
        feed_list.cursor_changed.connect(() =>
        {
            TreePath path;
            feed_list.get_cursor(out path, null);

            selected_feed = feed_data.get_feed_from_path(path);

            owner.display_node(feed_data.get_node_from_path(path));
        });
        feed_list.button_press_event.connect((event) =>
        {
            if(event.button == 3) {
                TreePath path;
                feed_list.get_path_at_pos((int)event.x, (int)event.y, out path, null, null, null);
                if(path != null) {
                    /* feed_list.select_path(path); */
                    feed_list.set_cursor(path, null, false);
                } else {
                    feed_list.unselect_all();
                }
                feed_list.popup_menu();
            }
            return false;
        });
        feed_list.popup_menu.connect(() =>
        {
            /* if(feed_list.get_selected_items().length() == 0) */
                ;/* content_menu.popup(null, null, null, 0, Gtk.get_current_event_time()); */
            /* else */
                feed_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
            return false;
        });
    }

    private void add_actions()
    {
        SimpleActionGroup feed_menu_group = new SimpleActionGroup();
        SimpleAction act_update = new SimpleAction("update", null);
        act_update.activate.connect(() => { if(selected_feed != null) owner.update_requested(selected_feed); });
        act_update.set_enabled(true);
        feed_menu_group.add_action(act_update);

        SimpleAction act_unsubscribe = new SimpleAction("unsubscribe", null);
        feed_menu_group.add_action(act_unsubscribe);

        this.insert_action_group("feed", feed_menu_group);
    }

    private void init_menus()
    {
        GLib.Menu feed_model = new GLib.Menu();
        feed_model.append("Check for Updates", "feed.update");
        feed_model.append("Unsubscribe", "feed.unsubscribe");

        feed_menu = new Gtk.Menu.from_model(feed_model);
        feed_menu.attach_to_widget(this, null);
    }
}
}
