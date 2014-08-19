using SQLHeavy;

public class DatabaseManager {
    private Database db;
    private bool _open = false;
    
    public bool open { get { return _open; } }
    
    public DatabaseManager.from_path(string location) {
	try {
	    db = new Database(location, FileMode.READ | FileMode.WRITE | FileMode.CREATE);
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
	    Query load_query = new Query(db, "SELECT * FROM entries WHERE `feed_id` = :id ORDER BY rowid DESC LIMIT :count");
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
	    Query save_query = new Query(db, "INSERT INTO feeds (id, title, link, description) VALUES (:id, :title, :link, :description)");
	    save_query[":id"] = feed.id;
	    save_query[":title"] = feed.title;
	    save_query[":link"] = feed.link;
	    save_query[":description"] = feed.description;
	    yield save_query.execute_async();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error saving feed data: %s\n", e.message);
	}
	if(save_items) {
	    yield saveFeedItems(feed);
	}
    }

    public async void saveFeedItems(Feed feed) {
	for(int i = 0; i < feed.item_count; ++i) {
	    yield saveItem(feed[i], feed.id);
	}
    }

    public async void saveItem(Item item, int feed_id) {
	try {
	    Query test_query = new Query(db, "SELECT * FROM entries WHERE `feed_id` = :id AND `guid` = :guid");
	    test_query[":id"] = feed_id;
	    test_query[":guid"] = item.guid;
	    QueryResult test_result = yield test_query.execute_async();
	    if(!test_result.finished) {
		//stderr.printf("Item <%s> already exists!\n", item.guid);
		return;
	    }

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
    }

    public async void removeFeed(Feed f) {
	try {
	    // TODO: Save items to expunged table, delete expunged on application end
	    Query feed_mv_query = new Query(db, "INSERT INTO expungedf SELECT * FROM feeds WHERE `id` = :id");
	    feed_mv_query[":id"] = f.id;
	    yield feed_mv_query.execute_async();

	    Query entry_mv_query = new Query(db, "INSERT INTO expungede SELECT * FROM entries WHERE `feed_id` = :id");
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
	    Query ex_rmf = new Query(db, "DELETE FROM expungedf");
	    Query ex_rme = new Query(db, "DELETE FROM expungede");
	    ex_rmf.execute();
	    ex_rme.execute();
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error clearing expunged feeds: %s\n", e.message);
	}
    }
}
