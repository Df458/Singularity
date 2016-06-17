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

namespace Singularity
{
public class CollectionNode : Object
{
    public Feed? feed { get; construct; }
    public FeedCollection? collection { get; construct; }
    public Contents contents { get; construct; }
    public uint id { get; construct; }

    public enum Contents
    {
        NONE = -1,
        FEED,
        COLLECTION
    }

    public CollectionNode.with_feed(Feed f)
    {
        Object(feed: f, collection: null, contents: Contents.FEED, id: f.id);
    }

    public CollectionNode.with_collection(FeedCollection c)
    {
        Object(feed: null, collection: c, contents: Contents.COLLECTION, id: c.id);
    }

    public void set_parent(FeedCollection p)
    {
        if(contents == Contents.FEED) {
            feed.parent = p;
            feed.parent_id = (int)p.id;
        } else if(contents == Contents.COLLECTION) {
            collection.parent = p;
            collection.parent_id = (int)p.id;
        }
    }

    public void remove_parent()
    {
        if(contents == Contents.FEED) {
            feed.parent = null;
            feed.parent_id = -1;
        } else if(contents == Contents.COLLECTION) {
            collection.parent = null;
            collection.parent_id = -1;
        }
    }
}
}
