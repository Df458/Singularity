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
    // Represents a single item within a larger feed
    public class Item : DataEntryGuid {
        public enum DBColumn {
            ID = 0,
            FEED_ID,
            GUID,
            TITLE,
            LINK,
            CONTENT,
            AUTHOR,
            RIGHTS,
            PUBLISH_TIME,
            UPDATE_TIME,
            LOAD_TIME,
            UNREAD,
            STARRED,
            COUNT
        }

        public Feed? owner = null;
        public string title = "";
        public string? link = null;
        public string? content = null;
        public string weak_guid = "";
        public Person? author = null;
        public Gee.Collection<Tag?> tags;
        public Gee.Collection<Attachment?> attachments = new Gee.ArrayList<Attachment?> ();
        public Gee.Collection<Person?> contributors;
        public string? rights = null;
        public DateTime time_published = new DateTime.from_unix_utc (0);
        public DateTime time_updated = new DateTime.from_unix_utc (0);
        public DateTime time_loaded = new DateTime.now_utc ();
        public bool unread = true;
        public bool starred = false;

        public Item () { }

        public Item.from_record (SQLHeavy.Record r) {
            base.from_record (r);
        }

        public override Query? insert (Queryable q) {
            try {
                Query query = new Query (q, """INSERT INTO items (
                            parent_id,
                            guid,
                            weak_guid,
                            title,
                            link,
                            content,
                            rights,
                            publish_time,
                            update_time,
                            load_time,
                            unread,
                            starred
                            ) VALUES (
                                :parent_id,
                                :guid,
                                :title,
                                :link,
                                :content,
                                :rights,
                                :publish_time,
                                :update_time,
                                :load_time,
                                :unread,
                                :starred
                                )""");
                query[":parent_id"] = owner.id;
                query[":guid"] = guid;
                query[":weak_guid"] = weak_guid;
                query[":title"] = title;
                query[":link"] = link;
                query[":content"] = content;
                query[":rights"] = rights;
                query[":publish_time"] = time_published.to_unix ();
                query[":update_time"] = time_updated.to_unix ();
                query[":load_time"] = time_loaded.to_unix ();
                query[":unread"] = unread ? 1 : 0;
                query[":starred"] = starred ? 1 : 0;
                // TODO: Decide how to store authors
                // TODO: Decide how to store contributors
                // TODO: Decide how to store tags
                return query;
            } catch (SQLHeavy.Error e) {
                warning ("Cannot insert item data: " + e.message);
                return null;
            }
        }
        public override Query? update (Queryable q) {
            try {
                Query query = new Query (q, """UPDATE items SET
                        title = :title,
                        link = :link,
                        content = :content,
                        rights = :rights,
                        publish_time = :publish_time,
                        update_time = :update_time,
                        load_time = :load_time WHERE guid = :guid
                        """);
                query[":guid"] = guid;
                query[":title"] = title;
                query[":link"] = link;
                query[":content"] = content;
                query[":rights"] = rights;
                query[":publish_time"] = time_published.to_unix ();
                query[":update_time"] = time_updated.to_unix ();
                query[":load_time"] = time_loaded.to_unix ();
                // TODO: Decide how to store authors
                // TODO: Decide how to store contributors
                // TODO: Decide how to store tags
                // TODO: Decide how to store attachments
                return query;
            } catch (SQLHeavy.Error e) {
                warning ("Cannot update item data: " + e.message);
                return null;
            }
        }
        public override Query? remove (Queryable q) {
            try {
                Query query = new Query (q, "DELETE FROM items WHERE `guid` = :guid");
                query[":guid"] = guid;
                return query;
            } catch (SQLHeavy.Error e) {
                warning ("Cannot remove item data: " + e.message);
                return null;
            }
        }

        public void prepare_for_db () {
            set_guid (md5_guid (owner.link+weak_guid));
        }

        public string to_string () {
            return "%s: %s [%s]".printf (guid, title, link);
        }

        // Checks to see if two items are the same.
        // TODO: Currently this just compares update times. Should we test all fields?
        public bool equals (Item i2) {
            return time_updated == i2.time_updated;
        }

        /** Populate data from a database record
         * @param r The record to read
         */
        protected override void build_from_record (Record r) throws SQLHeavy.Error {
            weak_guid = r.fetch_string (r.field_index ("weak_guid"));
            title = strip_htm (r.fetch_string (3));
            link = r.fetch_string (r.field_index ("link"));
            content = r.fetch_string (r.field_index ("content"));
            rights = r.fetch_string (r.field_index ("rights"));
            time_published = new DateTime.from_unix_utc (r.fetch_int (r.field_index ("publish_time")));
            time_updated = new DateTime.from_unix_utc (r.fetch_int (r.field_index ("update_time")));
            time_loaded = new DateTime.from_unix_utc (r.fetch_int (r.field_index ("load_time")));
            unread = r.fetch_int (r.field_index ("unread")) == 1;
            starred = r.fetch_int (r.field_index ("starred")) == 1;
            // TODO: Decide how to retrieve owner
            // TODO: Decide how to store authors
            // TODO: Decide how to store contributors
            // TODO: Decide how to store tags
        }
    }
}
