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
            if(id_prepared) {
                StringBuilder q_builder = new StringBuilder("INSERT OR IGNORE INTO feeds (id, parent_id, type, title, link, site_link, description, rights, generator, last_update) VALUES");
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

            Query q;
            try {
                q = new Query(db, "SELECT * FROM SQLITE_SEQUENCE WHERE name = 'feeds'");
            } catch(SQLHeavy.Error e) {
                error("Failed to check ids: %s", e.message);
            }
            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            if(!id_prepared) {
                try {
                    id_prepared = true;
                    next_id = res.fetch_int(res.field_index("seq")) + 1;
                    prepare_node_map(node);
                    return RequestStatus.CONTINUE;
                } catch(SQLHeavy.Error e) {
                    error("Failed to get ids: %s", e.message);
                }
            }
            return RequestStatus.DEFAULT;
        }

        private Gee.ArrayList<CollectionNode> m_node_list;
        private Gee.HashMap<FeedCollection, int> m_node_map;
        private int next_id;
        private bool id_prepared = false;

        private void prepare_node_list(CollectionNode n)
        {
            m_node_list.add(n);
            if(n.contents == CollectionNode.Contents.COLLECTION) {
                foreach(CollectionNode n2 in n.collection.nodes) {
                    prepare_node_list(n2);
                }
            }
        }

        private void prepare_node_map(CollectionNode n)
        {
            if(n.contents == CollectionNode.Contents.COLLECTION) {
                m_node_map.set(n.collection, next_id);
                n.collection.prepare_for_db(next_id);
                next_id++;
                foreach(CollectionNode n2 in n.collection.nodes) {
                    prepare_node_map(n2);
                }
            } else if(n.contents == CollectionNode.Contents.FEED) {
                n.feed.prepare_for_db(next_id);
                next_id++;
            }
        }

        private void insert_node(StringBuilder q_builder, CollectionNode n, bool first)
        {
            int p_id = -1;
            if(!first)
                q_builder.append(",");
            if(n.get_parent() != null) {
                if(m_node_map.has_key(n.get_parent()))
                     p_id = m_node_map[n.get_parent()];
                else
                     p_id = n.get_parent().id;
            }
            if(n.contents == CollectionNode.Contents.FEED) {
                Feed f = n.feed;
                q_builder.append_printf(" (%d, %d, %d, %s, %s, %s, %s, %s, %s, %lld)", f.id, p_id, (int)CollectionNode.Contents.FEED, sql_str(f.title), sql_str(f.link), sql_str(f.site_link), sql_str(f.description), sql_str(f.rights), sql_str(f.generator), f.last_update.to_unix());
            } else if(n.contents == CollectionNode.Contents.COLLECTION) {
                FeedCollection c = n.collection;
                q_builder.append_printf(" (%d, %d, %d, %s, null, null, null, null, null, null)", c.id, p_id, (int)CollectionNode.Contents.COLLECTION, sql_str(c.title));
            }
        }
    }
}
