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
    // DatabaseRequest for deleting collections
    public class DeleteCollectionRequest : DatabaseRequest, GLib.Object
    {
        public FeedCollection collection { get; construct; }

        public DeleteCollectionRequest(FeedCollection c)
        {
            Object(collection: c);
        }

        public Query build_query(Database db)
        {
            if(feeds_moved) {
                try {
                    return new Query(db, "UPDATE feeds SET parent_id = %d WHERE parent_id = %d".printf(collection.parent_id, collection.id));
                } catch(SQLHeavy.Error e) {
                    error("Failed to relink feeds: %s", e.message);
                }
            } else {
                try {
                    return new Query(db, "DELETE FROM feeds WHERE id = %d".printf(collection.id));
                } catch(SQLHeavy.Error e) {
                    error("Failed to delete collection: %s", e.message);
                }
            }
        }

        public RequestStatus process_result(QueryResult res)
        {
            if(feeds_moved)
                return RequestStatus.DEFAULT;
            feeds_moved = true;
            return RequestStatus.CONTINUE;
        }

        private bool feeds_moved = false;
    }
}
