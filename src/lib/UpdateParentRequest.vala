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
    public class UpdateParentRequest : DatabaseRequest, GLib.Object
    {
        public FeedDataEntry entry { get; construct; }
        public int parent_id { get; construct; }

        public UpdateParentRequest(FeedDataEntry e, int p)
        {
            Object(entry: e, parent_id: p);
        }

        public Query build_query(Database db)
        {
            StringBuilder q_builder = new StringBuilder("UPDATE feeds SET 'parent_id' = ");
            q_builder.append_printf("%d WHERE id = %d", parent_id, entry.id);

            Query q;
            try {
                q = new Query(db, q_builder.str);
            } catch(SQLHeavy.Error e) {
                error("Failed to reparent node: %s [%s]", e.message, q_builder.str);
            }
            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            return RequestStatus.DEFAULT;
        }
    }
}
