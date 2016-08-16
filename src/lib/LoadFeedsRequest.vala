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
                q = new Query(db, "SELECT feeds.*, icons.*, sum(items.unread) AS unread_count FROM feeds LEFT OUTER JOIN icons ON feeds.id = icons.id LEFT OUTER JOIN items ON items.parent_id = feeds.id GROUP BY feeds.id ORDER BY feeds.id");
            } catch(SQLHeavy.Error e) {
                error("failed to load feeds: %s", e.message);
            }

            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            try {
                for(; !res.finished; res.next()) {
                    switch(res.get_int("type")) {
                        case CollectionNode.Contents.FEED:
                            Feed f = new Feed.from_record(res);
                            CollectionNode n = new CollectionNode.with_feed(f);
                            m_node_map[f.id] = n;
                            count_map[f.id] = res.get_int("unread_count");
                            m_node_list.add(n);
                        break;
                        case CollectionNode.Contents.COLLECTION:
                            FeedCollection c = new FeedCollection.from_record(res);
                            CollectionNode n = new CollectionNode.with_collection(c);
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

            foreach(CollectionNode n in m_node_list)
            {
                if(n.contents == CollectionNode.Contents.FEED) {
                    if(n.feed.parent_id == -1)
                        feeds.add_node(n);
                    else
                        m_node_map[n.feed.parent_id].collection.add_node(n);
                } else if(n.contents == CollectionNode.Contents.COLLECTION) {
                    if(n.collection.parent_id == -1)
                        feeds.add_node(n);
                    else
                        m_node_map[n.collection.parent_id].collection.add_node(n);
                }
            }

            return RequestStatus.DEFAULT;
        }

        private Gee.HashMap<int, CollectionNode> m_node_map;
        private Gee.List<CollectionNode> m_node_list;
    }
}
