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
using Gee;
using SQLHeavy;

namespace Singularity {
    // Represents an RSS/Atom/RDF feed
    public class Feed : FeedDataEntry {
        public string? description { get; set; }
        public string link { get; set; }
        public string? site_link { get; set; }
        public string? rights { get; set; }
        public Collection<Tag?> tags { get; set; }
        public string? generator { get; set; }
        public string? icon_url { get; set; }
        public Gdk.Pixbuf? icon { get; set; default = null; }
        public DateTime? last_update { get; set; default = new DateTime.from_unix_utc (0); }

        public bool should_update {
            get {
                return last_update.add_minutes ((int)AppSettings.auto_update_freq)
                    .compare (new DateTime.now_utc ()) <= 0;
            }
        }

        public enum DBColumn {
            ID = 0,
            TYPE,
            TITLE,
            PARENT,
            ICON,
            LINK,
            SITE_LINK,
            DESCRIPTION,
            RIGHTS,
            GENERATOR,
            LAST_UPDATE,
            COUNT
        }

        public Feed () {}

        public Feed.from_record (Record r) {
            base.from_record (r);
        }

        // Sets contents based on a FeedProvider's contents
        public bool update_contents (FeedProvider provider) {
            if (provider.stored_feed == null)
                return false;

            title = provider.stored_feed.title == "" ? "Untitled Feed" : provider.stored_feed.title;

            if (provider.stored_feed.description != null)
                description = provider.stored_feed.description;

            if (provider.stored_feed.site_link != null)
                site_link = provider.stored_feed.site_link;

            if (provider.stored_feed.rights != null)
                rights = provider.stored_feed.rights;

            // TODO: Update tags

            if (provider.stored_feed.generator != null)
                generator = provider.stored_feed.generator;

            icon = provider.stored_feed.icon;

            last_update = provider.stored_feed.last_update;

            return true;
        }

        public override Query? insert (Queryable q) {
            try {
                Query query = new Query (q, """INSERT INTO feeds
                        (id, parent_id, type, title, link, site_link, description, rights, generator, last_update)
                        VALUES (
                            :id,
                            :parent_id,
                            :type,
                            :title,
                            :link,
                            :site_link,
                            :description,
                            :rights,
                            :generator,
                            :last_update
                        )""");
                query[":id"] = id;
                query[":parent_id"] = parent_id;
                query[":type"] = (int)CollectionNode.Contents.FEED;
                query[":title"] = title;
                query[":link"] = link;
                query[":site_link"] = site_link;
                query[":description"] = description;
                query[":rights"] = rights;
                query[":generator"] = generator;
                query[":last_update"] = last_update.to_unix ();
                // TODO: Decide how to store icons
                // TODO: Decide how to store tags
                return query;
            } catch (SQLHeavy.Error e) {
                warning ("Cannot insert feed data: " + e.message);
                return null;
            }
        }

        public override Query? update (Queryable q) {
            try {
                // TODO: Build the query to only have what's needed
                Query query = new Query (q, """UPDATE feeds SET
                        title = :title,
                        link = :link,
                        site_link = :site_link,
                        description = :description,
                        rights = :rights,
                        generator = :generator,
                        last_update = :last_update
                    WHERE id = :id""");
                query[":id"] = id;
                query[":title"] = title;
                query[":link"] = link;
                query[":site_link"] = site_link;
                query[":description"] = description;
                query[":rights"] = rights;
                query[":generator"] = generator;
                query[":last_update"] = last_update.to_unix ();
                // TODO: Decide how to store icons
                // TODO: Decide how to store tags
                return query;
            } catch (SQLHeavy.Error e) {
                warning ("Cannot update feed data: " + e.message);
                return null;
            }
        }

        public override Query? remove (Queryable q) {
            try {
                Query query = new Query (q, "DELETE FROM feeds WHERE `id` = :id");
                query[":id"] = id;
                return query;
            } catch (SQLHeavy.Error e) {
                warning ("Cannot remove feed data: " + e.message);
                return null;
            }
        }

        public string to_string () {
            return "%d (%d): %s [%s | %s]".printf (id, parent_id, title, link, site_link);
        }

        // Sets ID value in preparation for database access
        public void prepare_for_db (int new_id) {
            set_id (new_id);
        }

        // Return a collection containing this feed
        public override Gee.List<Feed> get_feeds () {
            Gee.List<Feed> feeds = new Gee.ArrayList<Feed> ();
            feeds.add (this);
            return feeds;
        }

        // Return contained Items for viewing
        public override Gee.List<Item> get_items () {
            return items;
        }

        // Find a child Item using the given guid
        public Item get_item (string guid, bool is_hash = true) {
            return items.first_match ((i) => { return is_hash ? i.guid == guid : i.weak_guid == guid; });
        }

        // Adds an item and sets its owner
        public void add_item (Item i) {
            i.owner = this;
            items.add (i);
        }

        protected override bool build_from_record (SQLHeavy.Record r) {
            try {
                // FIXME: This is currently necessary due to a left outer join. See if this can be removed somehow.
                set_id (r.fetch_int (0));

                parent_id = r.fetch_int (r.field_index ("parent_id"));
                title = r.fetch_string (r.field_index ("title"));
                link = r.fetch_string (r.field_index ("link"));
                site_link = r.fetch_string (r.field_index ("site_link"));
                description = r.fetch_string (r.field_index ("description"));
                rights = r.fetch_string (r.field_index ("rights"));
                generator = r.fetch_string (r.field_index ("generator"));
                last_update = new DateTime.from_unix_utc (r.fetch_int (r.field_index ("last_update")));
                // TODO: Decide how to store icons
                // TODO: Decide how to store tags
                uint8[] data = r.fetch_blob (r.field_index ("data"));
                if (data != null) {
                    int width = r.fetch_int (r.field_index ("width"));
                    int height = r.fetch_int (r.field_index ("height"));
                    int bits = r.fetch_int (r.field_index ("bits"));
                    int stride = r.fetch_int (r.field_index ("rowstride"));
                    bool has_alpha = r.fetch_int (r.field_index ("alpha")) == 1;
                    icon = new Gdk.Pixbuf.from_data (data, Gdk.Colorspace.RGB, has_alpha, bits, width, height, stride);
                }
                return true;
            } catch (SQLHeavy.Error e) {
                warning ("Cannot load collection data: " + e.message);
                return false;
            }
        }

        private Gee.List<Item> items = new Gee.ArrayList<Item> ();
    }
}
