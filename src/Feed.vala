public class Feed {
    private int _id;
    private Gee.ArrayList<Item> _items;
    
    public int id   { get { return _id; } } //Databse entry id
    public string title       { get; set; } //Feed title
    public string link        { get; set; } //Feed link
    public string origin_link        { get; set; } //Feed origin
    public string description { get; set; } //Feed description
    public int item_count { get { return _items.size;  } } //
    public int unread_count { get { int res = 0; foreach(Item i in _items) if(i.unread) res++; return res; } }
    
    public Feed.from_db(SQLHeavy.QueryResult result) {
	_items = new Gee.ArrayList<Item>();
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

    public Feed.from_xml(Xml.Node* node, string url) {
	origin_link = url;
	_items = new Gee.ArrayList<Item>();
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
		    if(!add_item(new Item.from_xml(dat)))
			return;
		}
	    }
	}

	yield man.saveFeedItems(this);
    }

    public Item get(int id) {
	return _items[id];
    }
    
    public bool add_item(Item new_item) {
	stdout.printf("Adding Item...\n");
	foreach(Item i in _items)
	    if(i.guid == new_item.guid)
		return false;
	_items.add(new_item);
	return true;
    }
    
    public Item get_item(int id = 0) {
	return _items[id];
    }

    public string constructHtml() {
	string html_string = "<html><body>";
	foreach(Item i in _items) {
	    html_string += i.constructHtml();
	}
	html_string += "</body></html>";
	return html_string;
    }
}
