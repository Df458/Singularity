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

namespace Singularity
{
//:TODO: 05.09.14 08:11:23, Hugues Ross
// Add a full implementation of the various feed standards
public class Feed : DataEntry
{
    public Feed()
    {
        warn("stub!");
    }

    public Feed.from_record(SQLHeavy.Record r)
    {
        base.from_record(r);
        warn("stub!");
    }

    public bool insert()
    {
        warn("stub!");
    }

    public bool update()
    {
        warn("stub!");
    }

    public bool remove()
    {
        warn("stub!");
    }
/*     private int _id; */
/*     private Gee.ArrayList<Item> _items; */
/*     private Gee.ArrayList<Item> _items_unread; */
/*     private Gee.ArrayList<Item> _items_starred; */
/*     private Gee.ArrayList<Item> _items_holding; */
/*     //private string _last_guid; */
/*     //private string _last_guid_post; */
/*     private Gee.ArrayList<string> _last_guids; */
/*     private Gee.ArrayList<string> _last_guids_post; */
/*     private DateTime _last_time = new DateTime.from_unix_utc(0); */
/*     private DateTime _last_time_post = new DateTime.from_unix_utc(0); */
/*     private bool accept_empty = false; */
/*      */
/*     public Gee.ArrayList<Item> items { get { return _items; } } */
/*  */
/*     public int id   { get { return _id; } } //Database entry id */
/*     public int parent_id = -1; */
/*     public string title = "Untitled Feed"; //Feed title */
/*     public string link        { get; set; } //Feed link */
/*     public string origin_link { get; set; } //Feed origin */
/*     public string description { get; set; } //Feed description */
/*     public string image_uri { get; set; } */
/*     public string image_title { get; set; } */
/*     public string image_link { get; set; } */
/*     //public string last_guid { get { return _last_guid; } } */
/*     public DateTime last_time { get{ return _last_time; } } */
/*  */
/*     public int item_count { get { return _items.size;  } } // */
/*     public int unread_count { get { return _items_unread.size; } } */
/*     public int starred_count { get { return _items_starred.size; } } */
/*  */
/*     public int status = 0; //0:standby 1:download 2:success 3:failure */
/*  */
/* //-Custom Settings------------------------------------------------------------- */
/*  */
/*     //Count, Increment(m,h,d,m,y), action(nothing,read/unread,star/unstar,delete) */
/*     public bool override_rules = false; */
/*     public int[] unread_rule = {0, 0, 0}; //1 week, read */
/*     public int[] read_rule   = {0, 0, 0}; //1 month, delete */
/*  */
/*     public bool override_location = false; */
/*     public bool get_location = true; */
/*     public string default_location; */
/*      */
/*     public Feed(int new_id = -1) */
/*     { */
/*         _id = new_id; */
/*         _last_guids = new Gee.ArrayList<string>(); */
/*         _last_guids_post = new Gee.ArrayList<string>(); */
/*         _items = new Gee.ArrayList<Item>(); */
/*         _items_unread = new Gee.ArrayList<Item>(); */
/*         _items_starred = new Gee.ArrayList<Item>(); */
/*         _items_holding = new Gee.ArrayList<Item>(); */
/*         accept_empty = true; */
/*     } */
/*  */
/*     public Feed.from_db(SQLHeavy.QueryResult result) */
/*     { */
/*         _last_guids = new Gee.ArrayList<string>(); */
/*         _last_guids_post = new Gee.ArrayList<string>(); */
/*         _items = new Gee.ArrayList<Item>(); */
/*         _items_unread = new Gee.ArrayList<Item>(); */
/*         _items_starred = new Gee.ArrayList<Item>(); */
/*         _items_holding = new Gee.ArrayList<Item>(); */
/*         try { */
/*             _id = result.fetch_int(0); */
/*             parent_id = result.fetch_int(1); */
/*             title = result.fetch_string(2); */
/*             link = result.fetch_string(3); */
/*             origin_link = result.fetch_string(4); */
/*             description = result.fetch_string(5); */
/*             // TODO: Load icon here */
/*             var guid_list = result.fetch_string(6).split("\n"); */
/*             foreach(string s in guid_list) */
/*                 _last_guids.add(s); */
/*             _last_time = new DateTime.from_unix_utc(result.fetch_int(7)); */
/*             // TODO: Re-enable once this is updated */
/*             //override_rules = parseRules(result.fetch_string(8)); */
/*             override_location = result.fetch_int(9) == 1; */
/*             get_location = result.fetch_int(10) == 1; */
/*             default_location = result.fetch_string(11); */
/*         } catch(SQLHeavy.Error e) { */
/*             // TODO: verbose */
/*             /* if(verbose) */ */
/*             /*     stderr.printf("Error loading feed data: %s\n", e.message); */ */
/*             return; */
/*         } */
/*     } */
/*  */
/*     public Feed.from_xml(Xml.Node* node, string url, int new_id = -1) */
/*     { */
/*         _last_guids = new Gee.ArrayList<string>(); */
/*         _last_guids_post = new Gee.ArrayList<string>(); */
/*         _id = new_id; */
/*         origin_link = url; */
/*         accept_empty = true; */
/*         _items = new Gee.ArrayList<Item>(); */
/*         _items_unread = new Gee.ArrayList<Item>(); */
/*         _items_starred = new Gee.ArrayList<Item>(); */
/*         _items_holding = new Gee.ArrayList<Item>(); */
/*  */
/*         while(node != null && node->name != "rss" && node->name != "RDF" && node->name != "feed") { */
/*             node = node->next; */
/*         } */
/*         if(node == null) { */
/*             // TODO: verbose */
/*             /* if(verbose) */ */
/*             /*     stderr.printf("Error: No defining node was found\n"); */ */
/*             status = 3; */
/*             return; */
/*         } */
/*         if(node->name == "rss") { */
/*             for(node = node->children; node != null; node = node->next) { */
/*                 if(node->type == Xml.ElementType.ELEMENT_NODE) { */
/*                     for(Xml.Node* dat = node->children; dat != null; dat = dat->next) { */
/*                         if(dat->type == Xml.ElementType.ELEMENT_NODE) { */
/*                             switch(dat->name) { */
/*                             case "title": */
/*                                 title = getNodeContents(dat); */
/*                             break; */
/*  */
/*                             case "link": */
/*                                 link = getNodeContents(dat); */
/*                             break; */
/*  */
/*                             case "description": */
/*                                 description = getNodeContents(dat); */
/*                             break; */
/*  */
/*                             case "item": */
/*                                 if(!add_item(new Item.from_rss(dat))) { */
/*                                     return; */
/*                                 } */
/*                             break; */
/*                              */
/*                             default: */
/*                                 //stderr.printf("Feed element <%s> is not currently supported.\n", dat->name); */
/*                             break; */
/*                             } */
/*                         } */
/*                     } */
/*                 } */
/*             } */
/*         } else if(node->name == "feed") { */
/*             for(node = node->children; node != null; node = node->next) { */
/*             if(node->type == Xml.ElementType.ELEMENT_NODE) { */
/*                 switch(node->name) { */
/*                 case "title": */
/*                     title = getNodeContents(node, true); */
/*                 break; */
/*  */
/*                 case "link": */
/*                     if(node->has_prop("rel") != null && node->has_prop("rel")->children->content == "alternate") */
/*                     link = node->has_prop("href")->children->content; */
/*                 break; */
/*  */
/*                 case "description": */
/*                     description = getNodeContents(node, true); */
/*                 break; */
/*  */
/*                 case "entry": */
/*                     if(!add_item(new Item.from_atom(node))) { */
/*                     return; */
/*                     } */
/*                 break; */
/*                  */
/*                 default: */
/*                     //stderr.printf("Element <%s> is not currently supported.\n", node->name); */
/*                 break; */
/*                 } */
/*             } */
/*             } */
/*         } else if(node->name == "RDF") { */
/*             for(; node != null; node = node->next) { */
/*             if(node->type == Xml.ElementType.ELEMENT_NODE) { */
/*                 for(Xml.Node* dat = node->children; dat != null; dat = dat->next) { */
/*                 if(dat->type == Xml.ElementType.ELEMENT_NODE) { */
/*                     switch(dat->name) { */
/*                     case "channel": */
/*                         for(Xml.Node* cdat = dat->children; cdat != null; cdat = cdat->next) */
/*                         if(cdat->type == Xml.ElementType.ELEMENT_NODE) { */
/*                             switch(cdat->name) { */
/*                             case "title": */
/*                                 title = getNodeContents(cdat); */
/*                             break; */
/*  */
/*                             case "link": */
/*                                 link = getNodeContents(cdat); */
/*                             break; */
/*  */
/*                             case "description": */
/*                                 description = getNodeContents(cdat); */
/*                             break; */
/*                             } */
/*                         } */
/*                     break; */
/*  */
/*                     case "item": */
/*                         if(!add_item(new Item.from_rss(dat))) { */
/*                         return; */
/*                         } */
/*                     break; */
/*                      */
/*                     default: */
/*                         //stderr.printf("Feed element <%s> is not currently supported.\n", dat->name); */
/*                     break; */
/*                     } */
/*                 } */
/*                 } */
/*             } */
/*             } */
/*         } */
/*         //_last_guid = _last_guid_post; */
/*         _last_guids = _last_guids_post; */
/*         if(title == null) */
/*             title = "Untitled Feed"; */
/*     } */
/*  */
/*     bool parseRules(string? rulestr) */
/*     { */
/*         if(rulestr == null || rulestr == "") */
/*            return false;  */
/*  */
/*         // TODO: Update these later */
/*         //rulestr.scanf("%d %d %d\n%d %d %d\n%d %d %d\n%d %d %d", &unread_unstarred_rule[0], &unread_unstarred_rule[1], &unread_unstarred_rule[2], &unread_starred_rule[0], &unread_starred_rule[1], &unread_starred_rule[2], &read_unstarred_rule[0], &read_unstarred_rule[1], &read_unstarred_rule[2], &read_starred_rule[0], &read_starred_rule[1], &read_starred_rule[2]); */
/*         return true; */
/*     } */
/*  */
/*     public async void updateFromWeb(DatabaseManager man) */
/*     { */
/*         //_last_guid_post = _last_guid; */
/*         _last_time_post = _last_time; */
/*         status = 1; */
/*         //app.updateFeedIcons(this); */
/*         Xml.Doc* doc = yield getXmlData(origin_link); */
/*         Xml.Node* node = doc->get_root_element(); */
/*         accept_empty = true; */
/*  */
/*         while(node != null && node->name != "rss" && node->name != "RDF" && node->name != "feed") */
/*             node = node->next; */
/*         if(node == null) { */
/*             // TODO: verbose */
/*             /* if(verbose) */ */
/*             /*     stderr.printf("Error: No defining node was found\n"); */ */
/*             status = 3; */
/*             //app.updateFeedIcons(this); */
/*             return; */
/*         } */
/*  */
/*         if(node->name == "rss") { */
/*             for(node = node->children; node != null; node = node->next) { */
/*                 if(node->type == Xml.ElementType.ELEMENT_NODE) { */
/*                     for(Xml.Node* dat = node->children; dat != null; dat = dat->next) { */
/*                         if(dat->type == Xml.ElementType.ELEMENT_NODE) { */
/*                             switch(dat->name) { */
/*                             case "title": */
/*                                 title = getNodeContents(dat); */
/*                             break; */
/*  */
/*                             case "link": */
/*                                 link = getNodeContents(dat); */
/*                             break; */
/*  */
/*                             case "description": */
/*                                 description = getNodeContents(dat); */
/*                             break; */
/*  */
/*                             case "item": */
/*                                 if(!add_item(new Item.from_rss(dat), true)) { */
/*                                     continue; */
/*                                 } */
/*                             break; */
/*                              */
/*                             default: */
/*                                 //stderr.printf("Feed element <%s> is not currently supported.\n", dat->name); */
/*                             break; */
/*                             } */
/*                         } */
/*                     } */
/*                 } */
/*             } */
/*         } else if(node->name == "feed") { */
/*             for(node = node->children; node != null; node = node->next) { */
/*             if(node->type == Xml.ElementType.ELEMENT_NODE) { */
/*                 switch(node->name) { */
/*                 case "title": */
/*                     title = getNodeContents(node, true); */
/*                 break; */
/*  */
/*                 case "link": */
/*                     if(node->has_prop("rel") != null && node->has_prop("rel")->children->content == "alternate") */
/*                     link = node->has_prop("href")->children->content; */
/*                 break; */
/*  */
/*                 case "description": */
/*                     description = getNodeContents(node, true); */
/*                 break; */
/*  */
/*                 case "entry": */
/*                     if(!add_item(new Item.from_atom(node), true)) { */
/*                         continue; */
/*                     } */
/*                 break; */
/*                  */
/*                 default: */
/*                     //stderr.printf("Element <%s> is not currently supported.\n", node->name); */
/*                 break; */
/*                 } */
/*             } */
/*             } */
/*         } else if(node->name == "RDF") { */
/*             for(; node != null; node = node->next) { */
/*             if(node->type == Xml.ElementType.ELEMENT_NODE) { */
/*                 for(Xml.Node* dat = node->children; dat != null; dat = dat->next) { */
/*                 if(dat->type == Xml.ElementType.ELEMENT_NODE) { */
/*                     switch(dat->name) { */
/*                     case "channel": */
/*                         for(Xml.Node* cdat = dat->children; cdat != null; cdat = cdat->next) */
/*                         if(cdat->type == Xml.ElementType.ELEMENT_NODE) { */
/*                             switch(cdat->name) { */
/*                             case "title": */
/*                                 title = getNodeContents(cdat); */
/*                             break; */
/*  */
/*                             case "link": */
/*                                 link = getNodeContents(cdat); */
/*                             break; */
/*  */
/*                             case "description": */
/*                                 description = getNodeContents(cdat); */
/*                             break; */
/*                             } */
/*                         } */
/*                     break; */
/*  */
/*                     case "item": */
/*                         if(!add_item(new Item.from_rss(dat), true)) { */
/*                             continue; */
/*                         } */
/*                     break; */
/*                      */
/*                     default: */
/*                         //stderr.printf("Feed element <%s> is not currently supported.\n", dat->name); */
/*                     break; */
/*                     } */
/*                 } */
/*                 } */
/*             } */
/*             } */
/*         } */
/*         if(status != 3) */
/*             status = 2; */
/*         // FIXME: Remove interdependency */
/*         //app.updateFeedIcons(this); */
/*         /* app.updateFeedItems(this); */ */
/*          */
/*         //_last_guid = _last_guid_post; */
/*         if(_last_guids_post.size > 0) { */
/*             _last_guids = _last_guids_post; */
/*             stderr.printf("GUIDS FROM %s:", title); */
/*             foreach(string i in _last_guids_post) */
/*                 stderr.printf("GUID: %s\n", i); */
/*         } */
/*         _last_time = _last_time_post; */
/*         stderr.printf("Saving feed info...\n"); */
/*         yield man.saveFeed(this, false); */
/*         if(_items_holding.size != 0) { */
/*             stderr.printf("Saving %d items...\n", _items_holding.size); */
/*             yield man.saveFeedItems(this, _items_holding); */
/*             _items_holding.clear(); */
/*         } */
/*     } */
/*  */
/*     public Item get(int id) */
/*     { */
/*         return _items[id]; */
/*     } */
/*  */
/*     public string get_guids() */
/*     { */
/*         string guid = ""; */
/*         foreach(string s in _last_guids) */
/*             guid += s + "\n"; */
/*         return guid; */
/*     } */
/*      */
/*     public bool add_item(Item new_item, bool hold = false) */
/*     { */
/*         if(hold) { */
/*             _last_guids_post.add(new_item.guid); */
/*         } */
/*         if(hold && (new_item.empty == true)) { */
/*             return false; */
/*         } */
/*  */
/*         if(hold && _last_guids.contains(new_item.guid)) */
/*             return false; */
/*  */
/*         bool keep = true; */
/*         if(!new_item.starred) { */
/*             if(override_rules) { */
/*                 if(new_item.unread) { */
/*                     keep = new_item.applyRule(unread_rule); */
/*                 } else { */
/*                     keep = new_item.applyRule(read_rule); */
/*                 } */
/*             } else { */
/*                 if(new_item.unread) { */
/*                     keep = new_item.applyRule(unread_rule); */
/*                 } else { */
/*                     keep = new_item.applyRule(read_rule); */
/*                 } */
/*             } */
/*         } */
/*  */
/*         if(!keep) */
/*             return false; */
/*  */
/*         foreach(Item i in _items) { */
/*             if(i.guid == new_item.guid) { */
/*                 return false; */
/*             } */
/*         } */
/*         if(hold == true) { */
/*             _items_holding.add(new_item); */
/*         } */
/*         if(new_item.unread == true) */
/*             _items_unread.add(new_item); */
/*         if(new_item.starred == true) */
/*             _items_starred.add(new_item); */
/*         new_item.feed = this; */
/*         _items.add(new_item); */
/*         return true; */
/*     } */
/*      */
/*     public Item get_item(int id = 0) */
/*     { */
/*         return _items[id]; */
/*     } */
/*  */
/*     public string constructHtml(DatabaseManager man) */
/*     { */
/*         string html_string = "<div class=\"feed\">"; */
/*         foreach(Item i in _items) { */
/*             html_string += i.constructHtml(); */
/*         } */
/*         html_string += "</div>"; */
/*         return html_string; */
/*     } */
/*  */
/*     public string constructUnreadHtml(DatabaseManager man) */
/*     { */
/*         string html_string = "<div class=\"feed\">"; */
/*         for(int i = _items_unread.size - 1; i >= 0; --i) { */
/*             html_string += _items_unread[i].constructHtml(); */
/*         } */
/*         if(html_string == "<div class=\"feed\">") */
/*             return ""; */
/*         html_string += "</div>"; */
/*         return html_string; */
/*     } */
/*  */
/*     public string constructStarredHtml(DatabaseManager man) */
/*     { */
/*         string html_string = "<div class=\"feed\">"; */
/*         foreach(Item i in _items_starred) { */
/*             html_string += i.constructHtml(); */
/*         } */
/*         if(html_string == "<div class=\"feed\">") */
/*             return ""; */
/*         html_string += "</div>"; */
/*         return html_string; */
/*     } */
/*  */
/*     public void removeUnreadItem(Item i) */
/*     { */
/*         _items_unread.remove(i); */
/*     } */
/*  */
/*     public void toggleStar(Item i) */
/*     { */
/*         if(_items.contains(i)) { */
/*             i.starred = !i.starred; */
/*             if(i.starred) */
/*                 _items_starred.add(i); */
/*             else */
/*                 _items_starred.remove(i); */
/*         } */
/*     } */
}
}
