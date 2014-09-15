//:TODO: 05.09.14 08:11:23, Hugues Ross
// Add a full implementation of the various feed standards
public class Feed {
    private int _id;
    private Gee.ArrayList<Item> _items;
    private Gee.ArrayList<Item> _items_unread;
    private Gee.ArrayList<Item> _items_holding;
    private string _last_guid;
    private string _last_guid_post;
    private DateTime _last_time = new DateTime.from_unix_utc(0);
    private DateTime _last_time_post = new DateTime.from_unix_utc(0);
    
    public Gee.ArrayList<Item> items { get { return _items; } }

    public int id   { get { return _id; } } //Databse entry id
    public string title       { get; set; } //Feed title
    public string link        { get; set; } //Feed link
    public string origin_link        { get; set; } //Feed origin
    public string description { get; set; } //Feed description
//:TODO: 08.09.14 07:28:34, Hugues Ross
// Move the Pixbuf to MainWindow
    //public Gdk.Pixbuf image { get; set; } //Feed Image
    public string image_uri { get; set; }
    public string image_title { get; set; }
    public string image_link { get; set; }
    public string last_guid { get { return _last_guid; } }
    public DateTime last_time { get{ return _last_time; } }

    public int item_count { get { return _items.size;  } } //
    public int unread_count { get { return _items_unread.size; } }

    public int status = 0; //0:standby 1:download 2:success 3:failure
    
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
	    _last_guid = result.fetch_string(5);
	    _last_time = new DateTime.from_unix_utc(result.fetch_int(6));
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

	while(node != null && node->name != "rss" && node->name != "RDF" && node->name != "feed") {
	    node = node->next;
	}
	if(node == null) {
	    stderr.printf("Error: No defining node was found\n");
	    status = 3;
	    return;
	}
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
				stderr.printf("Adding item...\n");
				    if(!add_item(new Item.from_rss(dat))) {
					stderr.printf("Duplicate Item. Exiting...\n");
					return;
				    }
				break;
				
				default:
				    stderr.printf("Feed element <%s> is not currently supported.\n", dat->name);
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
	} else if(node->name == "RDF") {
	    for(; node != null; node = node->next) {
		if(node->type == Xml.ElementType.ELEMENT_NODE) {
		    for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
			if(dat->type == Xml.ElementType.ELEMENT_NODE) {
			    switch(dat->name) {
				case "channel":
				    for(Xml.Node* cdat = dat->children; cdat != null; cdat = cdat->next)
					if(cdat->type == Xml.ElementType.ELEMENT_NODE) {
					    switch(cdat->name) {
						case "title":
						    title = getNodeContents(cdat);
						break;

						case "link":
						    link = getNodeContents(cdat);
						break;

						case "description":
						    description = getNodeContents(cdat);
						break;
					    }
					}
				break;

				case "item":
				stderr.printf("Adding item...\n");
				    if(!add_item(new Item.from_rss(dat))) {
					stderr.printf("Duplicate Item. Exiting...\n");
					return;
				    }
				break;
				
				default:
				    stderr.printf("Feed element <%s> is not currently supported.\n", dat->name);
				break;
			    }
			}
		    }
		}
	    }
	}
	_last_guid = _last_guid_post;
	if(title == null)
	    title = "Untitled Feed";
    }

    public async void updateFromWeb(DatabaseManager man) {
	stdout.printf("Updating %s\n", title);
	_last_guid_post = _last_guid;
	_last_time_post = _last_time;
	status = 1;
	app.updateFeedIcons(this);
	Xml.Doc* doc = yield getXmlData(origin_link);
	Xml.Node* node = doc->get_root_element();

	while(node != null && node->name != "rss" && node->name != "RDF" && node->name != "feed")
	    node = node->next;
	if(node == null) {
	    status = 3;
	    app.updateFeedIcons(this);
	    return;
	}
	if(node->name == "rss" || node->name == "RDF") {
	    node = node->name == "rss" ? node->children : node;
	    while(node != null && node->type != Xml.ElementType.ELEMENT_NODE)
		node = node->next;
	    if(node == null) {
		stderr.printf("ERROR");
		status = 3;
		app.updateFeedIcons(this);
		return;
	    }

	    for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
		if(dat->type == Xml.ElementType.ELEMENT_NODE) {
		    if(dat->name == "item") {
			if(!this.add_item(new Item.from_rss(dat), true)) {
			    status = 0;
			    app.updateFeedIcons(this);
			    break;
			}
		    }
		}
	    }
	} else if(node->name == "feed") {
	    for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
		if(dat->type == Xml.ElementType.ELEMENT_NODE) {
		    if(dat->name == "entry") {
			if(!this.add_item(new Item.from_atom(dat), true)) {
			    status = 0;
			    app.updateFeedIcons(this);
			    break;
			}
		    }
		}
	    }
	}
	if(status != 3)
	    status = 2;
	app.updateFeedIcons(this);
	app.updateFeedItems(this);
	
	_last_guid = _last_guid_post;
	_last_time = _last_time_post;
	if(_items_holding.size != 0) {
	    yield man.saveFeedItems(this, _items_holding);
	    _items_holding.clear();
	}
    }

    public Item get(int id) {
	return _items[id];
    }
    
    public bool add_item(Item new_item, bool hold = false) {
	if(hold && (new_item.guid == _last_guid || 
	(new_item.time_added.add_months(1).compare(new DateTime.now_utc()) <= 0 && new_item.unread == false && new_item.starred == false)
	|| new_item.empty == true)) {
	    //stderr.printf("dropping %s ...\n", new_item.title);
	    return false;
	}
	foreach(Item i in _items) {
	    if(i.guid == new_item.guid) {
		return false;
	    }
	}
	if(hold == true) {
	    _items_holding.add(new_item);
	}
	if(new_item.unread == true)
	    _items_unread.add(new_item);
	if(new_item.time_posted.compare(_last_time) > 0) {
	    _last_time = new_item.time_posted;
	    _last_guid_post = new_item.guid;
	}
	new_item.feed = this;
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
	    //i.unread = false;
	}
	html_string += "</div>";
	//man.updateUnread.begin(this, _items_unread, () => {
	    //_items_unread.clear();
	    //app.updateFeedItems(this);
	//});
	return html_string;
    }

    public string constructUnreadHtml(DatabaseManager man) {
	string html_string = "<div class=\"feed\">";
	foreach(Item i in _items_unread) {
	    html_string += i.constructHtml();
	    //i.unread = false;
	}
	//man.updateUnread.begin(this, _items_unread, () => {
	    ////stderr.printf("%d Clear...\n", _id);
	    //_items_unread.clear();
	    //app.updateFeedItems(this);
	//});
	if(html_string == "<div class=\"feed\">")
	    return "";
	html_string += "</div>";
	return html_string;
    }

    public void removeUnreadItem(Item i) {
	_items_unread.remove(i);
    }
}
