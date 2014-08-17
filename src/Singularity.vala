using Gee;

class Singularity {
    private ArrayList<Feed> feeds;
    private DatabaseManager db_man;
    private MainWindow main_window;

    public Singularity(string db_path) {
	db_man = new DatabaseManager.from_path(db_path);
	db_man.loadFeeds.begin((obj, res) =>{
	    feeds = db_man.loadFeeds.end(res);
	    stdout.printf("Finished loading feeds.\n");
	    main_window.add_feeds(feeds);
	    foreach(Feed f in feeds) {
		db_man.loadFeedItems.begin(f, -1, -1, (obj, res) => {
		    db_man.loadFeedItems.end(res);
		    f.updateFromWeb.begin(db_man);
		    main_window.updateFeedItem(f, feeds.index_of(f));
		});
	    }
	});
	main_window = new MainWindow();
    }

    public string constructFeedHtml(int feed_id) {
	return feeds[feed_id].constructHtml();
    }

    public string constructUnreadHtml() {
	return "<html><body><p>Unread view not implemented yet.</p></body></html>";
    }

    public string constructAllHtml() {
	return "<html><body><p>Full view not implemented yet.</p></body></html>";
    }

    public string constructStarredHtml() {
	return "<html><body><p>Starred view not implemented yet.</p></body></html>";
    }

    public int run() {
	Gtk.main();
	return 0;
    }
}
