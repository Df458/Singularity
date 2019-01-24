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

namespace Singularity {
    // A DatabaseRequest for renaming FeedCollections
    public class RenameRequest : DatabaseRequest, GLib.Object {
        public CollectionNode node { get; construct; }
        public string title { get; construct; }

        public RenameRequest (CollectionNode n, string t) {
            Object (node: n, title: t);
        }

        public Query build_query (Database db) {
            string q = "UPDATE feeds SET 'title' = %s WHERE id = %d".printf (sql_str (title), node.data.id);
            try {
                return new Query (db, q);
            } catch (SQLHeavy.Error e) {
                error ("Failed to rename node: %s [%s]", e.message, q);
            }
        }

        public RequestStatus process_result (QueryResult res) {
            return RequestStatus.DEFAULT;
        }
    }
}
