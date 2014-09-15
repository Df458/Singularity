using Gee;
//:TODO: 27.08.14 11:26:14, Hugues Ross
// Update feeds periodically
class Singularity {
//:TODO: 27.08.14 15:35:13, Hugues Ross
// Add a variable for auto-delete time
    private ArrayList<Feed> feeds;
    private DatabaseManager db_man;
    private MainWindow main_window;
    string css_path;
    string css_dat = "";
    private ArrayList<Item> view_list;
    string js_str = "<script>function isElementInViewport (el) {
	    var rect = el.getBoundingClientRect();

	    return (
		rect.top <= window.innerHeight / 2 ||
		rect.bottom <= window.innerHeight
	    );
    }

    function callback (el, id) {
	    window.location.assign('command://test/' + id);
	    //el.style.color='red'
    } 


    function fireIfElementVisible (el, id, callback) {
	    return function () {
		if ( isElementInViewport(el) && el.getAttribute('marked') != 'true' && el.getAttribute('viewed') != 'true') {
		    callback(el, id);
		    el.setAttribute('viewed', 'true');
		    el.setAttribute('marked', 'true');
		}
	    }
    }

    function swapViewed() {
	if ( el.getAttribute('viewed') == 'false') {
	    el.setAttribute('viewed', 'true');
	} else {
	    el.setAttribute('viewed', 'false');
	}
	el.setAttribute('marked', 'true');
    }

    var items = document.getElementsByClassName('item-head');
    items[0].setAttribute('marked', 'false');
    callback(items[0], 0);
    for(i = 1; i < items.length; ++i){
    var handler = fireIfElementVisible (items[i], i, callback);
    items[i].setAttribute('marked', 'false');
    addEventListener('DOMContentLoaded', handler, false);
    addEventListener('load', handler, false);
    addEventListener('scroll', handler, false);
    addEventListener('resize', handler, false);
    }</script>";

    public Singularity(string[] args) {
	Granite.Services.Paths.initialize("singularity-test", Environment.get_user_data_dir());
	Granite.Services.Paths.ensure_directory_exists(Granite.Services.Paths.user_data_folder);

	string db_path = Environment.get_user_data_dir() + "/singularity-test/test.db";
	css_path = Environment.get_user_data_dir() + "/singularity-test/test.css";
	if(args.length > 1)
	    db_path = args[1];
	if(args.length > 2)
	    css_path = args[2];
	db_man = new DatabaseManager.from_path(db_path);
	File file = File.new_for_path(css_path);
	if(!file.query_exists()) {
	    css_dat = "body {background-color: #EEEEEE;} div.feed {margin: 3%;} div.singularity-item {background-color: white; border: 1px solid #CCCCCC; border-radius: 3px; box-shadow: 0px 2px 5px #888888; margin: 12px;} div.item-head {padding: 12px;} div.item-content {padding: 12px;} img, object {max-width: 100%; height: auto;}";
	} else {
	    try {
		DataInputStream stream = new DataInputStream(file.read());
		string indat;
		while((indat = stream.read_line()) != null)
		    css_dat += indat;
	    } catch (Error e) {
		error("%s", e.message);
	    }
	}

	db_man.removeOld.begin();
	db_man.loadFeeds.begin((obj, res) =>{
	    feeds = db_man.loadFeeds.end(res);
	    stdout.printf("Finished loading feeds.\n");
	    main_window.add_feeds(feeds);
	    foreach(Feed f in feeds) {
		db_man.loadFeedItems.begin(f, -1, -1, (obj, res) => {
		    f.updateFromWeb.begin(db_man);
		});
	    }
	});
	main_window = new MainWindow();
	view_list = new ArrayList<Item>();
    }

    public string constructFeedHtml(int feed_id) {
	view_list.clear();
	string html_str = "<html><head><style>" + css_dat + "</style></head><body>" + feeds[feed_id].constructHtml(db_man) + js_str + "</body></html>";
	main_window.updateFeedItem(feeds[feed_id], feed_id);
	return html_str;
    }

    public string constructUnreadHtml() {
	view_list.clear();
	string html_str = "<html><head><style>" + css_dat + "</style></head><body><br/>";
		foreach(Feed f in feeds) {
	    html_str += f.constructUnreadHtml(db_man);
	}
	html_str += js_str + "</body></html>";
	stdout.printf(html_str);
	return html_str;
    }

    public string constructAllHtml() {
	view_list.clear();
	string html_str = "<html><head><style>" + css_dat + "</style></head><body>";
	foreach(Feed f in feeds) {
	    html_str += f.constructHtml(db_man);
	    main_window.updateFeedItem(f, feeds.index_of(f));
	}
	html_str += js_str + "</body></html>";
	return html_str;
    }

    public string constructStarredHtml() {
	view_list.clear();
	return "<html><head><style>" + css_dat + "</style></head><body><p>Starred view not implemented yet.</p></body></html>";
    }

    public void createFeed(string url) {
	getXmlData.begin(url, (obj, res) => {
	    Xml.Doc* doc = getXmlData.end(res);
	    if(doc == null || doc->get_root_element() == null) {
		stderr.printf("Error: doc is null\n");
		return;
	    }
	    Feed f = new Feed.from_xml(doc->get_root_element(), url, feeds.size);
	    if(f.status == 3)
		return;
	    db_man.saveFeed.begin(f, true);
	    feeds.add(f);
	    main_window.add_feed(f);
	    main_window.updateFeedItem(f, feeds.index_of(f));
	    delete doc;
	});
    }

    public void removeFeed(int feed_index) {
	Feed f = feeds[feed_index];
	db_man.removeFeed.begin(f);
	feeds.remove(f);
    }

    public int run() {
	Gtk.main();
	exit();
	return 0;
    }

    public void updateFeedItems(Feed f) {
	main_window.updateFeedItem(f, feeds.index_of(f));
    }

    public void updateFeedIcons(Feed f) {
	main_window.updateFeedIcon(feeds.index_of(f), f.status);
    }

    public void interpretUriEncodedAction(string action) {
	string[] args = action.split("/");
	//stderr.printf("%s: %s", args[0], view_list[int.parse(args[1])].title);
	view_list[int.parse(args[1])].unread = false;
	db_man.updateSingleUnread.begin(view_list[int.parse(args[1])], () => {
	    view_list[int.parse(args[1])].feed.removeUnreadItem(view_list[int.parse(args[1])]);
	    updateFeedItems(view_list[int.parse(args[1])].feed);
	});
    }

    public void exit() {
	stderr.printf("Clearing expunged feeds...");
	db_man.clearExpunged();
	stderr.printf("done.\n");
    }

    public void addToView(Item i) {
	view_list.add(i);
    }
}
