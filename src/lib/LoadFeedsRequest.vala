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

namespace Singularity
{
// DatabaseRequest for loading all feeds, collections, and items
public class LoadFeedsRequest : DatabaseRequest, GLib.Object
{
    public FeedCollection feeds { get; private set; default = new FeedCollection.root(); }
    public int unread_count { get; private set; default = 0; }
    public Gee.HashMap<int, int> count_map { get; private set; default = new Gee.HashMap<int, int>(); }

    public Query build_query(Database db)
    {
        try {
            if(current_id == -1)
                return new Query(db, "SELECT feeds.*, icons.*, sum(items.unread) AS unread_count FROM feeds LEFT OUTER JOIN icons ON feeds.id = icons.id LEFT OUTER JOIN items ON items.parent_id = feeds.id GROUP BY feeds.id ORDER BY feeds.id");
            else
                return new Query(db, "SELECT * FROM %s WHERE %s = %d".printf(tables[current_step], parent_columns[current_step], m_node_list[current_id].id));
        } catch(SQLHeavy.Error e) {
            error("failed to load feeds: %s", e.message);
        }
    }

    public RequestStatus process_result(QueryResult res)
    {
        if(current_id == -1) {
            try {
                for(; !res.finished; res.next()) {
                    CollectionNode n = null;
                    switch(res.get_int("type")) {
                        case CollectionNode.Contents.FEED:
                            n = new CollectionNode(new Feed.from_record(res));
                            unread_count += res.get_int("unread_count");
                            count_map[n.data.id] = res.get_int("unread_count");
                        break;
                        case CollectionNode.Contents.COLLECTION:
                            n = new CollectionNode(new FeedCollection.from_record(res));
                        break;
                    }
                    m_node_map[n.data.id] = n;
                    m_node_list.add(n);
                }
            } catch(SQLHeavy.Error e) {
                error("Failed to build feed structure: %s", e.message);
            }

            foreach(CollectionNode n in m_node_list) {
                if(n.data.parent_id == -1)
                    feeds.add_node(n);
                else
                    (m_node_map[n.data.parent_id].data as FeedCollection).add_node(n);
            }
        } else {
            switch(current_step)
            {
                case ChildType.ITEM:
                    try {
                        for(; !res.finished; res.next())
                            (m_node_list[current_id].data as Feed).add_item(new Item.from_record(res));
                    } catch(SQLHeavy.Error e) {
                        error("Failed to build feed structure: %s", e.message);
                    }
                    break;
                case ChildType.ENCLOSURE:
                    try {
                        for(; !res.finished; res.next()) {
                            (m_node_list[current_id].data as Feed).get_item(res.fetch_string(res.field_index("item_guid"))).attachments.add(new Attachment.from_record(res));
                        }
                    } catch(SQLHeavy.Error e) {
                        error("Failed to build feed structure: %s", e.message);
                    }
                    break;
                case ChildType.PERSON:
                    try {
                        for(; !res.finished; res.next()) {
                            (m_node_list[current_id].data as Feed).get_item(res.fetch_string(res.field_index("item_guid"))).author = new Person.from_record(res);
                        }
                    } catch(SQLHeavy.Error e) {
                        error("Failed to build feed structure: %s", e.message);
                    }
                    break;
            }

            current_step++;

            if(current_step > ChildType.LAST)
                current_step = ChildType.ITEM;
            else
                return RequestStatus.CONTINUE;
        }

        while(current_id + 1 < m_node_list.size) {
            current_id++;
            if(m_node_list[current_id].data is Feed)
                return RequestStatus.CONTINUE;
        }

        return RequestStatus.DEFAULT;
    }

    private Gee.HashMap<int, CollectionNode> m_node_map = new Gee.HashMap<int, CollectionNode>();
    private Gee.List<CollectionNode> m_node_list = new Gee.ArrayList<CollectionNode>();
    private int current_id = -1;
    private int current_step = ChildType.ITEM;

    private const string[] tables = { "items", "enclosures", "people" };
    private const string[] parent_columns = { "parent_id", "feed_id", "feed_id" };

    enum ChildType {
        ITEM = 0,
        ENCLOSURE,
        PERSON,
        LAST = PERSON
    }
}
}
