public class Item {
	private string _guid;
	private DateTime _time_posted;
	private DateTime _time_added;

	public string title       { get; set; } //Item title
	public string link        { get; set; } //Item link
	public string description { get; set; } //Item description
	public string author      { get; set; } //Item author
	public string guid { get { return _guid; } } //Unique identifier
	public bool unread = false;
	public DateTime time_posted { get { return _time_posted; } }
	public DateTime time_added  { get { return _time_added;  } }
	
	public Item.from_db(SQLHeavy.QueryResult result) {
	    try {
		title = result.fetch_string(1);
		link = result.fetch_string(2);
		description = result.fetch_string(3);
		author = result.fetch_string(4);
		_guid = result.fetch_string(8);
		_time_posted = new DateTime.from_unix_utc(result.fetch_int(9));
		stdout.printf("%d\n", result.fetch_int(11));
		if(result.fetch_int(11) == 1) {
		    unread = true;
		}
		_time_added = new DateTime.from_unix_utc(result.fetch_int(12));
	    } catch(SQLHeavy.Error e) {
		stderr.printf("Error loading feed data: %s\n", e.message);
		return;
	    }
	}

    public Item.from_xml(Xml.Node* node) {
	_time_added = new DateTime.now_utc();
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

		    case "pubDate":
			string[] date_strs = getNodeContents(dat).split(" ");
			string[] time_strs = date_strs[4].split(":");
			_time_posted = new DateTime.utc(int.parse(date_strs[3]), getMonth(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
		    break;

		    case "author":
			author = getNodeContents(dat);
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
