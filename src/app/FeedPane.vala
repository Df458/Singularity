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
using DFLib;

namespace Singularity {
// The contents of the left pane, which holds the treeview for browsing feeds
[GtkTemplate (ui="/org/df458/Singularity/FeedPane.ui")]
public class FeedPane : Bin {
    // Action groups
    private const string G_VIEW = "view";

    // Actions
    private const string A_SEARCH_MODE = "search-mode";
    private const string A_ADD_FEED = "add-feed";

    public Feed? selected_feed { get; private set; }
    public FeedCollection? selected_collection { get; private set; }

    public bool search_mode {
        get { return _search_mode; }
        set {
            if (_search_mode != value) {
                _search_mode = value;

                search_bar.search_mode_enabled = value;
            }
        }
    }
    private bool _search_mode = false;

    construct {
        init_content ();
        add_actions ();
        init_menus ();
    }

    public void init (MainWindow owner_window, CollectionTreeStore store) {
        owner = owner_window;

        feed_data = store;
        feed_model = new CollectionTreeModelFilter (store);
        feed_list.set_model (feed_model);

        TreeIter iter;
        if (feed_model.get_iter_first (out iter)) {
            feed_list.set_cursor (feed_model.get_path (iter), null, false);
        }
    }

    // Expand the base category (All Feeds)
    public void expand_base () {
        feed_list.expand_row (new TreePath.first (), false);
    }

    public signal void add_requested (Widget target);

    private CollectionTreeModelFilter feed_model;
    [GtkChild]
    private TreeView feed_list;
    [GtkChild]
    private CellRendererPixbuf icon_renderer;
    [GtkChild]
    private CellRendererText title_renderer;
    [GtkChild]
    private CellRendererText count_renderer;
    [GtkChild]
    private TreeViewColumn title_column;
    [GtkChild]
    private TreeViewColumn count_column;
    [GtkChild]
    private SearchBar search_bar;
    private CollectionTreeStore feed_data;
    private unowned MainWindow owner;

    private Gtk.Menu base_menu;
    private Gtk.Menu feed_menu;
    private Gtk.Menu collection_menu;

    private void init_content () {
        title_column.add_attribute (icon_renderer, "pixbuf", CollectionTreeStore.Column.ICON);
        title_column.add_attribute (title_renderer, "markup", CollectionTreeStore.Column.TITLE);
        title_column.add_attribute (title_renderer, "weight", CollectionTreeStore.Column.WEIGHT);

        count_column.cell_area.attribute_connect (count_renderer, "text", CollectionTreeStore.Column.UNREAD);
        count_column.cell_area.attribute_connect (count_renderer, "visible", CollectionTreeStore.Column.UNREAD);

        icon_renderer.xpad = 0;
        title_column.expand = true;

        feed_list.tooltip_column = CollectionTreeStore.Column.TITLE;
        feed_list.enable_model_drag_source (Gdk.ModifierType.BUTTON1_MASK, {
            TargetEntry () {
                target="SINGULARTY_COLLECTION_NODE",
                flags=0,
                info=0
            }
        }, Gdk.DragAction.MOVE);
        feed_list.enable_model_drag_dest ( {
            TargetEntry () {
                target="SINGULARTY_COLLECTION_NODE",
                flags=0,
                info=0
            }
        }, Gdk.DragAction.MOVE);
    }

    private void add_actions () {
        var group = new SimpleActionGroup ();
        group.add_action (new PropertyAction (A_SEARCH_MODE, this, "search_mode"));
        insert_action_group (G_VIEW, group);

        SimpleActionGroup feed_menu_group = new SimpleActionGroup ();
        SimpleActionGroup collection_menu_group = new SimpleActionGroup ();

        SimpleAction act_properties = new SimpleAction ("properties", null);
        act_properties.activate.connect (show_properties);
        act_properties.set_enabled (true);
        feed_menu_group.add_action (act_properties);

        SimpleAction act_update = new SimpleAction ("update", null);
        act_update.activate.connect (() => { if (selected_feed != null) owner.update_requested (selected_feed); });
        act_update.set_enabled (true);
        feed_menu_group.add_action (act_update);

        SimpleAction act_unsubscribe = new SimpleAction ("unsubscribe", null);
        act_unsubscribe.activate.connect (() => {
            if (selected_feed != null)
                owner.unsub_requested (selected_feed);
        });
        act_unsubscribe.set_enabled (true);
        feed_menu_group.add_action (act_unsubscribe);

        SimpleAction act_collection_new = new SimpleAction ("new", null);
        act_collection_new.activate.connect (() => {
            if (selected_feed != null)
                owner.new_collection_requested (selected_feed.parent);
            else
                owner.new_collection_requested (selected_collection);
        });
        act_collection_new.set_enabled (true);
        collection_menu_group.add_action (act_collection_new);

        SimpleAction act_collection_rename = new SimpleAction ("rename", null);
        act_collection_rename.activate.connect (() => {
            if (selected_collection != null) {
                Gtk.TreePath path = null;
                Gtk.TreeViewColumn column;
                feed_list.get_cursor (out path, out column);
                if (path != null) {
                    title_renderer.editable = true;
                    feed_list.set_cursor (path, title_column, true);
                    title_renderer.editable = false;
                }
            }
        });
        act_collection_rename.set_enabled (true);
        collection_menu_group.add_action (act_collection_rename);

        SimpleAction act_collection_delete = new SimpleAction ("delete", null);
        act_collection_delete.activate.connect (() => {
            if (selected_collection != null) {
                owner.delete_collection_requested (selected_collection);
            }
        });
        act_collection_delete.set_enabled (true);
        collection_menu_group.add_action (act_collection_delete);

        this.insert_action_group ("feed", feed_menu_group);
        this.insert_action_group ("collection", collection_menu_group);
    }

    private void init_menus () {
        GLib.Menu feed_model = new GLib.Menu ();
        feed_model.append ("Properties", "feed.properties");
        feed_model.append ("Create Collection", "collection.new");
        feed_model.append ("Check for Updates", "feed.update");
        feed_model.append ("Unsubscribe", "feed.unsubscribe");

        GLib.Menu collection_model = new GLib.Menu ();
        collection_model.append ("Create Collection", "collection.new");
        collection_model.append ("Delete", "collection.delete");
        collection_model.append ("Rename", "collection.rename");

        GLib.Menu base_model = new GLib.Menu ();
        base_model.append ("Create Collection", "collection.new");

        feed_menu = new Gtk.Menu.from_model (feed_model);
        feed_menu.attach_to_widget (this, null);
        collection_menu = new Gtk.Menu.from_model (collection_model);
        collection_menu.attach_to_widget (this, null);
        base_menu = new Gtk.Menu.from_model (base_model);
        base_menu.attach_to_widget (this, null);
    }

    private void show_properties () {
        if (selected_feed != null) {
            new Singularity.App.PropertiesWindow (owner, selected_feed).present ();
        }
    }

    [GtkCallback]
    private void drag_set_feed (Gdk.DragContext ctx, SelectionData data, uint info, uint time) {
        Gtk.TreePath path = null;
        feed_list.get_cursor (out path, null);
        int id = -1;
        if (path != null)
            id = feed_data.get_node_from_path (path).id;

        data.set (ctx.list_targets ().first ().data, 1, id.to_string ().data);
    }

    [GtkCallback]
    private void drag_get_feed (Gdk.DragContext ctx, int x, int y, SelectionData data, uint info, uint time) {
        Signal.stop_emission_by_name (feed_list, "drag-data-received");
        int id = int.parse ((string)data.get_data ());
        TreePath? path = null;
        if (id == -1 || !feed_list.get_dest_row_at_pos (x, y, out path, null)) {
            drag_finish (ctx, false, false, time);
            return;
        }

        CollectionNode src = feed_data.get_node_from_id (id);
        CollectionNode dest = feed_data.get_node_from_path (path);

        if (!feed_data.move_node (src, dest)) {
            drag_finish (ctx, false, false, time);
            return;
        }

        drag_finish (ctx, true, false, time);
    }

    [GtkCallback]
    private bool drag_drop_feed (Gdk.DragContext ctx, int x, int y, uint time) {
        TreePath? path = null;
        if (!feed_list.get_dest_row_at_pos (x, y, out path, null))
            return false;

        drag_get_data (feed_list, ctx, ctx.list_targets ().first ().data, time);

        return true;
    }

    [GtkCallback]
    private bool on_click_menu (Gdk.EventButton event) {
        TreePath path;
        feed_list.get_path_at_pos ((int)event.x, (int)event.y, out path, null, null, null);
        if (event.button == 3) { // Right click
            if (path != null) {
                feed_list.set_cursor (path, null, false);

                // Popup a menu based on the selected node
                if (!feed_data.is_path_root (path)) {
                    if (selected_feed != null) {
                        feed_menu.popup_at_pointer (event);
                    } else if (selected_collection != null) {
                        collection_menu.popup_at_pointer (event);
                    }
                } else {
                    base_menu.popup_at_pointer (event);
                }
            } else {
                feed_list.unselect_all ();

                base_menu.popup_at_pointer (event);
            }
        }
        return false;
    }

    [GtkCallback]
    private void on_cursor_change () {
        TreePath path;
        feed_list.get_cursor (out path, null);

        if (path != null) {
            path = feed_model.convert_path_to_child_path (path);
            if (path != null) {
                FeedDataEntry entry = feed_data.get_data_from_path (path);

                selected_feed = entry as Feed;
                selected_collection = entry as FeedCollection;

                owner.display_node (feed_data.get_node_from_path (path));
            }
        }
    }

    [GtkCallback]
    private void title_edit_done (string path, string title) {
        owner.rename_node_requested (feed_data.get_node_from_path (new TreePath.from_string (path)), title);
        title_renderer.editable = false;
    }

    [GtkCallback]
    private void title_edit_cancel () {
        title_renderer.editable = false;
    }

    [GtkCallback]
    private void on_search_changed (SearchEntry entry) {
        feed_model.search_text = entry.text;
        if(feed_model.has_search_text) {
            feed_list.expand_all ();
        } else {
            feed_list.collapse_all ();
            expand_base ();
        }
    }

    [GtkCallback]
    private void on_stop_search (SearchEntry entry) {
        search_mode = false;
        feed_list.collapse_all ();
        expand_base ();
    }

    [GtkCallback]
    private void on_add_feed (Button button) {
        add_requested (button);
    }
}
}
