/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2014  Hugues Ross <hugues.ross@gmail.com>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// modules: webkit2gtk-4.0 libsoup-2.4 granite libxml-2.0 sqlheavy-0.1 glib-2.0 gee-0.8

//:TODO: 05.09.14 08:11:23, Hugues Ross
// Add a full implementation of the various feed standards
public class Feed {
    private int _id;
    private Gee.ArrayList<Item> _items;
    private Gee.ArrayList<Item> _items_unread;
    private Gee.ArrayList<Item> _items_starred;
    private Gee.ArrayList<Item> _items_holding;
    private string _last_guid;
    private string _last_guid_post;
    private DateTime _last_time = new DateTime.from_unix_utc(0);
    private DateTime _last_time_post = new DateTime.from_unix_utc(0);
    private bool accept_empty = false;
    
    public Gee.ArrayList<Item> items { get { return _items; } }

    public int id   { get { return _id; } } //Databse entry id
    public string title       { get; set; } //Feed title
    public string link        { get; set; } //Feed link
    public string origin_link        { get; set; } //Feed origin
    public string description { get; set; } //Feed description
    public string image_uri { get; set; }
    public string image_title { get; set; }
    public string image_link { get; set; }
    public string last_guid { get { return _last_guid; } }
    public DateTime last_time { get{ return _last_time; } }

    public int item_count { get { return _items.size;  } } //
    public int unread_count { get { return _items_unread.size; } }
    public int starred_count { get { return _items_starred.size; } }

    public int status = 0; //0:standby 1:download 2:success 3:failure
    
    public Feed.from_db(SQLHeavy.QueryResult result) {
        _items = new Gee.ArrayList<Item>();
        _items_unread = new Gee.ArrayList<Item>();
        _items_starred = new Gee.ArrayList<Item>();
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
        accept_empty = true;
        _items = new Gee.ArrayList<Item>();
        _items_unread = new Gee.ArrayList<Item>();
        _items_starred = new Gee.ArrayList<Item>();
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
                        if(!add_item(new Item.from_rss(dat))) {
                        return;
                        }
                    break;
                    
                    default:
                        //stderr.printf("Feed element <%s> is not currently supported.\n", dat->name);
                    break;
                    }
                }
                }
            }
            }
        } else if(node->name == "feed") {
            for(node = node->children; node != null; node = node->next) {
            if(node->type == Xml.ElementType.ELEMENT_NODE) {
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
                    return;
                    }
                break;
                
                default:
                    //stderr.printf("Element <%s> is not currently supported.\n", node->name);
                break;
                }
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
                        if(!add_item(new Item.from_rss(dat))) {
                        return;
                        }
                    break;
                    
                    default:
                        //stderr.printf("Feed element <%s> is not currently supported.\n", dat->name);
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
	_last_guid_post = _last_guid;
	_last_time_post = _last_time;
	status = 1;
	app.updateFeedIcons(this);
	Xml.Doc* doc = yield getXmlData(origin_link);
	Xml.Node* node = doc->get_root_element();
    accept_empty = true;

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
        if(hold && (new_item.guid == _last_guid || new_item.empty == true)) {
            return false;
        }

        bool keep = true;
        if(new_item.unread) {
            if(new_item.starred) {
                keep = new_item.applyRule(app.unread_starred_rule);
            } else {
                keep = new_item.applyRule(app.unread_unstarred_rule);
            }
        } else if(new_item.starred) {
            keep = new_item.applyRule(app.read_starred_rule);
        } else {
            keep = new_item.applyRule(app.read_unstarred_rule);
        }

        if(!keep)
            return false;

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
        if(new_item.starred == true)
            _items_starred.add(new_item);
        if(accept_empty && hold) {
            accept_empty = false;
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
        }
        html_string += "</div>";
        return html_string;
    }

    public string constructUnreadHtml(DatabaseManager man) {
        string html_string = "<div class=\"feed\">";
        foreach(Item i in _items_unread) {
            html_string += i.constructHtml();
        }
        if(html_string == "<div class=\"feed\">")
            return "";
        html_string += "</div>";
        return html_string;
    }

    public string constructStarredHtml(DatabaseManager man) {
        string html_string = "<div class=\"feed\">";
        foreach(Item i in _items_starred) {
            html_string += i.constructHtml();
        }
        if(html_string == "<div class=\"feed\">")
            return "";
        html_string += "</div>";
        return html_string;
    }

    public void removeUnreadItem(Item i) {
        _items_unread.remove(i);
    }
}
