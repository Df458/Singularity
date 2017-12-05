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

namespace Singularity
{
    // DataEntry holding common data for both the Feed and Collection classes
    public abstract class FeedDataEntry : DataEntry
    {
        public string title { get; set; }
        public int parent_id { get; protected set; default = -1; }

        private FeedCollection? _parent = null;
        public FeedCollection? parent
        {
            get { return _parent; }
            set {
                _parent = value;

                if(value == null)
                    parent_id = -1;
                else
                    parent_id = value.id;
            }
        }

        public abstract Gee.List<Item> get_items();
    }

    // Represents a node within a CollectionTreeStore, and wraps FeedDataEntry
    // with information about parents and helper functions to help prevent extra
    // type-checking code elsewhere
    public class CollectionNode : Object
    {
        public FeedDataEntry data { get; construct set; }
        public int id { get { return data.id; } }

        public CollectionNode(FeedDataEntry entry)
        {
            Object(data: entry);
        }

        // Returns a list containing all of the node's children.
        // If this node wraps a Feed, an empty list is returned.
        public Gee.List<CollectionNode> get_children()
        {
            if(data is FeedCollection)
                return (data as FeedCollection).nodes;

            return new Gee.ArrayList<CollectionNode>();
        }

        // Represents the a FeedDataEntry's type in the database.
        // TODO: Refactor out if possible, find a more elegant way to describe
        //       the Feed/FeedCollection type difference
        public enum Contents
        {
            FEED,
            COLLECTION
        }
    }
}
