public class Item {
    private string _guid = "";
    private DateTime _time_posted = new DateTime.from_unix_utc(0);
    private DateTime _time_added = new DateTime.now_utc();

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
	    if(result.fetch_int(11) == 1) {
		unread = true;
	    }
	    _time_added = new DateTime.from_unix_utc(result.fetch_int(12));
	} catch(SQLHeavy.Error e) {
	    stderr.printf("Error loading feed data: %s\n", e.message);
	    return;
	}
    }

    public Item.from_rss(Xml.Node* node) {
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
	if(_guid == "") {
	    _guid = link;
	}
    }

    public Item.from_atom(Xml.Node* node) {
	_time_added = new DateTime.now_utc();
	for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
	    if(dat->type == Xml.ElementType.ELEMENT_NODE) {
		stderr.printf("Opening <%s>...", dat->name);
		switch(dat->name) {
		    case "title":
			title = getNodeContents(dat, true);
		    break;

		    case "link":
			if(dat->has_prop("rel") != null && dat->has_prop("rel")->children->content == "alternate") {
			    link = dat->has_prop("href")->children->content;
			    stderr.printf(dat->has_prop("href")->children->content);
			}
		    break;

		    case "content":
			description = getNodeContents(dat, true);
		    break;

		    case "id":
			_guid = getNodeContents(dat, true);
		    break;

		    case "updated": 
			string[] big_strs = getNodeContents(dat).split("T");
			string[] date_strs = big_strs[0].split("-");
			string[] time_strs = big_strs[1].split(":");
			_time_posted = new DateTime.utc(int.parse(date_strs[0]), int.parse(date_strs[1]), int.parse(date_strs[2]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
		    break;

		    case "author":
			for(Xml.Node* a = dat->children; a != null; a = a->next)
			    if(a->name == "name")
				author = getNodeContents(a, true);
		    break;
		    
		    default:
			//stderr.printf("Element <%s> is not currently supported.\n", dat->name);
		    break;
		}
		    stderr.printf("done\n");
	    }
	}
	unread = true;
	if(_guid == "")
	    _guid = link;
    }

    public string constructHtml() {
	string html_string = "<div class=\"item\"><div class=\"item-head\"><a href=" + link + "><h3>" + title + "</h3></a>\n";
	html_string += "<p>Posted";
	if(author != "")
	    html_string += " by " + author;
	if(_time_posted != new DateTime.from_unix_utc(0))
	    html_string += " on " + _time_posted.to_string();
	html_string += "</div><br/><div class=\"item-content\">" + description + "<br/></div></div>";
	return html_string;
    }
}
