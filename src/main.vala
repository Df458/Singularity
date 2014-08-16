using Gee;

public static int main (string[] args){
    Gtk.init(ref args);
    DatabaseManager manager = new DatabaseManager.from_path("test.db");
    Gee.ArrayList<Feed> feed_list = new Gee.ArrayList<Feed>();
    //manager.loadFeeds.begin((obj, res) => {
	//stdout.printf("Loaded\n");
	//feed_list = manager.loadFeeds.end(res);
	//stdout.printf("%d: %s <%s>\n\"%s\"\n", feed_list[0].id, feed_list[0].title, feed_list[0].link, feed_list[0].description);
	//manager.loadFeedItems(feed_list[0]);
	//Item item = feed_list[0].get_item();
	//stdout.printf("%s: %s <%s>\n\"%s\"\n", item.guid, item.title, item.link, item.description);
    //});
    getXmlData.begin("http://df458.blogspot.com/feeds/posts/default?alt=rss", (obj, res) => {
	Xml.Doc* doc = getXmlData.end(res);
	if(doc == null)
	    stderr.printf("Error: doc is null\n");
	Feed testfeed = new Feed.from_xml(doc->get_root_element());
	stdout.printf("%d: %s <%s>\n\"%s\"\n", testfeed.id, testfeed.title, testfeed.link, testfeed.description);
	Item item = testfeed.get_item();
	stdout.printf("%s: %s <%s>\n\"%s\"\n", item.guid, item.title, item.link, item.description);
	manager.saveFeed.begin(testfeed, true, (obj, res) => {
	    manager.saveFeed.end(res);
	    stdout.printf("Save Completed.\n");
	});
	delete doc;
    });
    stdout.printf("Loading...\n");
    Gtk.main();
    return 0;
}
