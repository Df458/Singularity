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

namespace Singularity
{
    // TreeStore for holding CollectionNodes.
    // Provides additional helper functions for managing nodes.
    public class CollectionTreeStore : TreeStore
    {
        public static string FEED_CATEGORY_STRING = "All Feeds";

        // Represents the columns of the tree store.
        // Please always use this value rather than numerical indices.
        public enum Column
        {
            ID = 0,
            TITLE,
            WEIGHT,
            ICON,
            NODE,
            UNREAD,
            COUNT
        }

        construct
        {
            set_column_types({ typeof(int), typeof(string), typeof(int), typeof(Gdk.Pixbuf), typeof(CollectionNode), typeof(int) });
            set_sort_column_id(Column.TITLE, SortType.ASCENDING);

            CollectionNode root_node = new CollectionNode(root_collection);
            node_map[-1] = root_node;
            append(out base_iter, null);
            set(base_iter, Column.ID, -1, Column.TITLE, FEED_CATEGORY_STRING, Column.WEIGHT, 800, Column.UNREAD, 0, Column.NODE, root_node, -1);

            try {
                feed_icon_default = Gtk.IconTheme.get_default().load_icon("application-rss+xml-symbolic", 16, IconLookupFlags.FORCE_SIZE);
                collection_icon_default = Gtk.IconTheme.get_default().load_icon("folder-symbolic", 16, IconLookupFlags.FORCE_SIZE);
            } catch(Error e) {
                error("Failed to load default icons: %s", e.message);
            }
        }

        public CollectionTreeStore.from_collection(FeedCollection fc)
        {
            append_root_collection(fc);
        }

        public signal void parent_changed(FeedDataEntry node, int id);

        // Adds the contents of a FeedCollection to the root node.
        public void append_root_collection(FeedCollection fc)
        {
            foreach(CollectionNode n in fc.nodes)
                append_node(n);
        }

        // Adds a single node, with the option of providing its parent.
        // If the parent is null, the root node will be used.
        public void append_node(CollectionNode node, TreeIter? parent = null)
        {
            if(node_map.has_key(node.id))
                return;

            if(parent == null) {
                parent = base_iter;
                root_collection.add_node(node);
            }

            node_map.set(node.id, node);

            TreeIter iter;
            append(out iter, parent);
            set(iter, Column.ID, node.id, Column.TITLE, node.data.title, Column.NODE, node);

            if(node.data is Feed) {
                if((node.data as Feed).icon != null)
                    set(iter, Column.ICON, (node.data as Feed).icon);
                else
                    set(iter, Column.ICON, feed_icon_default);
            } else
                set(iter, Column.ICON, collection_icon_default);

            foreach(CollectionNode n in node.get_children())
                append_node(n, iter);
        }

        // Moves node src into dest, keeping the heirarchy of src intact.
        public bool move_node(CollectionNode src, CollectionNode dest)
        {
            if(src.data == root_collection || !node_map.has_key(src.data.id) || !node_map.has_key(dest.data.id))
                return false;

            FeedCollection c;
            if(dest.data is Feed)
                c = dest.data.parent;
            else
                c = dest.data as FeedCollection;

            if(src.data == c)
                return false;

            src.data.parent = c;

            reparent(get_iter_from_node(src), get_iter_from_data(c));

            parent_changed(src.data, c.id);

            return true;
        }

        // Returns the FeedDataEntry corresponding to the given TreePath.
        public FeedDataEntry? get_data_from_path(TreePath path)
        {
            CollectionNode node = get_node_from_path(path);
            if(node != null)
                return node.data;

            return null;
        }

        // Returns the FeedDataEntry corresponding to the given TreeIter.
        public FeedDataEntry? get_data_from_iter(TreeIter iter)
        {
            CollectionNode node = get_node_from_iter(iter);
            if(node != null)
                return node.data;

            return null;
        }

        // Returns the FeedDataEntry corresponding to the given id.
        public FeedDataEntry? get_data_from_id(int id)
        {
            CollectionNode node = get_node_from_id(id);
            if(node != null)
                return node.data;

            return null;
        }

        // Returns the CollectionNode corresponding to the given TreePath.
        public CollectionNode? get_node_from_path(TreePath path)
        {
            TreeIter iter;
            get_iter(out iter, path);

            return get_node_from_iter(iter);
        }

        // Returns the CollectionNode corresponding to the given TreeIter.
        public CollectionNode? get_node_from_iter(TreeIter iter)
        {
            int id;
            get(iter, Column.ID, out id);

            return get_node_from_id(id);
        }

        // Returns the CollectionNode corresponding to the given id.
        public CollectionNode? get_node_from_id(int id)
        {
            return node_map[id];
        }

        // Removes the given CollectionNode from the store.
        public void remove_node(CollectionNode n)
        {
            TreeIter? iter = get_iter_from_node(n);
            // TODO: REMOVE COLLECTION CHILDREN TOO
            if(iter != null) {
                remove(ref iter);
                node_map.unset(n.id);
            }
        }

        // Removes the given FeedDataEntry from the store.
        public void remove_data(FeedDataEntry d)
        {
            TreeIter? iter = get_iter_from_data(d);
            if(iter != null) {
                if(d is FeedCollection) {
                    foreach(CollectionNode node in (d as FeedCollection).nodes) {
                        move_node(node, get_node_from_id(d.parent_id));
                    }
                }

                remove(ref iter);
                node_map.unset(d.id);
            }
        }

        // Performs a depth-first search for the tree node representing n,
        // starting from from.
        public TreeIter? get_iter_from_node(CollectionNode n, TreeIter? from = null)
        {
            TreeIter? it = base_iter;
            if(from != null && !iter_children(out it, from))
                return null;

            do {
                CollectionNode n2;
                get(it, Column.NODE, out n2, -1);
                if(n2 == n)
                    return it;

                if(iter_has_child(it)) {
                    TreeIter? it2 = get_iter_from_node(n, it);
                    if(it2 != null)
                        return it2;
                }
            } while(iter_next(ref it));

            return null;
        }

        // Performs a depth-first search for the tree node representing d,
        // starting from from.
        public TreeIter? get_iter_from_data(FeedDataEntry d, TreeIter? from = null)
        {
            TreeIter? it = base_iter;
            if(from != null)
                if(!iter_children(out it, from))
                    return null;
            do {
                CollectionNode n2;
                get(it, Column.NODE, out n2, -1);
                if(n2 != null && n2.data == d) {
                    return it;
                }

                if(iter_has_child(it)) {
                    TreeIter? it2 = get_iter_from_data(d, it);
                    if(it2 != null) {
                        return it2;
                    }
                }
            } while(iter_next(ref it));
            return null;
        }

        // Updates the unread count for a given node
        // TODO: This should
        //          a) Get the new count from the node itself
        //          b) Not be explicit, but instead be called by a signal
        public void set_unread_count(int count, int id, bool relative = false)
        {
            int orig_count = 0;
            TreeIter? iter = base_iter;

            CollectionNode n = get_node_from_id(id);
            if(n == null)
                return;

            iter = get_iter_from_node(n);

            if(iter == null)
                return;

            get(iter, Column.UNREAD, out orig_count, -1);
            if(relative)
                set(iter, Column.UNREAD, orig_count + count, -1);
            else
                set(iter, Column.UNREAD, count, -1);

            int new_count = 0;
            get(iter, Column.UNREAD, out new_count, -1);

            if(n.data != root_collection && new_count != orig_count) {
                set_unread_count(new_count - orig_count, n.data.parent_id, true);
            }
        }

        // Updates the given node's state to be failed
        // TODO: This should be replaced by a better system for tracking sucess/failure
        public void set_failed(int id)
        {
            TreeIter? iter = base_iter;
            if(id != -1) {
                CollectionNode n = get_node_from_id(id);
                if(n == null)
                    return;
                iter = get_iter_from_node(n);
                if(iter == null)
                    return;
            }

            set(iter, Column.WEIGHT, 800, -1);
        }

        private TreeIter base_iter;
        private Gee.HashMap<int, CollectionNode> node_map = new Gee.HashMap<int, CollectionNode>();
        private FeedCollection root_collection = new FeedCollection(FEED_CATEGORY_STRING);

        private Gdk.Pixbuf feed_icon_default;
        private Gdk.Pixbuf collection_icon_default;

        // A recursive subtree copy, used in move_node
        private void reparent(TreeIter src, TreeIter dest)
        {
            TreeIter iter;
            append(out iter, dest);
            int id;
            string title;
            int weight;
            Gdk.Pixbuf icon;
            CollectionNode node;
            int unread;
            get(src, Column.ID, out id, Column.TITLE, out title, Column.NODE, out node, Column.ICON, out icon, Column.WEIGHT, out weight, Column.UNREAD, out unread, -1);
            set(iter, Column.ID, id, Column.TITLE, title, Column.NODE, node, Column.ICON, icon, Column.WEIGHT, weight, Column.UNREAD, unread);

            TreeIter i;
            bool valid = iter_children(out i, src);
            while(valid) {
                reparent(i, iter);
                valid = iter_next(ref i);
            }

            remove(ref src);
        }
    }
}
