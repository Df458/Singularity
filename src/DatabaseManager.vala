using SQLHeavy;

public class DatabaseManager {
//:TODO: 27.08.14 17:23:02, Hugues Ross
// Test auto-remove feature
    private Database db;
    private bool _open = false;
    
    public bool open { get { return _open; } }
    
    public DatabaseManager.from_path(string location) {
	try {
	    db = new Database(location, FileMode.READ | FileMode.WRITE | FileMode.CREATE);
	    Query build_feeds_query = new Query(db, "CREATE TABLE IF NOT EXISTS feeds (id INTEGER, title TEXT, link TEXT, description TEXT, origin TEXT, last_guid TEXT, last_time INTEGER)");
	    build_feeds_query.execute();
	    Query build_feeds_expunged_query = new Query(db, "CREATE TABLE IF NOT EXISTS feedsExpunged (id INTEGER, title TEXT, link TEXT, description TEXT, origin TEXT, last_guid TEXT, last_time INTEGER)");
	    build_feeds_expunged_query.execute();
	    Query build_entries_query = new Query(db, "CREATE TABLE IF NOT EXISTS entries (feed_id INTEGER, title TEXT, link TEXT, description TEXT, author TEXT, categories TEXT, comments_url TEXT, enclosures TEXT, guid TEXT, pubdate INTEGER, source TEXT, unread INTEGER, savedate INTEGER)");
	    build_entries_query.execute();
	    Query build_entries_expunged_query = new Query(db, "CREATE TABLE IF NOT EXISTS entriesExpunged (feed_id INTEGER, title TEXT, link TEXT, description TEXT, author TEXT, categories TEXT, comments_url TEXT, enclosures TEXT, guid TEXT, pubdate INTEGER, source TEXT, unread INTEGER, savedate INTEGER)");
	    build_entries_expunged_query.execute();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error creating database: %s\n", e.message);
	}
	_open = true;
    }
    
    public async Gee.ArrayList<Feed> loadFeeds() {
	Gee.ArrayList<Feed> feed_list = new Gee.ArrayList<Feed>();
	
	try {
	    Query load_query = new Query(db, "SELECT * FROM feeds");
	    for(QueryResult result = yield load_query.execute_async(); !result.finished; result.next() ) {
		Feed f = new Feed.from_db(result);
		//yield loadFeedItems(f, -1, -1, true);
		feed_list.add(f);
	    }
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error loading feed data: %s\n", e.message);
	}
	
	return feed_list;
    }
	
    public async void loadFeedItems(Feed feed, int item_count = -1, int starting_id = -1) {
	try {
	    Query load_query = new Query(db, "SELECT * FROM entries WHERE `feed_id` = :id ORDER BY savedate DESC LIMIT :count");
	    load_query[":id"] = feed.id;
	    load_query[":count"] = item_count;
	    
	    for ( QueryResult result = yield load_query.execute_async(); !result.finished; result.next() ) {
		feed.add_item(new Item.from_db(result));
	    }
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error loading item data: %s\n", e.message);
	}
    }

    public async void saveFeed(Feed feed, bool save_items = true) {
	try {
	    Query save_query = new Query(db, "INSERT INTO feeds (id, title, link, description, origin, last_guid, last_time) VALUES (:id, :title, :link, :description, :origin, :last_guid, :last_time)");
	    save_query[":id"] = feed.id;
	    save_query[":title"] = feed.title;
	    save_query[":link"] = feed.link;
	    save_query[":description"] = feed.description;
	    save_query[":origin"] = feed.origin_link;
	    save_query[":last_guid"] = feed.last_guid;
	    save_query[":last_time"] = feed.last_time.to_unix();
	    yield save_query.execute_async();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error saving feed data: %s\n", e.message);
	}
	if(save_items) {
	    yield saveFeedItems(feed, feed.items);
	}
    }

    public async void saveFeedItems(Feed feed, Gee.ArrayList<Item> items) {
	try {
	    Query update_query = new Query(db, "UPDATE feeds SET last_guid = :last_guid, last_time = :last_time WHERE id = :id");
	    update_query[":last_guid"] = feed.last_guid;
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

    public async void saveItem(Item item, int feed_id) {
	try {
	    Query test_query = new Query(db, "SELECT * FROM entries WHERE `feed_id` = :id AND `guid` = :guid");
	    test_query[":id"] = feed_id;
	    test_query[":guid"] = item.guid;
	    QueryResult test_result = yield test_query.execute_async();
	    if(!test_result.finished) {
		stderr.printf("Item <%s> already exists!\n", item.guid);
		return;
	    }

	    //stderr.printf("Test succeeded. saving...\n");
	    Query save_query = new Query(db, "INSERT INTO entries (feed_id, title, link, description, author, guid, pubdate, unread, savedate) VALUES (:id, :title, :link, :description, :author, :guid, :pubdate, :unread, :savedate)");
	    save_query[":id"] = feed_id;
	    save_query[":title"] = item.title;
	    save_query[":link"] = item.link;
	    save_query[":description"] = item.description;
	    save_query[":author"] = item.author;
	    save_query[":guid"] = item.guid;
	    save_query[":pubdate"] = item.time_posted.to_unix();
	    save_query[":unread"] = item.unread ? 1 : 0;
	    save_query[":savedate"] = item.time_added.to_unix();
	    yield save_query.execute_async();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error saving feed data: %s\n", e.message);
	}
	//stderr.printf("done.\n");
    }

    public async void removeFeed(Feed f) {
	try {
	    Query feed_mv_query = new Query(db, "INSERT INTO feedsExpunged SELECT * FROM feeds WHERE `id` = :id");
	    feed_mv_query[":id"] = f.id;
	    yield feed_mv_query.execute_async();

	    Query entry_mv_query = new Query(db, "INSERT INTO entriesExpunged SELECT * FROM entries WHERE `feed_id` = :id");
	    entry_mv_query[":id"] = f.id;
	    yield entry_mv_query.execute_async();
	    
	    Query feed_rm_query = new Query(db, "DELETE FROM feeds WHERE `id` = :id");
	    feed_rm_query[":id"] = f.id;
	    yield feed_rm_query.execute_async();
	    
	    Query item_rm_query = new Query(db, "DELETE FROM entries WHERE `feed_id` = :id");
	    item_rm_query[":id"] = f.id;
	    yield item_rm_query.execute_async();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error deleting feed: %s\n", e.message);
	}
    }

    public void clearExpunged() {
	try {
	    Query ex_rmf = new Query(db, "DELETE FROM feedsExpunged");
	    Query ex_rme = new Query(db, "DELETE FROM entriesExpunged");
	    ex_rmf.execute();
	    ex_rme.execute();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error clearing expunged feeds: %s\n", e.message);
	}
    }

    public async void updateUnread(Feed feed, Gee.ArrayList<Item> items) {
	//stderr.printf("Updating unread... ");
	foreach(Item item in items) {
	    try {
		Query save_query = new Query(db, "UPDATE entries SET unread = :unread WHERE guid = :guid");
		save_query[":guid"] = item.guid;
		save_query[":unread"] = item.unread ? 1 : 0;
		yield save_query.execute_async();
	    } catch(SQLHeavy.Error e) {
		stderr.printf("Error saving feed data: %s\n", e.message);
	    }
	}
	//stderr.printf("done. %d\n", feed.id);
    }

    public async void removeOld() {
	try {
	    DateTime cutoff = new DateTime.now_utc().add_months(-1);
	    Query rm_query = new Query(db, "DELETE FROM entries WHERE savedate < :cutoff");
	    rm_query[":cutoff"] = cutoff.to_unix();
	    yield rm_query.execute_async();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error clearing old items: %s", e.message);
	}
    }
}
