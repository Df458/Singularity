/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

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
    class RSSItemDataSource : FeedProvider
    {
        public override bool parse_data(Xml.Doc doc)
        {
            stored_feed = new Feed();
            stored_feed.last_update = new DateTime.now_utc();
            _data = new Gee.ArrayList<Item>();
            Xml.Node* node = doc.get_root_element();

            while(node != null && node->name != "rss" && node->name != "RDF")
                node = node->next;

            if(node == null)
                return false;

            if(node->name == "rss")
                readRSSFeed(node->children);
            else if(node->name == "RDF")
                readRDFFeed(node);

            return true;
        }

        private void readRSSFeed(Xml.Node* node)
        {
            for(; node != null; node = node->next) {
                if(node->type == Xml.ElementType.ELEMENT_NODE) {
                    for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
                        if(dat->type == Xml.ElementType.ELEMENT_NODE) {
                            switch(dat->name) {
                                case "title":
                                    stored_feed.title = get_node_contents(dat).strip().replace("&", "&amp;");
                                break;

                                case "link":
                                    stored_feed.site_link = get_node_contents(dat);
                                break;

                                case "description":
                                    stored_feed.description = get_node_contents(dat);
                                break;

                                case "item":
                                    Item item = readRSSItem(dat);
                                    if(item != null)
                                        _data.add(item);
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

        private Item? readRSSItem(Xml.Node* node)
        {
            Item new_item = new Item();

            for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
                if(dat->type == Xml.ElementType.ELEMENT_NODE) {
                    switch(dat->name) {
                        case "title":
                            new_item.title = get_node_contents(dat);
                        break;

                        case "link":
                            new_item.link = get_node_contents(dat);
                        break;

                        case "description":
                            new_item.content = get_node_contents(dat);
                        break;

                        case "guid":
                            new_item.guid = get_node_contents(dat);
                        break;

                        case "pubDate":
                            string input = get_node_contents(dat);
                            string[] date_strs = input.split(" ");
                            if(date_strs.length < 5)
                                break;
                            string[] time_strs = date_strs[4].split(":");
                            if(time_strs.length < 3)
                                break;
                            new_item.time_published = new DateTime.utc(int.parse(date_strs[3]), get_month(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                            new_item.time_updated = new DateTime.utc(int.parse(date_strs[3]), get_month(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                        break;

                        case "date":
                            string[] big_strs = get_node_contents(dat).split("T");
                            if(big_strs.length < 2)
                                break;
                            string[] date_strs = big_strs[0].split("-");
                            if(date_strs.length < 3)
                                break;
                            string[] time_strs = big_strs[1].split(":");
                            if(time_strs.length < 3)
                                break;
                            new_item.time_published = new DateTime.utc(int.parse(date_strs[0]), int.parse(date_strs[1]), int.parse(date_strs[2]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                            new_item.time_updated = new DateTime.utc(int.parse(date_strs[0]), int.parse(date_strs[1]), int.parse(date_strs[2]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                        break;

                        case "author":
                        case "creator":
                            new_item.author = Person(get_node_contents(dat));
                        break;

                        case "enclosure":
                            // TODO: Reimplement after adding attachments
                            /* if(dat->has_prop("url") != null) */
                            /*     enclosure_url = dat->has_prop("url")->children->content; */
                            /* if(dat->has_prop("length") != null) */
                            /*     enclosure_length = int.parse(dat->has_prop("length")->children->content); */
                            /* if(dat->has_prop("type") != null) */
                            /*     enclosure_type = dat->has_prop("type")->children->content; */
                        break;

                        default:
                            //stderr.printf("Item element <%s> is not currently supported.\n", dat->name);
                        break;
                    }
                }
            }
            if(new_item.guid == null || new_item.guid == "") {
                if(new_item.link != null && new_item.link.length > 0) {
                    new_item.guid = new_item.link;
                } else if(new_item.title.length > 0) {
                    new_item.guid = new_item.title;
                } else if(new_item.content != null && new_item.content.length > 0) {
                    new_item.guid = new_item.content;
                } else {
                    warning("Could not establish GUID for feed, as it has no guid, title, link, or content");
                    return null;
                }
            }

            return new_item;
        }

        private void readRDFFeed(Xml.Node* node)
        {
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
                                                    /* title = get_node_contents(cdat); */
                                                break;

                                                case "link":
                                                    /* link = get_node_contents(cdat); */
                                                break;

                                                case "description":
                                                    /* description = get_node_contents(cdat); */
                                                break;
                                            }
                                        }
                                break;

                                case "item":
                                    Item item = readRSSItem(dat);
                                    _data.add(item);
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
    }
}
