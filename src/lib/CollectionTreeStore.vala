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

public class CollectionTreeStore : TreeStore
{
    public const string FEED_CATEGORY_STRING = "All Feeds";
    public enum Column
    {
        ID = 0,
        TYPE,
        TITLE,
        ICON,
        NODE,
        UNREAD,
        COUNT
    }

    public CollectionTreeStore()
    {
        prepare();
    }

    public CollectionTreeStore.from_collection(FeedCollection fc)
    {
        prepare();
        append_root_collection(fc);
    }

    public void append_root_collection(FeedCollection fc)
    {
        foreach(CollectionNode n in fc.nodes) {
            append_node(n, base_iter);
        }
    }

    public void append_node(CollectionNode node, TreeIter? parent)
    {
        if(node_map.has_key(node.id))
            return;
        if(parent == null)
            parent = base_iter;

        node_map.set(node.id, node);

        TreeIter iter;
        append(out iter, parent);
        string title = "";
        if(node.contents == CollectionNode.Contents.FEED)
            title = node.feed.title;
        else if(node.contents == CollectionNode.Contents.COLLECTION)
            title = node.collection.title;
        set(iter, Column.ID, node.id, Column.TYPE, node.contents, Column.TITLE, title, Column.NODE, node);
        if(node.contents == CollectionNode.Contents.COLLECTION) {
            foreach(CollectionNode n in node.collection.nodes)
                append_node(n, iter);
        } else {
            set(iter, Column.ICON, node.feed.icon);
        }
    }

    public Feed? get_feed_from_path(TreePath path)
    {
        TreeIter iter;
        get_iter(out iter, path);

        return get_feed_from_iter(iter);
    }

    public Feed? get_feed_from_iter(TreeIter iter)
    {
        int id;
        int type;

        get(iter, Column.ID, out id, Column.TYPE, out type);
        if(type != CollectionNode.Contents.FEED)
            return null;

        return get_feed_from_id(id);
    }

    public Feed? get_feed_from_id(int id)
    {
        if(node_map.has_key(id))
            return node_map.get(id).feed;
        return null;
    }

    public FeedCollection? get_collection_from_path(TreePath path)
    {
        int id;
        int type;
        TreeIter iter;

        get_iter(out iter, path);
        get(iter, Column.ID, out id, Column.TYPE, out type);
        if(type != CollectionNode.Contents.COLLECTION)
            return null;

        return get_collection_from_id(id);
    }

    public FeedCollection? get_collection_from_iter(TreeIter iter)
    {
        int id;
        int type;

        get(iter, Column.ID, out id, Column.TYPE, out type);
        if(type != CollectionNode.Contents.COLLECTION)
            return null;

        return get_collection_from_id(id);
    }

    public FeedCollection? get_collection_from_id(int id)
    {
        if(node_map.has_key(id))
            return node_map.get(id).collection;
        return null;
    }

    public CollectionNode? get_node_from_path(TreePath path)
    {
        int id;
        TreeIter iter;

        get_iter(out iter, path);
        get(iter, Column.ID, out id);

        return get_node_from_id(id);
    }

    public CollectionNode? get_node_from_iter(TreeIter iter)
    {
        int id;

        get(iter, Column.ID, out id);

        return get_node_from_id(id);
    }

    public CollectionNode? get_node_from_id(int id)
    {
        if(node_map.has_key(id))
            return node_map.get(id);
        return null;
    }

    public void remove_node(CollectionNode n)
    {
        TreeIter? iter = get_iter_from_node(n);
        if(iter != null) {
            remove(ref iter);
            node_map.unset(n.id);
        }
    }

    public void remove_feed(Feed f)
    {
        TreeIter? iter = get_iter_from_feed(f);
        if(iter != null) {
            remove(ref iter);
            node_map.unset(f.id);
        }
    }

    public void remove_collection(FeedCollection c)
    {
        TreeIter? iter = get_iter_from_collection(c);
        if(iter != null) {
            remove(ref iter);
            node_map.unset(c.id);
        }
    }

    public TreeIter? get_iter_from_node(CollectionNode n, TreeIter? from = null)
    {
        TreeIter? it = base_iter;
        if(from != null)
            if(!iter_children(out it, from))
                return null;
        do {
            CollectionNode n2;
            get(it, Column.NODE, out n2, -1);
            if(n2 == n) {
                return it;
            }

            if(iter_has_child(it)) {
                TreeIter? it2 = get_iter_from_node(n, it);
                if(it2 != null) {
                    return it2;
                }
            }
        } while(iter_next(ref it));
        return null;
    }

    public TreeIter? get_iter_from_feed(Feed f, TreeIter? from = null)
    {
        TreeIter? it = base_iter;
        if(from != null)
            if(!iter_children(out it, from))
                return null;
        do {
            CollectionNode n2;
            get(it, Column.NODE, out n2, -1);
            if(n2 != null && n2.feed == f) {
                return it;
            }

            if(iter_has_child(it)) {
                TreeIter? it2 = get_iter_from_feed(f, it);
                if(it2 != null) {
                    return it2;
                }
            }
        } while(iter_next(ref it));
        return null;
    }

    public TreeIter? get_iter_from_collection(FeedCollection c, TreeIter? from = null)
    {
        TreeIter? it = base_iter;
        if(from != null)
            if(!iter_children(out it, from))
                return null;
        do {
            CollectionNode n2;
            get(it, Column.NODE, out n2, -1);
            if(n2 != null && n2.collection == c) {
                return it;
            }

            if(iter_has_child(it)) {
                TreeIter? it2 = get_iter_from_collection(c, it);
                if(it2 != null) {
                    return it2;
                }
            }
        } while(iter_next(ref it));
        return null;
    }

    public void set_unread_count(int count, int id = -1, bool relative = false)
    {
        int orig_count = 0;
        TreeIter? iter = base_iter;
        if(count != 0)
            stderr.printf("Unread: %d, %d\n", id, count);
        if(id != -1) {
            CollectionNode n = get_node_from_id(id);
            if(n == null)
                return;
            iter = get_iter_from_node(n);
            if(iter == null)
                return;
        }
        if(relative) {
            get(iter, Column.UNREAD, out orig_count, -1);
        }

        set(iter, Column.UNREAD, orig_count + count, -1);
    }

    private TreeIter base_iter;
    private Gee.HashMap<int, CollectionNode> node_map;

    private void prepare()
    {
        node_map = new Gee.HashMap<int, CollectionNode>();
        set_column_types({typeof(int), typeof(int), typeof(string), typeof(Gdk.Pixbuf), typeof(CollectionNode), typeof(int)});
        set_sort_column_id(Column.TITLE, SortType.ASCENDING);
        append(out base_iter, null);
        set(base_iter, Column.ID, -1, Column.TYPE, CollectionNode.Contents.COLLECTION, Column.TITLE, FEED_CATEGORY_STRING, Column.UNREAD, 0);
    }
}

}
