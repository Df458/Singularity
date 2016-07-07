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
using Gee;
using SQLHeavy;

namespace Singularity
{
    public class Feed : DataEntry
    {
        public int              parent_id   { get; set; }
        public FeedCollection?  parent      { get; set; }
        public string           title       { get; set; }
        public string?          description { get; set; }
        public string           link        { get; set; }
        public string?          site_link   { get; set; }
        public string?          rights      { get; set; }
        public Collection<Tag?> tags        { get; set; }
        public string?          generator   { get; set; }
        public Icon?            icon        { get; set; }
        public DateTime?        last_update { get; set; }

        public enum DBColumn
        {
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

        public Feed()
        {
            last_update = new DateTime.from_unix_utc(0);
            parent_id   = -1;
        }

        public Feed.from_record(Record r) { base.from_record(r); }

        public bool get_should_update()
        {
            // TODO: base this on actual update times
            return last_update.add_minutes(30).compare(new DateTime.now_utc()) <= 0;
        }

        public bool update_contents(FeedProvider provider)
        {
            if(provider.stored_feed == null)
                return false;

            if(provider.stored_feed.title != title)
                title = provider.stored_feed.title;

            if(provider.stored_feed.description != null && provider.stored_feed.description != description)
                description = provider.stored_feed.description;

            if(provider.stored_feed.site_link != null && provider.stored_feed.site_link != site_link)
                site_link = provider.stored_feed.site_link;

            if(provider.stored_feed.rights != null && provider.stored_feed.rights != rights)
                rights = provider.stored_feed.rights;

            // TODO: Update tags

            if(provider.stored_feed.generator != null && provider.stored_feed.generator != generator)
                generator = provider.stored_feed.generator;

            if(provider.stored_feed.icon != icon)
                icon = provider.stored_feed.icon;

            last_update = provider.stored_feed.last_update;

            return true;
        }

        public override Query? insert(Queryable q)
        {
            try {
                Query query = new Query(q, "INSERT INTO feeds (id, parent_id, type, title, link, site_link, description, rights, generator, last_update) VALUES (:id, :parent_id, :type, :title, :link, :site_link, :description, :rights, :generator, :last_update)");
                query[":id"] = id;
                query[":parent_id"] = parent_id;
                query[":type"] = (int)CollectionNode.Contents.FEED;
                query[":title"] = title;
                query[":link"] = link;
                query[":site_link"] = site_link;
                query[":description"] = description;
                query[":rights"] = rights;
                query[":generator"] = generator;
                query[":last_update"] = last_update.to_unix();
                // TODO: Decide how to store icons
                // TODO: Decide how to store tags
                return query;
            } catch(SQLHeavy.Error e) {
                warning("Cannot insert feed data: " + e.message);
                return null;
            }
        }

        public override Query? update(Queryable q)
        {
            try {
                // TODO: Build the query to only have what's needed
                Query query = new Query(q, "UPDATE feeds SET title = :title, link = :link, site_link = :site_link, description = :description, rights = :rights, generator = :generator, last_update = :last_update WHERE id = :id");
                query[":id"] = id;
                query[":title"] = title;
                query[":link"] = link;
                query[":site_link"] = site_link;
                query[":description"] = description;
                query[":rights"] = rights;
                query[":generator"] = generator;
                query[":last_update"] = last_update.to_unix();
                // TODO: Decide how to store icons
                // TODO: Decide how to store tags
                return query;
            } catch(SQLHeavy.Error e) {
                warning("Cannot update feed data: " + e.message);
                return null;
            }
        }

        public override Query? remove(Queryable q)
        {
            try {
                Query query = new Query(q, "DELETE FROM feeds WHERE `id` = :id");
                query[":id"] = id;
                return query;
            } catch(SQLHeavy.Error e) {
                warning("Cannot remove feed data: " + e.message);
                return null;
            }
        }

        public string to_string()
        {
            StringBuilder sb = new StringBuilder();
            sb.append_printf("%d (%d): %s [%s | %s]", id, parent_id, title, link, site_link);
            return sb.str;
        }

        protected override bool build_from_record(SQLHeavy.Record r)
        {
            try {
                title = r.fetch_string(r.field_index("title"));
                link = r.fetch_string(r.field_index("link"));
                site_link = r.fetch_string(r.field_index("site_link"));
                description = r.fetch_string(r.field_index("description"));
                rights = r.fetch_string(r.field_index("rights"));
                generator = r.fetch_string(r.field_index("generator"));
                last_update = new DateTime.from_unix_utc(r.fetch_int(r.field_index("last_update")));
                // TODO: Decide how to store icons
                // TODO: Decide how to store tags
                return true;
            } catch(SQLHeavy.Error e) {
                warning("Cannot load collection data: " + e.message);
                return false;
            }
        }

        public void prepare_for_db(int new_id)
        {
            set_id(new_id);
        }
    }
}
