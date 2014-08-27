// TODO: Implement Feed Image stuff

public class Feed {
    private int _id;
    private Gee.ArrayList<Item> _items;
    private Gee.ArrayList<Item> _items_unread;
    private Gee.ArrayList<Item> _items_holding;
    
    public Gee.ArrayList<Item> items { get { return _items; } }

    public int id   { get { return _id; } } //Databse entry id
    public string title       { get; set; } //Feed title
    public string link        { get; set; } //Feed link
    public string origin_link        { get; set; } //Feed origin
    public string description { get; set; } //Feed description
    public Gdk.Pixbuf image { get; set; } //Feed Image
    public string image_title { get; set; }
    public string image_link { get; set; }

    public int item_count { get { return _items.size;  } } //
    public int unread_count { get { return _items_unread.size; } }
    
    public Feed.from_db(SQLHeavy.QueryResult result) {
	_items = new Gee.ArrayList<Item>();
	_items_unread = new Gee.ArrayList<Item>();
	_items_holding = new Gee.ArrayList<Item>();
	try {
	    _id = result.fetch_int(0);
	    title = result.fetch_string(1);
	    link = result.fetch_string(2);
	    description = result.fetch_string(3);
	    origin_link = result.fetch_string(4);
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error loading feed data: %s\n", e.message);
	    return;
	}
    }

    public Feed.from_xml(Xml.Node* node, string url, int new_id = -1) {
	_id = new_id;
	origin_link = url;
	_items = new Gee.ArrayList<Item>();
	_items_unread = new Gee.ArrayList<Item>();
	_items_holding = new Gee.ArrayList<Item>();
	while(node != null && node->name != "rss" && node->name != "feed")
	    node = node->next;
	if(node == null)
	    return;
	if(node->name == "rss") {
	    for(node = node->children; node != null; node = node->next) {
		if(node->type == Xml.ElementType.ELEMENT_NODE) {
		    for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
			if(dat->type == Xml.ElementType.ELEMENT_NODE) {
			    switch(dat->name) {
				case "title":
				    title = getNodeContents(dat);
				break;

				case "link":
				    link = getNodeContents(dat);
				break;

				case "description":
				    description = getNodeContents(dat);
				break;

				case "item":
				    if(!add_item(new Item.from_rss(dat))) {
					stdout.printf("Duplicate Item. Exiting...\n");
					return;
				    }
				break;
				
				default:
				    //stderr.printf("Element <%s> is not currently supported.\n", dat->name);
				break;
			    }
			}
		    }
		}
	    }
	} else if(node->name == "feed") {
	    for(node = node->children; node != null; node = node->next) {
		if(node->type == Xml.ElementType.ELEMENT_NODE) {
		    stderr.printf("Opening <%s>...", node->name);
		    switch(node->name) {
			case "title":
			    title = getNodeContents(node, true);
			break;

			case "link":
			    if(node->has_prop("rel") != null && node->has_prop("rel")->children->content == "alternate")
				link = node->has_prop("href")->children->content;
			break;

			case "description":
			    description = getNodeContents(node, true);
			break;

			case "entry":
			    if(!add_item(new Item.from_atom(node))) {
				stdout.printf("Duplicate Item. Exiting...\n");
				return;
			    }
			break;
			
			default:
			    //stderr.printf("Element <%s> is not currently supported.\n", node->name);
			break;
		    }
		    stderr.printf("done\n");
		}
	    }
	}
    }

    public async void updateFromWeb(DatabaseManager man) {
	Xml.Doc* doc = yield getXmlData(origin_link);
	Xml.Node* node = doc->get_root_element();

	while(node != null && node->name != "rss")
	    node = node->next;
	if(node == null)
	    return;
	node = node->children;
	for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
	    if(dat->type == Xml.ElementType.ELEMENT_NODE) {
		if(dat->name == "item") {
		    if(!this.add_item(new Item.from_rss(dat), true))
			break;
		}
	    }
	}

	app.updateFeedItems(this);

	stderr.printf("Saving %d items to the database(%d)...", _items_holding.size, _id);
	yield man.saveFeedItems(this, _items_holding);
	stderr.printf("done.\n");
	_items_holding.clear();
    }

    public Item get(int id) {
	return _items[id];
    }
    
    public bool add_item(Item new_item, bool hold = false) {
	//stdout.printf("Adding Item...\n");
	foreach(Item i in _items)
	    if(i.guid == new_item.guid)
		return false;
	//stdout.printf("Item check passed.\n");
	if(hold == true) {
	    stdout.printf("Holding...\n");
	    _items_holding.add(new_item);
	}
	if(new_item.unread == true)
	    _items_unread.add(new_item);
	_items.add(new_item);
	return true;
    }
    
    public Item get_item(int id = 0) {
	return _items[id];
    }

    public string constructHtml(DatabaseManager man) {
	string html_string = "<div class=\"feed\">";
	foreach(Item i in _items) {
	    html_string += i.constructHtml();
	    i.unread = false;
	}
	html_string += "</div>";
	man.updateUnread.begin(this, _items_unread, () => {
	    _items_unread.clear();
	    app.updateFeedItems(this);
	});
	return html_string;
    }

    public string constructUnreadHtml(DatabaseManager man) {
	string html_string = "<div class=\"feed\">";
	foreach(Item i in _items_unread) {
	    html_string += i.constructHtml();
	    i.unread = false;
	}
	man.updateUnread.begin(this, _items_unread, () => {
	    stderr.printf("%d Clear...\n", _id);
	    _items_unread.clear();
	    app.updateFeedItems(this);
	});
	html_string += "</div>";
	return html_string;
    }
}
