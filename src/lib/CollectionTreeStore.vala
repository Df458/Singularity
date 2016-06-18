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

    public CollectionTreeStore.from_collection(FeedCollection fc)
    {
        set_column_types({typeof(int), typeof(int), typeof(string), typeof(Gdk.Pixbuf), typeof(CollectionNode)});
        set_sort_column_id(Column.TITLE, SortType.ASCENDING);
        TreeIter iter;
        append(out iter, null);
        set(iter, Column.ID, -1, Column.TYPE, CollectionNode.Contents.COLLECTION, Column.TITLE, FEED_CATEGORY_STRING);
        foreach(CollectionNode n in fc.nodes) {
            append_node(n, iter);
        }
    }

    public void append_node(CollectionNode node, TreeIter? parent)
    {
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
}

}
