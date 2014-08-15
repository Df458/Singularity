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
				feed_list.add(new Feed.from_db(result));
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

	public async void saveFeed(Feed feed) {
	    try {
		Query save_query = new Query(db, "INSERT INTO feeds (id, title, link, description) VALUES (:id, :title, :link, :description)");
		save_query[":id"] = feed.id;
		save_query[":title"] = feed.title;
		save_query[":link"] = feed.link;
		save_query[":description"] = feed.description;
		yield save_query.execute_async();
	    } catch(SQLHeavy.Error e) {
		stderr.printf("Error aving feed data: %s\n", e.message);
	    }
	}
}
