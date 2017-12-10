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
    // A DatabaseRequest for unsubscribing from a feed
    public class UnsubscribeRequest : DatabaseRequest, GLib.Object
    {
        public Feed feed { get; construct; }
        public UnsubscribeRequest(Feed f)
        {
            Object(feed: f);
        }

        public Query build_query(Database db)
        {
            try {
                if(icon_removed)
                    return new Query(db, "DELETE FROM feeds WHERE id = %d".printf(feed.id));
                else if(items_removed)
                    return new Query(db, "DELETE FROM icons WHERE id = %d".printf(feed.id));
                else
                    return new Query(db, "DELETE FROM items WHERE parent_id = %d".printf(feed.id));
            } catch(SQLHeavy.Error e) {
                error("Failed to unsubscribe: %s", e.message);
            }
        }

        public RequestStatus process_result(QueryResult res)
        {
            if(icon_removed)
                return RequestStatus.DEFAULT;
            else if(items_removed)
                icon_removed = true;
            items_removed = true;
            return RequestStatus.CONTINUE;
        }

        private bool items_removed = false;
        private bool icon_removed = false;
    }
}
