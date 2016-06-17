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

using SQLHeavy;

namespace Singularity
{
    public class FeedCollection : DataEntry
    {
        public int              parent_id   { get; set; }
        public FeedCollection?  parent      { get; set; }
        public string title { get; protected set; }
        public Icon? icon   { get; protected set; }
        public Gee.List<CollectionNode> nodes { get; protected set; }

        public enum DBColumn
        {
            ID = 0,
            TITLE,
            COUNT
        }

        public FeedCollection.from_record(Record r) { parent = null; parent_id = -1; base.from_record(r); }
        public FeedCollection.root() { parent = null; parent_id = -1; }

        public void add_node(CollectionNode c)
        {
            nodes.add(c);
            c.set_parent(this);
        }

        public void remove_node(CollectionNode c)
        {
            nodes.remove(c);
            c.remove_parent();
        }

        public override Query? insert(Queryable q)
        {
            try {
                Query query = new Query(q, "INSERT INTO feeds (id, parent_id, type, title) VALUES (:id, :parent_id, :type, :title)");
                query[":id"] = id;
                query[":parent_id"] = parent_id;
                query[":type"] = CollectionNode.Contents.COLLECTION;
                query[":title"] = title;
                // TODO: Decide how to store icons
                return query;
            } catch(SQLHeavy.Error e) {
                warning("Cannot insert collection data: " + e.message);
                return null;
            }
        }

        public override Query? update(Queryable q)
        {
            try {
                Query query = new Query(q, "UPDATE collections SET title = :title, parent_id = :parent_id WHERE id = :id");
                query[":id"] = id;
                query[":parent_id"] = parent_id;
                query[":title"] = title;
                // TODO: Decide how to store icons
                return query;
            } catch(SQLHeavy.Error e) {
                warning("Cannot update collection data: " + e.message);
                return null;
            }
        }

        public override Query? remove(Queryable q)
        {
            try {
                Query query = new Query(q, "DELETE FROM collections WHERE `id` = :id");
                query[":id"] = id;
                return query;
            } catch(SQLHeavy.Error e) {
                warning("Cannot remove collection data: " + e.message);
                return null;
            }
        }

        protected override bool build_from_record(SQLHeavy.Record r)
        {
            try {
                title = r.fetch_string(DBColumn.TITLE);
                // TODO: Decide how to store icons
                return true;
            } catch(SQLHeavy.Error e) {
                warning("Cannot load collection data: " + e.message);
                return false;
            }
        }
    }
}
