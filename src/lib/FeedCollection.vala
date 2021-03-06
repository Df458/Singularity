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
    // Represents a collection of feeds. FeedCollections act a lot like folders,
    // and can hold both feeds and other collections.
    public class FeedCollection : FeedDataEntry {
        public Icon? icon { get; protected set; }
        public Gee.List<CollectionNode> nodes { get; protected set; default = new Gee.ArrayList<CollectionNode> (); }

        public enum DBColumn {
            ID = 0,
            TITLE,
            COUNT
        }

        public FeedCollection (string new_title) {
            title = new_title;
        }

        public FeedCollection.from_record (Record r) {
            base.from_record (r);
        }

        public FeedCollection.root () { }

        // Adds a node as a child, and updates its parent
        public void add_node (CollectionNode c) {
            nodes.add (c);
            c.data.parent = this;
        }

        // Removes a child node, and updates its parent
        public void remove_node (CollectionNode c)
            requires (nodes.contains (c)) {
            nodes.remove (c);
            c.data.parent = null;
        }

        /** Creates a query for inserting this entry
         *
         * @param q The Queryable to run this query against
         */
        public override Query? insert (Queryable q) throws SQLHeavy.Error {
            Query query = new Query (q, """INSERT INTO feeds (id, parent_id, type, title)
                VALUES (:id, :parent_id, :type, :title)""");
            query[":id"] = id;
            query[":parent_id"] = parent_id;
            query[":type"] = CollectionNode.Contents.COLLECTION;
            query[":title"] = title;
            // TODO: Decide how to store icons
            return query;
        }

        /** Creates a query for updating this entry
         *
         * @param q The Queryable to run this query against
         */
        public override Query? update (Queryable q) throws SQLHeavy.Error {
            Query query = new Query (q, """UPDATE collections SET
                    title = :title,
                    parent_id = :parent_id
                WHERE id = :id""");
            query[":id"] = id;
            query[":parent_id"] = parent_id;
            query[":title"] = title;
            // TODO: Decide how to store icons
            return query;
        }

        /** Creates a query for removing this entry
         *
         * @param q The Queryable to run this query against
         */
        public override Query? remove (Queryable q) throws SQLHeavy.Error {
            Query query = new Query (q, "DELETE FROM collections WHERE `id` = :id");
            query[":id"] = id;
            return query;
        }

        /** Populate data from a database record
         *
         * @param r The record to read
         */
        protected override void build_from_record (Record r) throws SQLHeavy.Error {
            set_id (r.fetch_int (0));

            parent_id = r.fetch_int (r.field_index ("parent_id"));
            title = r.get_string ("title");
            // TODO: Decide how to store icons
        }

        public void prepare_for_db (int new_id) {
            set_id (new_id);
        }

        // Returns all feeds contained in this collection
        public override Gee.List<Feed> get_feeds () {
            Gee.List<Feed> feeds = new Gee.ArrayList<Feed> ();
            foreach (CollectionNode node in nodes) {
                feeds.add_all (node.data.get_feeds ());
            }

            return feeds;
        }

        // Returns the union of all items contained in child nodes
        public override Gee.List<Item> get_items () {
            Gee.List<Item> items = new Gee.ArrayList<Item> ();
            foreach (CollectionNode node in nodes) {
                items.add_all (node.data.get_items ());
            }

            return items;
        }
    }
}
