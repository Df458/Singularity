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
    public class UnsubscribeRequest : DatabaseRequest, GLib.Object
    {
        public Feed feed { get; construct; }
        public UnsubscribeRequest(Feed f)
        {
            Object(feed: f);
        }

        public Query build_query(Database db)
        {
            if(items_removed) {
                StringBuilder q_builder = new StringBuilder("DELETE FROM feeds");
                q_builder.append_printf(" WHERE id = %d;", feed.id);

                Query q;
                try {
                    q = new Query(db, q_builder.str);
                } catch(SQLHeavy.Error e) {
                    error("Failed to unsubscribe: %s", e.message);
                }
                return q;
            }

            Query q;
            try {
                q = new Query(db, "DELETE FROM items WHERE parent_id = %d");
            } catch(SQLHeavy.Error e) {
                error("Failed to unsubscribe: %s", e.message);
            }
            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            if(items_removed)
                return RequestStatus.DEFAULT;
            items_removed = true;
            return RequestStatus.CONTINUE;
        }

        private bool items_removed = false;
    }
}
