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
    public int next_feed_id = 0;
    public int next_item_id = 0;
    
    public bool open { get { return _open; } }
    
    public DatabaseManager(SessionSettings settings, GlobalSettings global_settings, string default_path)
    {
        m_global_settings = global_settings;

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

        prepare.begin();
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
            load_query[":parent_id"] = feed_list.id;

            Gee.ArrayList<FeedCollection> clist = new Gee.ArrayList<FeedCollection>();
            for(QueryResult result = yield load_query.execute_async(); !result.finished; result.next() ) {
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
                        clist.add(c);
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

    public async Gee.List<Item?> load_items_for_node(CollectionNode? node, bool unread_only, bool starred_only)
    {
        /* yield lock_command(); */
        StringBuilder q_builder = new StringBuilder("SELECT * FROM items");
        Gee.ArrayList<Item?> item_list = new Gee.ArrayList<Item?>();

        if(node == null) {
            if(unread_only || starred_only)
                q_builder.append(" WHERE ");
        } else if(node.contents == CollectionNode.Contents.COLLECTION) {
            // TODO: Get all contained feeds
            if(unread_only || starred_only)
                q_builder.append(" AND ");
        } else {
            q_builder.append(" WHERE `parent_id` = :parent_id");
            if(unread_only || starred_only)
                q_builder.append(" AND ");
        }
        if(unread_only) {
            q_builder.append("`unread` = 1");
            if(starred_only)
                q_builder.append(" AND ");
        }
        if(starred_only) {
            q_builder.append("`starred` = 1");
        }

        /* stderr.printf("COMMAND: %s (%d)\n", q_builder.str, node.id); */

        try {
            Query q = new Query(db, q_builder.str);
            if(node != null) {
                if(node.contents == CollectionNode.Contents.COLLECTION) {
                    // TODO: Get all contained feeds
                } else {
                    q[":parent_id"] = node.id;
                }
            }

            for(QueryResult result = yield q.execute_async(); !result.finished; result.next() ) {
                item_list.add(new Item.from_record(result));
            }
        } catch(SQLHeavy.Error e) {
            warning("Failed to load items: %s (Query %s)", e.message, q_builder.str);
        }

        /* unlock_command(); */

        return item_list;
    }

    public async void save_updates(UpdatePackage package)
    {
        yield lock_command();
        try {
            Query? feed_query = package.feed.update(db);
            if(feed_query != null)
                yield feed_query.execute_async();

            foreach(Item i in package.items) {
                if(i == null)
                    continue;
                Query test_query = new Query(db, "SELECT COUNT(), id FROM items WHERE `parent_id` = :id AND `guid` = :guid");
                test_query[":id"] = package.feed.id;
                test_query[":guid"] = i.guid;
                QueryResult test_result = yield test_query.execute_async();
                Query? q;
                if(test_result.fetch_int(0) == 0) {
                    i.prepare_for_db(next_item_id);
                    q = i.insert(db);
                    next_item_id++;
                } else {
                    i.prepare_for_db(test_result.fetch_int(1));
                    q = i.update(db);
                }

                if(q != null)
                    yield q.execute_async();
            }
        } catch(SQLHeavy.Error e) {
            unlock_command();
            error("Error saving item data: %s\n", e.message);
        }

        yield cleanup_id(package.feed.id);

        unlock_command();
    }

    public async bool feed_exists(Feed f)
    {
        try {
            Query test_query = new Query(db, "SELECT COUNT() FROM feeds WHERE `link` = :link");
            test_query[":link"] = f.link;
            QueryResult test_result = yield test_query.execute_async();
            return test_result.fetch_int(0) != 0;
        } catch(SQLHeavy.Error e) {
            error("Error checking database for feeds: %s\n", e.message);
        }
    }

    public async void save_new_node(CollectionNode to_save)
    {
        yield lock_command();
        switch(to_save.contents)
        {
            case CollectionNode.Contents.FEED:
                yield save_new_feed(to_save.feed);
                break;

            case CollectionNode.Contents.COLLECTION:
                yield save_new_collection(to_save.collection);
                foreach(CollectionNode child in to_save.collection.nodes) {
                    child.set_parent(to_save.collection); // This updates the parent id before saving
                    yield save_new_node(child);
                }
                break;
        }
        unlock_command();
    }

    public async void view_item(int id)
    {
        yield lock_command();
        try {
            Query view_query = new Query(db, "UPDATE items SET unread = 0 WHERE id = :id");
            view_query[":id"] = id;
            yield view_query.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Error marking item: %s\n", e.message);
        }

        unlock_command();
    }

    public async void toggle_star(int id)
    {
        yield lock_command();
        try {
            Query view_query = new Query(db, "UPDATE items SET starred = 1 - starred WHERE id = :id");
            view_query[":id"] = id;
            yield view_query.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Error marking item: %s\n", e.message);
        }

        unlock_command();
    }

    public async void toggle_unread(int id)
    {
        yield lock_command();
        try {
            Query view_query = new Query(db, "UPDATE items SET unread = 1 - unread WHERE id = :id");
            view_query[":id"] = id;
            yield view_query.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Error marking item: %s\n", e.message);
        }

        unlock_command();
    }

    public async void unsubscribe(Feed f)
    {
        yield lock_command();
        try {
            Query q_ufeed = new Query(db, "DELETE FROM feeds WHERE `id` = :id");
            q_ufeed[":id"] = f.id;
            yield q_ufeed.execute_async();
            Query q_uitem = new Query(db, "DELETE FROM items WHERE `parent_id` = :id");
            q_uitem[":id"] = f.id;
            yield q_uitem.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Can't unsubscribe: %s", e.message);
        }
        unlock_command();
    }

//-----------------------------------------------------------------------------

    private CommandWrapper[] m_waitlist = null;
    private unowned GlobalSettings m_global_settings;

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

    private async void prepare()
    {
        yield lock_command();

        try {
            Query fnext = new Query(db, "SELECT MAX(id) FROM feeds");
            Query inext = new Query(db, "SELECT MAX(id) FROM items");
            QueryResult fres = yield fnext.execute_async();
            QueryResult ires = yield inext.execute_async();
            next_feed_id = fres.fetch_int(0) + 1;
            next_item_id = ires.fetch_int(0) + 1;
        } catch(SQLHeavy.Error e) {
            error("Error preparing database ids: %s\n", e.message);
        }

        unlock_command();
    }

    private async void save_new_feed(Feed to_save)
    {
        try {
            to_save.prepare_for_db(next_feed_id);
            next_feed_id++;
            Query q = to_save.insert(db);
            yield q.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Error checking database for feeds: %s\n", e.message);
        }
    }

    private async void save_new_collection(FeedCollection to_save)
    {
        try {
            to_save.prepare_for_db(next_feed_id);
            next_feed_id++;
            Query q = to_save.insert(db);
            yield q.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Error checking database for feeds: %s\n", e.message);
        }
    }

    private async void lock_command()
    {
        /* if(m_waitlist != null) { */
        /*     CommandWrapper command = new CommandWrapper(lock_command.callback); */
        /*     m_waitlist += (owned) command; */
        /*     yield; */
        /* } else { */
        /*     m_waitlist = new CommandWrapper[0]; */
        /* } */
    }

    private async void cleanup_id(int id)
    {
        StringBuilder q_builder = new StringBuilder("DELETE FROM items WHERE `parent_id` = :id AND (");
        bool delete_read = m_global_settings.read_rule[2] == 2;
        bool delete_unread = m_global_settings.unread_rule[2] == 2;
        if(!delete_read && !delete_unread)
            return;
        DateTime read_time = new DateTime.now_utc();
        DateTime unread_time = new DateTime.now_utc();

        if(delete_read) {
            q_builder.append("(`unread` = 0 AND `load_time` < :read_time)");
            read_time = read_time.add_minutes(-1);
            switch(m_global_settings.read_rule[1]) {
                case 0:
                    read_time = read_time.add_days(m_global_settings.read_rule[0] * -1);
                    break;
                case 1:
                    read_time = read_time.add_months(m_global_settings.read_rule[0] * -1);
                    break;
                case 2:
                    read_time = read_time.add_years(m_global_settings.read_rule[0] * -1);
                    break;
            }
            if(delete_unread)
                q_builder.append(" OR ");
            else
                q_builder.append(")");
            /* stderr.printf("Deleting read before %ld (%d) \u2026\n", (long)read_time.to_unix(), id); */
        }

        if(delete_unread) {
            q_builder.append_printf("(`unread` = 1 AND `load_time` < :unread_time))");
            switch(m_global_settings.unread_rule[1]) {
                case 0:
                    unread_time = unread_time.add_days(m_global_settings.unread_rule[0] * -1);
                    break;
                case 1:
                    unread_time = unread_time.add_months(m_global_settings.unread_rule[0] * -1);
                    break;
                case 2:
                    unread_time = unread_time.add_years(m_global_settings.unread_rule[0] * -1);
                    break;
            }
            stderr.printf("Deleting unread\u2026\n");
        }

        try {
            Query q_clean = new Query(db, q_builder.str);
            q_clean[":id"] = id;
            if(delete_read)
                q_clean[":read_time"] = read_time.to_unix();
            if(delete_unread)
                q_clean[":unread_time"] = unread_time.to_unix();
            yield q_clean.execute_async();
        } catch(SQLHeavy.Error e) {
            error("Can't clean up id: %s: %s", e.message, q_builder.str);
        }
    }

    private void unlock_command()
    {
        /* if(m_waitlist != null) { */
        /*     foreach(CommandWrapper c in m_waitlist) */
        /*         c.func(); */
        /*     m_waitlist = null; */
        /* } */
    }
}

public class CommandWrapper
{
    public SourceFunc func {get; private set; }

    public CommandWrapper(SourceFunc f) { func = f; }
}
}
