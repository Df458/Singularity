/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2014  Hugues Ross <hugues.ross@gmail.com>

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

public class DatabaseManager
{
    private static const string schema_dir = "/usr/local/share/singularity/schemas";
    private Database db;
    private bool _open = false;
    public int next_id = 0;
    
    public bool open { get { return _open; } }
    
    public DatabaseManager.from_path(string location)
    {
        if(verbose)
            stderr.printf("Creating database...\n");
        try {
            db = new Database(location);
            if(db.schema_version == 0) {
                initSchema();
            }

            bool updated = false;
            do {
                updated = updateSchema();
            } while(updated);
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error creating database: %s\n", e.message);
            return;
        }
        _open = true;
        if(verbose)
            stderr.printf("Database successfully created. User version is %d.\n", db.user_version);
    }
    
    public async Gee.ArrayList<Feed> loadFeeds()
    {
        Gee.ArrayList<Feed> feed_list = new Gee.ArrayList<Feed>();

        try {
            Query load_query = new Query(db, "SELECT * FROM feeds");
            for(QueryResult result = yield load_query.execute_async(); !result.finished; result.next() ) {
                if(result.fetch_int(0) >= next_id)
                    next_id = result.fetch_int(0) + 1;
                Feed f = new Feed.from_db(result);
                feed_list.add(f);
            }
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error loading feed data: %s\n", e.message);
        }

        return feed_list;
    }
	
    public async void loadFeedItems(Feed feed, int item_count = -1)
    {
        try {
            Query load_query = new Query(db, "SELECT * FROM items WHERE `parent_id` = :id ORDER BY savedate DESC LIMIT :count");
            load_query[":id"] = feed.id;
            load_query[":count"] = item_count;
            
            for ( QueryResult result = yield load_query.execute_async(); !result.finished; result.next() ) {
            feed.add_item(new Item.from_db(result));
            }
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error loading item data: %s\n", e.message);
        }
    }

    // Adds a feed for the first time, with just a link and id
    public void addFeed(Feed feed)
    {
        try {
            Query save_query = new Query(db, "INSERT INTO feeds (id, parent_id, title, origin) VALUES (:id, -1, :title, :origin)");
            save_query[":id"] = feed.id;
            save_query[":title"] = feed.title;
            save_query[":origin"] = feed.origin_link;
            save_query.execute();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error saving feed data: %s\n", e.message);
        }
    }

    // Updates a feed with new data
    public async void saveFeed(Feed feed, bool save_items = true)
    {
        try {
            Query save_query = new Query(db, "UPDATE feeds SET parent_id = :parent_id, title = :title, link = :link, description = :description, origin = :origin, last_load_guids = :last_guids, last_load_time = :last_time WHERE id = :id");
            save_query[":id"] = feed.id;
            save_query[":parent_id"] = feed.parent_id;
            save_query[":title"] = feed.title;
            save_query[":link"] = feed.link;
            save_query[":description"] = feed.description;
            save_query[":origin"] = feed.origin_link;
            save_query[":last_guids"] = feed.get_guids();
            save_query[":last_time"] = feed.last_time.to_unix();
            yield save_query.execute_async();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error saving feed data: %s\n", e.message);
        }
        if(save_items) {
            yield saveFeedItems(feed, feed.items);
        }
    }

    public async void saveFeedItems(Feed feed, Gee.ArrayList<Item> items)
    {
        try {
            Query update_query = new Query(db, "UPDATE feeds SET last_load_guids = :last_guid, last_load_time = :last_time WHERE id = :id");
            if(verbose)
                stdout.printf("Saving guids: %s\n", feed.get_guids());
            update_query[":last_guid"] = feed.get_guids();
            update_query[":last_time"] = feed.last_time.to_unix();
            update_query[":id"] = feed.id;
            yield update_query.execute_async();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error updating feed: %s", e.message);
        }
        foreach(Item i in items) {
            yield saveItem(i, feed.id);
        }
    }

    public async void saveItem(Item item, int feed_id)
    {
        try {
            Query test_query = new Query(db, "SELECT * FROM items WHERE `parent_id` = :id AND `guid` = :guid");
            test_query[":id"] = feed_id;
            test_query[":guid"] = item.guid;
            QueryResult test_result = yield test_query.execute_async();
            if(!test_result.finished && verbose) {
                stderr.printf("Item <%s> already exists!\n", item.guid);
                return;
            }

            Query save_query = new Query(db, "INSERT INTO items (parent_id, title, link, description, author, guid, pubdate, unread, starred, savedate, attachments) VALUES (:id, :title, :link, :description, :author, :guid, :pubdate, :unread, :starred, :savedate, :attachments)");
            save_query[":id"] = feed_id;
            save_query[":title"] = item.title;
            save_query[":link"] = item.link;
            save_query[":description"] = item.description;
            save_query[":author"] = item.author;
            save_query[":guid"] = item.guid;
            save_query[":pubdate"] = item.time_posted.to_unix();
            save_query[":unread"] = item.unread ? 1 : 0;
            save_query[":starred"] = item.starred ? 1 : 0;
            save_query[":savedate"] = item.time_added.to_unix();
            save_query[":attachments"] = item.enclosure_url;
            yield save_query.execute_async();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error saving feed data: %s\n", e.message);
        }
    }

    public async void updateFeedSettings(Feed f, string rules)
    {
        try {
            Query save_query = new Query(db, "UPDATE feeds SET rules = :rules, override_download = :override, ask_download_location = :getloc, default_location = :loc WHERE id = :id");
            save_query[":id"] = f.id;
            save_query[":rules"] = rules;
            save_query[":override"] = f.override_location ? 1 : 0;
            save_query[":getloc"] = f.get_location ? 1 : 0;
            save_query[":loc"] = f.default_location;
            yield save_query.execute_async();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error saving feed data: %s\n", e.message);
        }
    }

    public async void removeFeed(Feed f)
    {
        try {
            if(verbose)
                stderr.printf("Removing feed...");
            Query feed_rm_query = new Query(db, "DELETE FROM feeds WHERE `id` = :id");
            feed_rm_query[":id"] = f.id;
            yield feed_rm_query.execute_async();
            
            if(verbose)
                stderr.printf("Removing entries...");
            Query item_rm_query = new Query(db, "DELETE FROM items WHERE `parent_id` = :id");
            item_rm_query[":id"] = f.id;
            yield item_rm_query.execute_async();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error deleting feed: %s\n", e.message);
        }
    }

    public async void updateUnread(Feed feed, Gee.ArrayList<Item> items)
    {
        foreach(Item item in items) {
            try {
                Query save_query = new Query(db, "UPDATE items SET unread = :unread WHERE guid = :guid");
                save_query[":guid"] = item.guid;
                save_query[":unread"] = item.unread ? 1 : 0;
                yield save_query.execute_async();
            } catch(SQLHeavy.Error e) {
                stderr.printf("Error saving feed data: %s\n", e.message);
            }
        }
    }

    public async void updateStarred(Feed feed, Item item)
    {
        try {
            Query save_query = new Query(db, "UPDATE items SET starred = :starred WHERE parent_id = :fid AND guid = :guid");
            save_query[":guid"] = item.guid;
            save_query[":starred"] = item.starred ? 1 : 0;
            save_query[":fid"] = feed.id;
            yield save_query.execute_async();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error saving feed data: %s\n", e.message);
        }
    }
    
    public async void updateSingleUnread(Item item)
    {
	    try {
            Query save_query = new Query(db, "UPDATE items SET unread = :unread WHERE guid = :guid");
            save_query[":guid"] = item.guid;
            save_query[":unread"] = item.unread ? 1 : 0;
            yield save_query.execute_async();
	    } catch(SQLHeavy.Error e) {
            stderr.printf("Error saving feed data: %s\n", e.message);
        }
    }

    public async void removeOld()
    {
        try {
            DateTime cutoff = new DateTime.now_utc().add_months(-1);
            Query rm_query = new Query(db, "DELETE FROM items WHERE savedate < :cutoff");
            rm_query[":cutoff"] = cutoff.to_unix();
            yield rm_query.execute_async();
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error clearing old items: %s", e.message);
        }
    }

    /*
     * Finds and applies Create.sql file.
     * If it isn't found, return false.
     */
    private bool initSchema()
    {
        StringBuilder builder = new StringBuilder(schema_dir);
        builder.append("/Create.sql");
        File script = File.new_for_path(builder.str);
        if(!script.query_exists())
            return false;

        try {
            db.run_script(builder.str);
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error initializing database: %s\n", e.message);
            return false;
        }
        return true;
    }

    /*
     * Search for and apply an Update_to_(user_version) file for the next user_version.
     * If none are found, return false.
     */
    private bool updateSchema()
    {
        StringBuilder builder = new StringBuilder(schema_dir);
        builder.append_printf("/Update-to-%d.sql", db.user_version + 1);
        File script = File.new_for_path(builder.str);
        if(!script.query_exists())
            return false;

        try {
            db.run_script(builder.str);
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error updating database version to %d: %s\n", db.user_version + 1, e.message);
            return false;
        }
        db.user_version += 1;
        return true;
    }
}
