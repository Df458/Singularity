public class Item {
	private string _guid;
	private DateTime _time_posted;
	private DateTime _time_added;

	public string title       { get; set; } //Item title
	public string link        { get; set; } //Item link
	public string description { get; set; } //Item description
	public string guid { get { return _guid; } } //Unique identifier
	public bool unread = false;
	public DateTime time_posted { get { return _time_posted; } }
	public DateTime time_added  { get { return _time_added;  } }
	
	public Item.from_db(SQLHeavy.QueryResult result) {
	    try {
		title = result.fetch_string(1);
		link = result.fetch_string(2);
		description = result.fetch_string(3);
		_guid = result.fetch_string(8);
		stdout.printf("%d\n", result.fetch_int(11));
		if(result.fetch_int(11) == 1) {
		    unread = true;
		}
	    } catch(SQLHeavy.Error e) {
		stderr.printf("Error loading feed data: %s\n", e.message);
		return;
	    }
	}

    public Item.from_xml(Xml.Node* node) {
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

		    case "guid":
			_guid = getNodeContents(dat);
		    break;
		    
		    default:
			//stderr.printf("Element <%s> is not currently supported.\n", dat->name);
		    break;
		}
	    }
	}
	unread = true;
    }

    public string constructHtml() {
	string html_string = "<a href=" + link + "><h3>" + title + "</h3></a>\n" + description + "<br/>";
	return html_string;
    }
}
