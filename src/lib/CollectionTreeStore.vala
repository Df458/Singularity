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

// TODO: Figure out how to extract icons
public class CollectionTreeStore : TreeStore
{
    public static const string FEED_CATEGORY_STRING = "All Feeds";
    public enum Column
    {
        ID = 0,
        TYPE,
        TITLE,
        ICON,
        NODE,
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
        set(iter, Column.ID, node.id, Column.TYPE, node.contents, Column.TITLE, title);
        if(node.contents == CollectionNode.Contents.COLLECTION) {
            foreach(CollectionNode n in node.collection.nodes)
                append_node(n, iter);
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

    private TreeIter base_iter;
    private Gee.HashMap<int, CollectionNode> node_map;

    private void prepare()
    {
        node_map = new Gee.HashMap<int, CollectionNode>();
        set_column_types({typeof(int), typeof(int), typeof(string), typeof(Gdk.Pixbuf), typeof(CollectionNode)});
        set_sort_column_id(Column.TITLE, SortType.ASCENDING);
        append(out base_iter, null);
        set(base_iter, Column.ID, -1, Column.TYPE, CollectionNode.Contents.COLLECTION, Column.TITLE, FEED_CATEGORY_STRING);
    }
}

}
