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
using DFLib;
using SQLHeavy;

namespace Singularity {
    // Represents an attached file on an item (sometimes refered to as an enclosure)
    public class Attachment : DataEntryGuid {
        public string name { get; set; }
        public string url { get; set; }
        public int size { get; set; }
        public string mimetype { get; set; }

        public Attachment.from_record (SQLHeavy.Record r) throws SQLHeavy.Error {
            base.from_record (r);
        }

        // Prepares and hashes this object's guid
        public void prepare_for_db (Item owner) {
            set_guid (md5_guid (owner.guid+url));
        }

        /** Populate data from a database record
         * @param r The record to read
         */
        protected override void build_from_record (Record r) throws SQLHeavy.Error {
            set_guid (r.get_string ("guid"));
            name = r.get_string ("name");
            url = r.get_string ("uri");
            size = r.get_int ("length");
            mimetype = r.get_string ("mimetype");
        }
    }
}
