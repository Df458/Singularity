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
    public class LoadFeedsRequest : DatabaseRequest, GLib.Object
    {
        public FeedCollection feeds { get; private set; }
        public int unread_count { get; private set; }
        public Gee.HashMap<int, int> count_map { get; private set; }

        public LoadFeedsRequest()
        {
            feeds = new FeedCollection.root();
            m_node_map = new Gee.HashMap<int, CollectionNode>();
            count_map = new Gee.HashMap<int, int>();
            m_node_list = new Gee.ArrayList<CollectionNode>();
            unread_count = 0;
        }

        public Query build_query(Database db)
        {
            Query q;
            try {
                if(current_id == -1) {
                    q = new Query(db, "SELECT feeds.*, icons.*, sum(items.unread) AS unread_count FROM feeds LEFT OUTER JOIN icons ON feeds.id = icons.id LEFT OUTER JOIN items ON items.parent_id = feeds.id GROUP BY feeds.id ORDER BY feeds.id");
                } else {
                    if(item_step)
                        q = new Query(db, "SELECT * FROM items WHERE parent_id = %d".printf(m_node_list[current_id].id));
                    else
                        q = new Query(db, "SELECT * FROM enclosures WHERE feed_id = %d".printf(m_node_list[current_id].id));
                }
            } catch(SQLHeavy.Error e) {
                    error("failed to load feeds: %s", e.message);
                }

            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            if(current_id == -1) {
                try {
                    for(; !res.finished; res.next()) {
                        switch(res.get_int("type")) {
                            case CollectionNode.Contents.FEED:
                                Feed f = new Feed.from_record(res);
                                CollectionNode n = new CollectionNode(f);
                                m_node_map[f.id] = n;
                                count_map[f.id] = res.get_int("unread_count");
                                m_node_list.add(n);
                            break;
                            case CollectionNode.Contents.COLLECTION:
                                FeedCollection c = new FeedCollection.from_record(res);
                                CollectionNode n = new CollectionNode(c);
                                m_node_map[c.id] = n;
                                count_map[c.id] = res.get_int("unread_count");
                                m_node_list.add(n);
                            break;
                        }
                        unread_count += res.get_int("unread_count");
                    }
                } catch(SQLHeavy.Error e) {
                    error("Failed to build feed structure: %s", e.message);
                }

                foreach(CollectionNode n in m_node_list) {
                    if(n.data.parent_id == -1) {
                        feeds.add_node(n);
                    }
                    else
                        (m_node_map[n.data.parent_id].data as FeedCollection).add_node(n);
                }
            } else {
                if(item_step) {
                    item_step = false;
                    try {
                        for(; !res.finished; res.next()) {
                            Item i = new Item.from_record(res);
                            (m_node_list[current_id].data as Feed).add_item(i);
                        }
                    } catch(SQLHeavy.Error e) {
                        error("Failed to build feed structure: %s", e.message);
                    }

                    return RequestStatus.CONTINUE;
                } else {
                    item_step = true;
                    try {
                        for(; !res.finished; res.next()) {
                            Attachment a = new Attachment.from_record(res);
                            string guid = res.fetch_string(res.field_index("item_guid"));
                            (m_node_list[current_id].data as Feed).get_item(guid).attachments.add(a);
                        }
                    } catch(SQLHeavy.Error e) {
                        error("Failed to build feed structure: %s", e.message);
                    }
                }
            }

            while(current_id + 1 < m_node_list.size) {
                current_id++;
                if(m_node_list[current_id].data is Feed)
                    return RequestStatus.CONTINUE;
            }

            return RequestStatus.DEFAULT;
        }

        private Gee.HashMap<int, CollectionNode> m_node_map;
        private Gee.List<CollectionNode> m_node_list;
        private int current_id = -1;
        private bool item_step = true;
    }
}
