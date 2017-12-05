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
using SQLHeavy;

namespace Singularity
{
    // A DatabaseRequest for creating new FeedCollections
    public class CollectionRequest : DatabaseRequest, GLib.Object
    {
        public CollectionNode node { get; construct; }
        public int parent_id { get; construct; }

        public CollectionRequest(CollectionNode n, int p)
            requires(n.data is FeedCollection)
        {
            Object(node: n, parent_id: p);
        }

        public Query build_query(Database db)
        {
            if(insert_done) {
                try {
                    return new Query(db, "SELECT MAX(id) FROM feeds");
                } catch(SQLHeavy.Error e) {
                    error("Failed to check ids: %s", e.message);
                }
            }

            StringBuilder q_builder = new StringBuilder("INSERT OR IGNORE INTO feeds (parent_id, type, title, link) VALUES");
            q_builder.append_printf("(%d, %d, %s, null)", parent_id, (int)CollectionNode.Contents.COLLECTION, sql_str(node.data.title));

            try {
                /* warning(q_builder.str); */
                return new Query(db, q_builder.str);
            } catch(SQLHeavy.Error e) {
                error("Failed to create collection: %s", e.message);
            }
        }

        public RequestStatus process_result(QueryResult res)
        {
            if(insert_done) {
                try {
                    (node.data as FeedCollection).prepare_for_db(res.fetch_int(0));
                } catch(SQLHeavy.Error e) {
                    error("Failed to get ids: %s", e.message);
                }
            } else {
                insert_done = true;
                return RequestStatus.CONTINUE;
            }
            return RequestStatus.DEFAULT;
        }

        private bool insert_done = false;
    }
}
