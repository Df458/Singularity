public class Feed {
	private int _id;
	private Gee.ArrayList<Item> _items;
	
	public int id   { get { return _id; } } //Databse entry id
	public string title       { get; set; } //Feed title
	public string link        { get; set; } //Feed link
	public string description { get; set; } //Feed description
	public int item_count {get { return _items.size;  } } //
	
	public Feed.from_db(SQLHeavy.QueryResult result) {
		_items = new Gee.ArrayList<Item>();
		try {
			_id = result.fetch_int(0);
			title = result.fetch_string(1);
			link = result.fetch_string(2);
			description = result.fetch_string(3);
		} catch(SQLHeavy.Error e) {
			stderr.printf("Error loading feed data: %s\n", e.message);
			return;
		}
	}

	public Feed.from_xml(Xml.Node* node) {
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
				    add_item(new Item.from_xml(dat));
				break;
				
				default:
				    stderr.printf("Element <%s> is not currently supported.\n", dat->name);
				break;
			    }
			}
		    }
		}
	    }
	}

	public Item get(int id) {
	    return _items[id];
	}
	
	public void add_item(Item new_item) {
		stdout.printf("Adding Item...\n");
		_items.add(new_item);
	}
	
	public Item get_item(int id = 0) {
		return _items[id];
	}
}
