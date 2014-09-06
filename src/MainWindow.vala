using Gtk;
using Gdk;
using Granite.Widgets;

class MainWindow : Gtk.Window {
    private HeaderBar top_bar;
    private ThinPaned content_pane;
    private WebKit.WebView web_view;
    private SourceList feed_list;
    private SourceList.ExpandableItem category_all;
    private SourceList.ExpandableItem category_collection;
    private SourceList.Item unread_item;
    private SourceList.Item all_item;
    private SourceList.Item starred_item;
    private StatusBar status_bar;
    private Box content_fill;
    private Gee.ArrayList<SourceList.Item> feed_items;
    private Gdk.Pixbuf icon_download;
    private Gdk.Pixbuf icon_success;
    private Gdk.Pixbuf icon_failure;

    private AddPopupWindow add_win;

    public MainWindow() {
	feed_items = new Gee.ArrayList<SourceList.Item>();
	window_position = WindowPosition.CENTER;
	set_default_size(800, 600);

	top_bar = new HeaderBar();
	top_bar.set_title("Singularity");
	top_bar.set_subtitle("You have no subscriptions");
	top_bar.set_show_close_button(true);
	set_titlebar(top_bar);

	content_fill = new Box(Orientation.VERTICAL, 0);
	this.add(content_fill);

	content_pane = new ThinPaned();
	content_fill.add(content_pane);

	add_win = new AddPopupWindow(this);

	Button add_button = new Button.from_icon_name("add", IconSize.MENU);
	Button rm_button = new Button.from_icon_name("remove", IconSize.MENU);
	rm_button.set_sensitive(false);
	rm_button.clicked.connect((ev) => {
	    var f = feed_list.selected;
	    app.removeFeed(feed_items.index_of(f));
	    category_all.remove(f);
	    feed_items.remove(f);
	    if(feed_items.size > 1) {
		top_bar.set_subtitle("You have " + feed_items.size.to_string() + " subscriptions");
	    } else if(feed_items.size == 1) {
		top_bar.set_subtitle("You have 1 subscription");
	    } else {
		top_bar.set_subtitle("You have no subscriptions");
	    }
	});
	add_button.clicked.connect((ev) => {
	    add_win.show_all();
	});
	status_bar = new StatusBar();
	//status_bar.set_text("Test Text");
	status_bar.insert_widget(add_button, true);
	status_bar.insert_widget(rm_button, true);
	content_fill.add(status_bar);

	feed_list = new SourceList();
	category_collection = new SourceList.ExpandableItem("Collections");
	unread_item = new SourceList.Item("Unread");
	all_item = new SourceList.Item("All");
	starred_item = new SourceList.Item("Starred");
	category_collection.add(all_item);
	category_collection.add(unread_item);
//:TODO: 30.08.14 13:58:34, Hugues Ross
// Add starred collections
	//category_collection.add(starred_item);
	category_all = new SourceList.ExpandableItem("Subscriptions");
	feed_list.root.add(category_collection);
	feed_list.root.add(category_all);
	feed_list.root.expand_all();
	content_pane.pack1(feed_list, false, false);
	starred_item.badge = "0";
	feed_list.item_selected.connect((item) => {
	    rm_button.set_sensitive(false);
	    if(item == unread_item)
		web_view.load_html(app.constructUnreadHtml(), "");
	    else if(item == all_item)
		web_view.load_html(app.constructAllHtml(), "");
	    else if(item == starred_item)
		web_view.load_html(app.constructStarredHtml(), "");
	    else {
		if(feed_items.index_of(item) < 0)
		    return;
		web_view.load_html(app.constructFeedHtml(feed_items.index_of(item)), "");
		rm_button.set_sensitive(true);
	    }
	});

	web_view = new WebKit.WebView();
	WebKit.Settings view_settings = new WebKit.Settings();
	web_view.set_settings(view_settings);
//Prevent context menu from being displayed
	web_view.context_menu.connect(()=>{
	    return true;
	});

//:TODO: 06.09.14 08:28:12, Hugues Ross
// Open link in browser if the user clicked it
	//web_view.decide_policy.connect((decision, type) => {
	    //if(type == WebKit.PolicyDecisionType.NAVIGATION_ACTION) {
		//WebKit.NavigationPolicyDecision nav_dec = (WebKit.NavigationPolicyDecision) decision;
		//try {
		    //GLib.Process.spawn_command_line_async("xdg-open " + nav_dec.get_navigation_action().get_request().uri);
		//} catch(Error e) {
		    //stderr.printf(e.message);
		//}
		//return true;
	    //}
	    //return false;
	//});
	ScrolledWindow scroll = new ScrolledWindow(null, null);
	scroll.add(web_view);
	content_pane.add2(scroll);

	this.destroy.connect(() => {
	    Gtk.main_quit();
	});
	try {
	    icon_download = new Pixbuf.from_file(Environment.get_user_data_dir() + "/singularity-test/emblem_download.png");
	    icon_failure = new Pixbuf.from_file(Environment.get_user_data_dir() + "/singularity-test/emblem_failure.png");
	    icon_success = new Pixbuf.from_file(Environment.get_user_data_dir() + "/singularity-test/emblem_success.png");
	} catch(Error e) {
	    stderr.printf(e.message);
	}
	this.show_all();
    }

    public void add_feeds(Gee.ArrayList<Feed> feeds) {
	foreach(Feed f in feeds) {
	    add_feed(f);
	}
    }

    public void add_feed(Feed f) {
	SourceList.Item feed_item = new SourceList.Item(f.title);
	feed_item.badge = f.unread_count.to_string();
	category_all.add(feed_item);
	unread_item.badge = (int.parse(unread_item.badge) + f.unread_count).to_string();
	feed_items.add(feed_item);
	if(feed_items.size > 1) {
	    top_bar.set_subtitle("You have " + feed_items.size.to_string() + " subscriptions");
	} else {
	    top_bar.set_subtitle("You have 1 subscription");
	}
    }

    public void updateFeedItem(Feed f, int index) {
	int unread_diff = f.unread_count - int.parse(feed_items[index].badge);
	unread_item.badge = (int.parse(unread_item.badge) + unread_diff).to_string();
	feed_items[index].badge = f.unread_count.to_string();
    }

    public void updateFeedIcon(int index, int icon) {
	switch(icon) {
	    case 0:
		feed_items[index].icon = null;
	    break;
	    case 1:
		feed_items[index].icon = icon_download;
	    break;
	    case 2:
		feed_items[index].icon = icon_success;
	    break;
	    case 3:
		feed_items[index].icon = icon_failure;
	    break;
	}
    }
}
