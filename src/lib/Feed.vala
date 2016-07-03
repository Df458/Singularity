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
    public class Feed : Subscription<Item, Xml.Doc>, DataEntry
    {
        public int              parent_id   { get; set; }
        public FeedCollection?  parent      { get; set; }
        public string           title       { get; set; }
        public string?          description { get; set; }
        public string           link        { get; set; }
        public string?          site_link   { get; set; }
        public string?          rights      { get; protected set; }
        public Collection<Tag?> tags        { get; protected set; }
        public string?          generator   { get; protected set; }
        public Icon?            icon        { get; protected set; }
        public DateTime?        last_update { get; protected set; }
        public DateTime?        next_update { get; protected set; }

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
            NEXT_UPDATE,
            COUNT
        }

        public Feed.from_record(Record r) { base.from_record(r); }

        public bool get_should_update()
        {
            return next_update.compare(new DateTime.now_utc()) <= 0;
        }

        public bool update_contents(DataSource<Item, Xml.Doc> source)
        {
            warning("update_contents() is unimplemented.");
            return true;
        }

        public override Query? insert(Queryable q)
        {
            try {
                Query query = new Query(q, "INSERT INTO feeds (id, parent_id, type, title, link, site_link, description, rights, generator, last_update, next_update) VALUES (:id, :parent_id, :type, :title, :link, :site_link, :description, :rights, :generator, :last_update, :next_update)");
                query[":id"] = id;
                query[":parent_id"] = parent_id;
                query[":type"] = CollectionNode.Contents.FEED;
                query[":title"] = title;
                query[":link"] = link;
                query[":site_link"] = site_link;
                query[":description"] = description;
                query[":rights"] = rights;
                query[":generator"] = generator;
                query[":last_update"] = last_update.to_unix();
                query[":next_update"] = next_update.to_unix();
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
                Query query = new Query(q, "UPDATE feeds SET title = :title, link = :link, site_link = :site_link, description = :description, rights = :rights, generator = :generator, :last_update = last_update, next_update = :next_update WHERE id = :id");
                query[":id"] = id;
                query[":title"] = title;
                query[":link"] = link;
                query[":site_link"] = site_link;
                query[":description"] = description;
                query[":rights"] = rights;
                query[":generator"] = generator;
                query[":last_update"] = last_update.to_unix();
                query[":next_update"] = next_update.to_unix();
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
                next_update = new DateTime.from_unix_utc(r.fetch_int(r.field_index("next_update")));
                // TODO: Decide how to store icons
                // TODO: Decide how to store tags
                return true;
            } catch(SQLHeavy.Error e) {
                warning("Cannot load collection data: " + e.message);
                return false;
            }
        }
    }
}
