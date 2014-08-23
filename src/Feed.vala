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
	while(node != null && node->name != "rss")
	    node = node->next;
	if(node == null)
	    return;
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
				if(!add_item(new Item.from_xml(dat))) {
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
		    if(!add_item(new Item.from_xml(dat), true))
			return;
		}
	    }
	}

	app.updateFeedItems(this);

	stderr.printf("Saving %d items to the database...", _items_holding.size);
	yield man.saveFeedItems(this, _items_holding);
	stderr.printf("done.\n");
	_items_holding.clear();
    }

    public Item get(int id) {
	return _items[id];
    }
    
    public bool add_item(Item new_item, bool hold = false) {
	stdout.printf("Adding Item...\n");
	foreach(Item i in _items)
	    if(i.guid == new_item.guid)
		return false;
	if(hold)
	    _items_holding.add(new_item);
	if(new_item.unread)
	    _items_unread.add(new_item);
	_items.add(new_item);
	return true;
    }
    
    public Item get_item(int id = 0) {
	return _items[id];
    }

    public string constructHtml(DatabaseManager man) {
	string html_string = "<div>";
	foreach(Item i in _items) {
	    html_string += i.constructHtml();
	    i.unread = false;
	}
	html_string += "</div>";
	man.updateUnread.begin(this, _items_unread);
	_items_unread.clear();
	return html_string;
    }

    public string constructUnreadHtml(DatabaseManager man) {
	string html_string = "";
	foreach(Item i in _items) {
	    if(i.unread == true)
		html_string += i.constructHtml();
	    i.unread = false;
	}
	man.updateUnread.begin(this, _items_unread);
	_items_unread.clear();
	return html_string;
    }
}
