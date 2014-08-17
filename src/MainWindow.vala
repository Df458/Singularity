using Gtk;
using Granite.Widgets;

class MainWindow : Window {
    private HeaderBar top_bar;
    private ThinPaned content_pane;
    private WebKit.WebView web_view;
    private SourceList feed_list;
    private SourceList.ExpandableItem category_all;
    private SourceList.ExpandableItem category_collection;
    private SourceList.Item unread_item;
    private SourceList.Item all_item;
    private SourceList.Item starred_item;
    private Gee.ArrayList<SourceList.Item> feed_items;

    public MainWindow() {
	feed_items = new Gee.ArrayList<SourceList.Item>();
	window_position = WindowPosition.CENTER;

	top_bar = new HeaderBar();
	top_bar.set_title("Singularity");
	top_bar.set_subtitle("Awwwwwwww Yeeeeeaaaaaaah!");
	top_bar.set_show_close_button(true);
	set_titlebar(top_bar);

	content_pane = new ThinPaned();
	this.add(content_pane);

	feed_list = new SourceList();
	category_collection = new SourceList.ExpandableItem("Collections");
	unread_item = new SourceList.Item("Unread");
	all_item = new SourceList.Item("All");
	starred_item = new SourceList.Item("Starred");
	category_collection.add(all_item);
	category_collection.add(unread_item);
	category_collection.add(starred_item);
	category_all = new SourceList.ExpandableItem("Subscriptions");
	feed_list.root.add(category_collection);
	feed_list.root.add(category_all);
	feed_list.root.expand_all();
	content_pane.pack1(feed_list, true, false);
	starred_item.badge = "0";
	feed_list.item_selected.connect((item) => {
	    if(item == unread_item)
		web_view.load_html_string(app.constructUnreadHtml(), "");
	    else if(item == all_item)
		web_view.load_html_string(app.constructAllHtml(), "");
	    else if(item == starred_item)
		web_view.load_html_string(app.constructStarredHtml(), "");
	    else {
		web_view.load_html_string(app.constructFeedHtml(feed_items.index_of(item)), "");
	    }
	});

	web_view = new WebKit.WebView();
	WebKit.WebSettings view_settings = new WebKit.WebSettings();
	view_settings.enable_default_context_menu = false;
	web_view.set_settings(view_settings);
	ScrolledWindow scroll = new ScrolledWindow(null, null);
	scroll.add(web_view);
	content_pane.add2(scroll);

	this.destroy.connect(() => {
	    Gtk.main_quit();
	});

	this.show_all();
    }

    public void add_feeds(Gee.ArrayList<Feed> feeds) {
	foreach(Feed f in feeds) {
	    SourceList.Item feed_item = new SourceList.Item(f.title);
	    feed_item.badge = f.unread_count.to_string();
	    category_all.add(feed_item);
	    unread_item.badge = (int.parse(unread_item.badge) + f.unread_count).to_string();
	    feed_items.add(feed_item);
	}
    }

    public void updateFeedItem(Feed f, int index) {
	int unread_diff = f.unread_count + int.parse(feed_items[index].badge);
	unread_item.badge = (int.parse(unread_item.badge) + unread_diff).to_string();
	feed_items[index].badge = f.unread_count.to_string();
    }
}
