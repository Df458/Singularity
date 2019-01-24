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
    // DatabaseRequest for toggling an item's unread/starred status
    public class ItemToggleRequest : DatabaseRequest, GLib.Object {
        public enum ToggleField {
            UNREAD = 0,
            STARRED
        }

        public string guid { get; construct; }
        public ToggleField field { get; construct; }

        public ItemToggleRequest (string i, ToggleField f) {
            Object (guid: i, field: f);
        }

        public Query build_query (Database db) {
            try {
                return new Query (db, "UPDATE items SET %s = 1 - %s WHERE guid = %s".printf (
                    field_names[field],
                    field_names[field],
                    sql_str (guid)));
            } catch (SQLHeavy.Error e) {
                error ("Failed to toggle %s: %s", field_names[field], e.message);
            }
        }

        public RequestStatus process_result (QueryResult res) {
            return RequestStatus.DEFAULT;
        }

        private const string[] field_names = { "unread", "starred" };
    }
}
