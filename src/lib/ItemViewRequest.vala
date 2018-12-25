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
// DatabaseRequest for marking one or more items as read
public class ItemViewRequest : DatabaseRequest, GLib.Object
{
    public string[] guid { get; private set; }

    public ItemViewRequest(string[] i)
    {
        guid = i;
    }

    public Query build_query(Database db)
    {
        StringBuilder q_builder = new StringBuilder("UPDATE items SET 'unread' = 0 WHERE guid IN (");
        for(int i = 0; i < guid.length; ++i) {
            if(i != 0)
                q_builder.append(", ");
            q_builder.append_printf("%s", sql_str(guid[i]));
        }
        q_builder.append(")");

        try {
            return new Query(db, q_builder.str);
        } catch(SQLHeavy.Error e) {
            error("Failed to view item: %s [%s]", e.message, q_builder.str);
        }
    }

    public RequestStatus process_result(QueryResult res)
    {
        return RequestStatus.DEFAULT;
    }
}
}
