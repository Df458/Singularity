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

public class DatabaseManager
{
    private static const string schema_dir = "/usr/local/share/singularity/schemas";
    private Database db;
    private bool _open = false;
    public int next_id = 0;
    
    public bool open { get { return _open; } }
    
    public DatabaseManager(SessionSettings settings, string default_path)
    {
        try {
            if(settings.database_path != null)
                db = new Database(settings.database_path);
            else
                db = new Database(default_path);
            if(db.schema_version == 0) {
                if(settings.verbose)
                    stderr.printf("Creating database...\n");
                initSchema();
            }

            bool updated = false;
            do {
                updated = updateSchema();
            } while(updated);
        } catch(SQLHeavy.Error e) {
            stderr.printf("Error creating the database: %s\n", e.message);
            return;
        }
        _open = true;
        if(settings.verbose)
            stderr.printf("Database successfully created. User version is %d.\n", db.user_version);
    }
    
    public async FeedCollection load_feeds()
    {
        FeedCollection feed_list = new FeedCollection.root();

        yield load_feeds_for_collection(feed_list);

        return feed_list;
    }

    public async void load_feeds_for_collection(FeedCollection feed_list)
    {
        try {
            Query load_query = new Query(db, "SELECT * FROM feeds WHERE `parent_id` = :parent_id");
            if(feed_list.id == null)
                load_query[":parent_id"] = -1;
            else
                load_query[":parent_id"] = feed_list.id;
            Gee.ArrayList<FeedCollection> clist = new Gee.ArrayList<FeedCollection>();
            for(QueryResult result = yield load_query.execute_async(); !result.finished; result.next() ) {
                if(result.fetch_int(0) >= next_id)
                    next_id = result.fetch_int(0) + 1;
                switch(result.get_int("type")) {
                    case CollectionNode.Contents.FEED:
                        Feed f = new Feed.from_record(result);
                        CollectionNode n = new CollectionNode.with_feed(f);
                        feed_list.add_node(n);
                        break;
                    case CollectionNode.Contents.COLLECTION:
                        FeedCollection c = new FeedCollection.from_record(result);
                        CollectionNode n = new CollectionNode.with_collection(c);
                        feed_list.add_node(n);
                        break;
                }
            }
            foreach(FeedCollection c in clist) {
                yield load_feeds_for_collection(c);
            }
        } catch(SQLHeavy.Error e) {
            error("Error loading feed data: %s\n", e.message);
        }
    }

    public async void save_updates(UpdatePackage package)
    {
        try {
            Query? feed_query = package.feed.update(db);
            yield feed_query.execute_async();

            foreach(Item i in package.items) {
                Query test_query = new Query(db, "SELECT COUNT FROM items WHERE `feed_id` = :id AND `guid` = :guid");
                test_query[":id"] = i.owner.id;
                test_query[":guid"] = i.guid;
                QueryResult test_result = yield test_query.execute_async();
                Query? q;
                if(test_result.fetch_int(0) == 0) {
                    q = i.insert(db);
                } else {
                    q = i.update(db);
                }

                if(q != null)
                    yield q.execute_async();
            }
        } catch(SQLHeavy.Error e) {
            error("Error saving item data: %s\n", e.message);
        }
    }

    public async bool feed_exists(Feed f)
    {
        try {
            Query test_query = new Query(db, "SELECT COUNT FROM feeds WHERE `link` = :link");
            test_query[":link"] = f.link;
            QueryResult test_result = yield test_query.execute_async();
            return test_result.fetch_int(0) != 0;
        } catch(SQLHeavy.Error e) {
            error("Error checking database for feeds: %s\n", e.message);
        }
    }

    public async void save_new_feed(Feed to_save)
    {
        try {
            Query q = to_save.insert(db);
            q.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Error checking database for feeds: %s\n", e.message);
        }
    }

    public async void save_new_collection(FeedCollection to_save)
    {
        try {
            Query q = to_save.insert(db);
            q.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Error checking database for feeds: %s\n", e.message);
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
}
