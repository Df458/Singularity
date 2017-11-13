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
    public class SubscribeRequest : DatabaseRequest, GLib.Object
    {
        public CollectionNode node { get; construct; }

        public SubscribeRequest(CollectionNode n)
        {
            Object(node: n);

            m_node_list = new Gee.ArrayList<CollectionNode>();
            m_node_map = new Gee.HashMap<FeedCollection, int>();
            prepare_node_list(n);
        }

        public Query build_query(Database db)
        {
            if(insert_done) {
                Query q;
                try {
                    q = new Query(db, "SELECT MAX(id) FROM feeds");
                } catch(SQLHeavy.Error e) {
                    error("Failed to check ids: %s", e.message);
                }
                return q;
            }

            StringBuilder q_builder = new StringBuilder("INSERT OR IGNORE INTO feeds (parent_id, type, title, link, site_link, description, rights, generator, last_update) VALUES");
            if(m_node_list.size > 0) {
                insert_node(q_builder, m_node_list[0], true);
                for(int i = 1; i < m_node_list.size; i++)
                    insert_node(q_builder, m_node_list[i], false);
            }

            Query q;
            try {
                q = new Query(db, q_builder.str);
            } catch(SQLHeavy.Error e) {
                error("Failed to subscribe: %s", e.message);
            }
            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            if(insert_done) {
                try {
                    next_id = res.fetch_int(0);
                    prepare_node_map(node);
                } catch(SQLHeavy.Error e) {
                    error("Failed to get ids: %s", e.message);
                }
            } else {
                insert_done = true;
                return RequestStatus.CONTINUE;
            }
            return RequestStatus.DEFAULT;
        }

        private Gee.ArrayList<CollectionNode> m_node_list;
        private Gee.HashMap<FeedCollection, int> m_node_map;
        private int next_id;
        private bool insert_done = false;

        private void prepare_node_list(CollectionNode n)
        {
            m_node_list.add(n);
            if(n.data is FeedCollection) {
                foreach(CollectionNode n2 in (n.data as FeedCollection).nodes) {
                    prepare_node_list(n2);
                }
            }
        }

        private void prepare_node_map(CollectionNode n)
        {
            if(n.data is FeedCollection) {
                FeedCollection c = n.data as FeedCollection;
                m_node_map.set(c, next_id);
                c.prepare_for_db(next_id);
                next_id++;
                foreach(CollectionNode n2 in c.nodes) {
                    prepare_node_map(n2);
                }
            } else {
                (n.data as Feed).prepare_for_db(next_id);
                next_id++;
            }
        }

        private void insert_node(StringBuilder q_builder, CollectionNode n, bool first)
        {
            int p_id = -1;
            if(!first)
                q_builder.append(",");
            if(n.data.parent != null) {
                if(m_node_map.has_key(n.data.parent))
                     p_id = m_node_map[n.data.parent];
                else
                     p_id = n.data.parent_id;
            }
            if(n.data is Feed) {
                Feed f = n.data as Feed;
                q_builder.append_printf(" (%d, %d, %s, %s, %s, %s, %s, %s, %lld)", p_id, (int)CollectionNode.Contents.FEED, sql_str(f.title), sql_str(f.link), sql_str(f.site_link), sql_str(f.description), sql_str(f.rights), sql_str(f.generator), f.last_update.to_unix());
            } else {
                FeedCollection c = n.data as FeedCollection;
                q_builder.append_printf(" (%d, %d, %s, null, null, null, null, null, null)", p_id, (int)CollectionNode.Contents.COLLECTION, sql_str(c.title));
            }
        }
    }
}
