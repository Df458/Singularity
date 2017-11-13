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
        title_column    = new TreeViewColumn.with_area(new CellAreaBox());
        title_column.cell_area.add(icon_renderer);
        title_column.cell_area.add(title_renderer);

        title_column.cell_area.attribute_connect(icon_renderer, "pixbuf", CollectionTreeStore.Column.ICON);
        title_column.cell_area.attribute_connect(title_renderer, "markup", CollectionTreeStore.Column.TITLE);
        title_column.cell_area.attribute_connect(title_renderer, "weight", CollectionTreeStore.Column.WEIGHT);

        count_column   = new TreeViewColumn.with_attributes("Unread", count_renderer, "text",   CollectionTreeStore.Column.UNREAD, null);

        title_renderer.ellipsize = Pango.EllipsizeMode.END;
        title_column.sizing = TreeViewColumnSizing.FIXED;
        count_column.sizing = TreeViewColumnSizing.FIXED;
        icon_renderer.xpad = 0;
        title_column.fixed_width = 120;
        title_column.expand = true;

        feed_list.append_column(title_column);
        feed_list.append_column(count_column);
        feed_list.headers_visible = false;
        feed_list.tooltip_column = CollectionTreeStore.Column.TITLE;
        feed_list.enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, { TargetEntry(){ target="SINGULARTY_COLLECTION_NODE", flags=0, info=0 } }, Gdk.DragAction.MOVE);
        feed_list.enable_model_drag_dest({ TargetEntry(){ target="SINGULARTY_COLLECTION_NODE", flags=0, info=0 } }, Gdk.DragAction.MOVE);

        scroll.add(feed_list);
    }

    private void connect_signals()
    {
        feed_list.cursor_changed.connect(() =>
        {
            TreePath path;
            feed_list.get_cursor(out path, null);

            FeedDataEntry entry = feed_data.get_data_from_path(path);

            selected_feed = entry as Feed;
            selected_collection = entry as FeedCollection;

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

        feed_list.drag_data_get.connect((ctx, data, info, time) =>
        {
            Gtk.TreePath path = null;
            feed_list.get_cursor(out path, null);
            int id = -1;
            if(path != null)
                id = feed_data.get_node_from_path(path).id;

            warning("Passing data: %d", id);

            /* data.set_text(id.to_string(), -1); */
            /* data.set(ctx.list_targets().first().data, 1, (uchar[])id); */
            data.set(ctx.list_targets().first().data, 1, id.to_string().data);
        });
        feed_list.drag_drop.connect((ctx, x, y, time) =>
        {
            TreePath? path = null;
            if(!feed_list.get_dest_row_at_pos(x, y, out path, null))
                return false;

                warning("getting %s...", ctx.list_targets().first().data.name());
            drag_get_data(feed_list, ctx, ctx.list_targets().first().data, time);

            return true;
        });
        feed_list.drag_data_received.connect((ctx, x, y, data, info, time) =>
        {
            Signal.stop_emission_by_name(feed_list, "drag-data-received");
            warning("Got data: %s %d, %d", data.get_text(), data.get_length(), data.get_format());
            /* int id = int.parse(data.get_text()); */
            int id = int.parse((string)data.get_data());
            warning("Got data: %d", id);
            TreePath? path = null;
            if(id == -1 || !feed_list.get_dest_row_at_pos(x, y, out path, null)) {
                drag_finish(ctx, false, false, time);
                return;
            }

            CollectionNode src = feed_data.get_node_from_id(id);
            CollectionNode dest = feed_data.get_node_from_path(path);

            if(!feed_data.move_node(src, dest)) {
                drag_finish(ctx, false, false, time);
                return;
            }

            drag_finish(ctx, true, false, time);
        });

        title_renderer.editing_canceled.connect(() =>
        {
            title_renderer.editable = false;
        });

        title_renderer.edited.connect((path, text) =>
        {
            owner.rename_node_requested(feed_data.get_node_from_path(new TreePath.from_string(path)), text);
            title_renderer.editable = false;
        });
    }

    private void add_actions()
    {
        SimpleActionGroup feed_menu_group = new SimpleActionGroup();
        SimpleActionGroup collection_menu_group = new SimpleActionGroup();

        SimpleAction act_properties = new SimpleAction("properties", null);
        act_properties.activate.connect(() => { if(selected_feed != null) owner.show_properties(selected_feed); });
        act_properties.set_enabled(true);
        feed_menu_group.add_action(act_properties);

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

        SimpleAction act_collection_new = new SimpleAction("new", null);
        act_collection_new.activate.connect(() => {
            if(selected_feed != null)
                owner.new_collection_requested(selected_feed.parent);
            else
                owner.new_collection_requested(selected_collection);
        });
        act_collection_new.set_enabled(true);
        collection_menu_group.add_action(act_collection_new);

        SimpleAction act_collection_rename = new SimpleAction("rename", null);
        act_collection_rename.activate.connect(() => {
            if(selected_collection != null) {
                Gtk.TreePath path = null;
                Gtk.TreeViewColumn column;
                feed_list.get_cursor(out path, out column);
                if(path != null) {
                    title_renderer.editable = true;
                    feed_list.set_cursor(path, title_column, true);
                    title_renderer.editable = false;
                }
            }
        });
        act_collection_rename.set_enabled(true);
        collection_menu_group.add_action(act_collection_rename);

        SimpleAction act_collection_delete = new SimpleAction("delete", null);
        act_collection_delete.activate.connect(() => {
            if(selected_collection != null) {
                owner.delete_collection_requested(selected_collection);
            }
        });
        act_collection_delete.set_enabled(true);
        collection_menu_group.add_action(act_collection_delete);

        this.insert_action_group("feed", feed_menu_group);
        this.insert_action_group("collection", collection_menu_group);
    }

    private void init_menus()
    {
        GLib.Menu feed_model = new GLib.Menu();
        feed_model.append("Properties", "feed.properties");
        feed_model.append("Create Collection", "collection.new");
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
