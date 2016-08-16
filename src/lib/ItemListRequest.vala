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
using SQLHeavy;

namespace Singularity
{
    public class ItemListRequest : DatabaseRequest, GLib.Object
    {
        public enum Filter
        {
            EVERYTHING = 0,
            UNREAD_ONLY,
            STARRED_ONLY,
            UNREAD_AND_STARRED,
            COUNT,
            DEFAULT = EVERYTHING
        }

        public enum SortType
        {
            NOTHING = 0,
            UNREAD,
            STARRED,
            POST_DATE,
            TITLE,
            FEED,
            COUNT,
        }

        public Filter   item_filter              = Filter.DEFAULT;
        public SortType primary_sort             = SortType.FEED;
        public bool     primary_sort_ascending   = true;
        public SortType secondary_sort           = SortType.POST_DATE;
        public bool     secondary_sort_ascending = true;

        public int      max_items                = -1;
        public int      item_offset              = 0;
        public CollectionNode? filter_node { get; construct; }
        public Gee.List<Item>? item_list { get; private set; }
        public Gee.HashMap<Item, int> item_id_map { get; private set; }

        public ItemListRequest(CollectionNode? node)
        {
            Object(filter_node: node);
            build_id_list(filter_node);
            item_id_map = new Gee.HashMap<Item, int>();
        }

        public Query build_query(Database db)
        {
            StringBuilder q_builder = new StringBuilder("SELECT items.*");
            bool needs_feed_data = primary_sort == SortType.FEED || secondary_sort == SortType.FEED;
            if(needs_feed_data)
                q_builder.append(", feeds.title");
            q_builder.append(" FROM items");
            if(needs_feed_data)
                q_builder.append(" LEFT OUTER JOIN feeds ON items.parent_id = feeds.id");

            if(item_filter != Filter.DEFAULT) {
                switch(item_filter)
                {
                    case Filter.UNREAD_ONLY:
                        q_builder.append(" WHERE items.unread = 1");
                    break;
                    case Filter.STARRED_ONLY:
                        q_builder.append(" WHERE items.starred = 1");
                    break;
                    case Filter.UNREAD_AND_STARRED:
                        q_builder.append(" WHERE items.unread = 1 OR items.starred = 1");
                    break;
                }
                if(filter_node != null)
                    q_builder.append(" AND");
            }
            if(filter_node != null) {
                if(item_filter == Filter.DEFAULT)
                    q_builder.append(" WHERE");
                q_builder.append_printf(" items.parent_id IN (%d", m_id_list[0]);
                for(int i = 1; i < m_id_list.length; i++)
                    q_builder.append_printf(", %d", m_id_list[i]);
                q_builder.append(")");
            }

            if(primary_sort != SortType.NOTHING) {
                switch(primary_sort)
                {
                    case SortType.UNREAD:
                        q_builder.append(" ORDER BY items.unread");
                    break;
                    case SortType.STARRED:
                        q_builder.append(" ORDER BY items.starred");
                    break;
                    case SortType.POST_DATE:
                        q_builder.append(" ORDER BY items.update_time");
                    break;
                    case SortType.TITLE:
                        q_builder.append(" ORDER BY items.title");
                    break;
                    case SortType.FEED:
                        q_builder.append(" ORDER BY feeds.title");
                    break;
                }

                if(primary_sort_ascending)
                    q_builder.append(" ASC");
                else
                    q_builder.append(" DESC");

                if(secondary_sort != SortType.NOTHING) {
                    switch(secondary_sort)
                    {
                        case SortType.UNREAD:
                            q_builder.append(", items.unread");
                        break;
                        case SortType.STARRED:
                            q_builder.append(", items.starred");
                        break;
                        case SortType.POST_DATE:
                            q_builder.append(", items.update_time");
                        break;
                        case SortType.TITLE:
                            q_builder.append(", items.title");
                        break;
                        case SortType.FEED:
                            q_builder.append(", feeds.title");
                        break;
                    }

                    if(secondary_sort_ascending)
                        q_builder.append(" ASC");
                    else
                        q_builder.append(" DESC");
                }
            }

            if(max_items > 0) {
                q_builder.append_printf(" LIMIT %d OFFSET %d", max_items, item_offset);
            }

            Query query;
            try {
                query = new Query(db, q_builder.str);
            } catch(SQLHeavy.Error e) {
                error("Can't request item list: %s", e.message);
            }

            return query;
        }

        public RequestStatus process_result(QueryResult res)
        {
            item_list = new Gee.ArrayList<Item>();
            try {
                for(; !res.finished; res.next() ) {
                    Item i = new Item.from_record(res);
                    item_list.add(i);
                    item_id_map[i] = res.get_int("parent_id");
                }
            } catch(SQLHeavy.Error e) {
                error("Failed to construct item list: %s", e.message);
            }

            return RequestStatus.COMPLETED;
        }

        private int[] m_id_list;

        private void build_id_list(CollectionNode? node)
        {
            if(node == null)
                return;

            if(node.contents == CollectionNode.Contents.FEED)
                m_id_list += node.id;
            else if(node.contents == CollectionNode.Contents.COLLECTION)
                foreach(CollectionNode i in node.collection.nodes)
                    build_id_list(i);
        }
        
        // TODO: Remove this when done
        // SELECT items.*, feeds.title FROM items LEFT OUTER JOIN `feeds` ON items.parent_id = feeds.id WHERE items.parent_id IN (3, 4) ORDER BY `update_time` DESC LIMIT 10 OFFSET 5
    }
}
