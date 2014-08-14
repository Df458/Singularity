using Gee;

public static int main (string[] args){
	//Gtk.init(ref args);
	DatabaseManager manager = new DatabaseManager.from_path("test.db");
	Gee.ArrayList<Feed> feed_list = manager.loadFeeds();
	stdout.printf("%d: %s <%s>\n\"%s\"\n", feed_list[0].id, feed_list[0].title, feed_list[0].link, feed_list[0].description);
	manager.loadFeedItems(feed_list[0]);
	Item item = feed_list[0].get_item();
	stdout.printf("%s: %s <%s>\n\"%s\"\n", item.guid, item.title, item.link, item.description);
	return 0;
}
