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

public class Item {
    private string _guid = "";
    private DateTime _time_posted = new DateTime.from_unix_utc(0);
    private DateTime _time_added = new DateTime.now_utc();
    private bool _empty = true;

    public string title       { get; set; } //Item title
    public string link        { get; set; } //Item link
    public string description { get; set; } //Item description
    public string author      { get; set; } //Item author
    public string guid { get { return _guid; } } //Unique identifier
    public Feed feed { get; set; }
    public bool unread  = false;
    public bool starred = false;
    public DateTime time_posted { get { return _time_posted; } }
    public DateTime time_added  { get { return _time_added;  } }	
    public bool empty { get { return _empty; } }
    public string enclosure_url = "";
    public uint enclosure_length = 0;
    public string enclosure_type = "";
    
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
            if(result.fetch_int(13) == 1) {
                starred = true;
            }
            _empty = false;
        } catch(SQLHeavy.Error e) {
            if(verbose)
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
                string input = getNodeContents(dat);
                string[] date_strs = input.split(" ");
                if(date_strs.length < 5)
                    break;
                string[] time_strs = date_strs[4].split(":");
                if(time_strs.length < 3)
                    break;
                _time_posted = new DateTime.utc(int.parse(date_strs[3]), getMonth(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                break;

                case "date":
                string[] big_strs = getNodeContents(dat).split("T");
                if(big_strs.length < 2)
                    break;
                string[] date_strs = big_strs[0].split("-");
                if(date_strs.length < 3)
                    break;
                string[] time_strs = big_strs[1].split(":");
                if(time_strs.length < 3)
                    break;
                _time_posted = new DateTime.utc(int.parse(date_strs[0]), int.parse(date_strs[1]), int.parse(date_strs[2]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                break;

                case "author":
                case "creator":
                author = getNodeContents(dat);
                break;

                case "enclosure":
                if(dat->has_prop("url") != null)
                    enclosure_url = dat->has_prop("url")->children->content;
                if(dat->has_prop("length") != null)
                    enclosure_length = int.parse(dat->has_prop("length")->children->content);
                if(dat->has_prop("type") != null)
                    enclosure_type = dat->has_prop("type")->children->content;
                break;
                
                default:
                //stderr.printf("Item element <%s> is not currently supported.\n", dat->name);
                break;
            }
            }
        }
        unread = true;
        if(_guid == "" || _guid == null) {
            _guid = link;
            if(link == "" || link == null) {
            _guid = title;
            if(title == "" || title == null) {
                _guid = "";
            }
            }
        }
        if(_guid != "")
            _empty = false;
    }

    public Item.from_atom(Xml.Node* node) {
        _time_added = new DateTime.now_utc();
        for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
            if(dat->type == Xml.ElementType.ELEMENT_NODE) {
            switch(dat->name) {
                case "title":
                title = getNodeContents(dat, true);
                break;

                case "link":
                if(dat->has_prop("rel") == null || dat->has_prop("rel")->children->content == "alternate") {
                    link = dat->has_prop("href")->children->content;
                }
                break;

                case "content":
                description = getNodeContents(dat, true);
                break;

                case "id":
                case "guid":
                _guid = getNodeContents(dat, true);
                break;

                case "updated": 
                if(getNodeContents(dat) == null)
                    break;
                string input = getNodeContents(dat);
                string[] big_strs = input.split("T");
                if(big_strs.length < 2)
                    break;
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
            }
        }
        unread = true;
        if(_guid == "" || _guid == null) {
            _guid = link;
            if(link == "" && title != "")
            _guid = title;
        }
        if(_guid != "" || time_posted != new DateTime.from_unix_utc(0))
            _empty = false;
    }

    public bool applyRule(int[] rule) {
        //stdout.printf("Rule: %d, %d, %d\n", rule[0], rule[1], rule[2]);
        if(rule[1] == 0 || rule[2] == 0)
            return true;

        //stdout.printf("Getting time(%d)...\n", rule[0]);
        if(rule[0] != 0) {
            int timediff;
            switch(rule[1]) {
                case 1:
                    timediff = time_added.add_minutes(rule[0]).compare(new DateTime.now_utc());
                break;
                case 2:
                    timediff = time_added.add_hours(rule[0]).compare(new DateTime.now_utc());
                break;
                case 3:
                    timediff = time_added.add_days(rule[0]).compare(new DateTime.now_utc());
                break;
                case 4:
                    timediff = time_added.add_months(rule[0]).compare(new DateTime.now_utc());
                break;
                case 5:
                    timediff = time_added.add_years(rule[0]).compare(new DateTime.now_utc());
                break;
                default:
                    return true;
            }
            //stdout.printf("diff: %d\n", timediff);

            if(timediff > 0) {
                //stdout.printf("Time has not arrived yet!\n");
                return true;
            }
        }

        switch(rule[2]) {
            case 1:
                unread = !unread;
            break;
            case 2:
                starred = !starred;
            break;
            case 3:
                return false;
        }
        return true;
    }

    public string constructHtml() {
        string html_string = "<article class=\"singularity-item\"><header class=\"item-head\" viewed=\"" + (unread ? "false" : "true") +"\"><a href=" + link + "><h3>" + title + "</h3></a>" /*+ "<input type=\"image\" src=\"file:///usr/local/share/singularity/emblem_failure.png\"/>\n"*/;
        string authtimestr = "<p>Posted";
        if(author.strip() != "" && author != null)
            authtimestr += " by " + author;
        if(_time_posted.compare(new DateTime.from_unix_utc(0)) != 0) {
            authtimestr += " on <time datetime=\"" + _time_posted.to_string();
            authtimestr += "\">" + _time_posted.to_string() + "</time></header>";
        }
        if(authtimestr != "")
            html_string += authtimestr;
        if(description.strip() != "" && description != null)
            html_string += "<br /><div class='item-content'>" + description + "</div>";
        if(enclosure_url != "" && enclosure_url != null) {
            html_string += "<br /><a href=" + enclosure_url + ">Attachment</a>";
        }
        html_string += "</article>";
        app.addToView(this);
        return html_string;
    }
}
