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
    public class ItemToggleRequest : DatabaseRequest, GLib.Object
    {
        public enum ToggleField
        {
            UNREAD = 0,
            STARRED
        }
        public const string[] field_names = { "unread", "starred" };
        public int id { get; construct; }
        public ToggleField field { get; construct; }

        public ItemToggleRequest(int i, ToggleField f)
        {
            Object(id: i, field: f);
        }

        public Query build_query(Database db)
        {
            StringBuilder q_builder = new StringBuilder("UPDATE items");
            q_builder.append_printf(" SET %s = 1 - %s WHERE id = %d", field_names[field], field_names[field], id);

            Query q;
            try {
                q = new Query(db, q_builder.str);
                stderr.printf("Q:%s\n", q.sql);
            } catch(SQLHeavy.Error e) {
                error("Failed to toggle %s: %s", field_names[field], e.message);
            }
            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            return RequestStatus.DEFAULT;
        }
    }
}
