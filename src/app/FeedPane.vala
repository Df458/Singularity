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
    public FeedCollection? selected_collection { get; private set; }

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

    public void expand_all()
    {
        feed_list.expand_all();
    }

    public signal void selection_changed(int selection_id);

    private ScrolledWindow       scroll;
    private TreeModelFilter      feed_model;
    private TreeView             feed_list;
    private CellRendererPixbuf   icon_renderer;
    private CellRendererText     title_renderer;
    private CellRendererText     count_renderer;
    private TreeViewColumn       icon_column;
    private TreeViewColumn       title_column;
    private TreeViewColumn       count_column;
    private CollectionTreeStore  feed_data;
    private unowned MainWindow   owner;

    private Gtk.Menu base_menu;
    private Gtk.Menu feed_menu;
    private Gtk.Menu collection_menu;

    private void init_structure()
    {
        scroll = new ScrolledWindow(null, null);
        scroll.hscrollbar_policy = PolicyType.NEVER;
        this.pack_start(scroll, true, true);
    }

    private void init_content()
    {
        feed_list      = new TreeView.with_model(feed_model);
        icon_renderer  = new CellRendererPixbuf();
        title_renderer = new CellRendererText();
        count_renderer = new CellRendererText();
        icon_column    = new TreeViewColumn.with_attributes("Icon",   icon_renderer,  "pixbuf", CollectionTreeStore.Column.ICON,   null);
        title_column   = new TreeViewColumn.with_attributes("Title",  title_renderer, "markup", CollectionTreeStore.Column.TITLE,  null);
        count_column   = new TreeViewColumn.with_attributes("Unread", count_renderer, "text",   CollectionTreeStore.Column.UNREAD, null);

        title_renderer.ellipsize = Pango.EllipsizeMode.END;
        icon_column.sizing = TreeViewColumnSizing.FIXED;
        title_column.sizing = TreeViewColumnSizing.FIXED;
        count_column.sizing = TreeViewColumnSizing.FIXED;
        icon_renderer.xpad = 0;
        title_column.fixed_width = 120;
        title_column.expand = true;

        feed_list.append_column(icon_column);
        feed_list.append_column(title_column);
        feed_list.append_column(count_column);
        feed_list.headers_visible = false;
        feed_list.tooltip_column = CollectionTreeStore.Column.TITLE;

        scroll.add(feed_list);
    }

    private void connect_signals()
    {
        feed_list.cursor_changed.connect(() =>
        {
            TreePath path;
            feed_list.get_cursor(out path, null);

            selected_feed = feed_data.get_feed_from_path(path);
            selected_collection = feed_data.get_collection_from_path(path);

            owner.display_node(feed_data.get_node_from_path(path));
        });
        feed_list.button_press_event.connect((event) =>
        {
            if(event.button == 3) {
                TreePath path;
                feed_list.get_path_at_pos((int)event.x, (int)event.y, out path, null, null, null);
                if(path != null) {
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
            TreePath path;
            feed_list.get_cursor(out path, null);

            if(selected_feed != null)
                feed_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
            else if(selected_collection != null)
                collection_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
            else
                base_menu.popup(null, null, null, 0, Gtk.get_current_event_time());
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
        act_unsubscribe.activate.connect(() => {
            if(selected_feed != null)
                owner.unsub_requested(selected_feed);
        });
        act_unsubscribe.set_enabled(true);
        feed_menu_group.add_action(act_unsubscribe);

        this.insert_action_group("feed", feed_menu_group);
    }

    private void init_menus()
    {
        GLib.Menu feed_model = new GLib.Menu();
        feed_model.append("Check for Updates", "feed.update");
        feed_model.append("Unsubscribe", "feed.unsubscribe");

        GLib.Menu collection_model = new GLib.Menu();
        collection_model.append("Create Collection", "collection.new");
        collection_model.append("Delete", "collection.delete");
        collection_model.append("Rename", "collection.rename");

        GLib.Menu base_model = new GLib.Menu();
        base_model.append("Create Collection", "collection.new");

        feed_menu = new Gtk.Menu.from_model(feed_model);
        feed_menu.attach_to_widget(this, null);
        collection_menu = new Gtk.Menu.from_model(collection_model);
        collection_menu.attach_to_widget(this, null);
        base_menu = new Gtk.Menu.from_model(base_model);
        base_menu.attach_to_widget(this, null);
    }
}
}
