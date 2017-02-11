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

// TODO: Rework this. Currently, it's based on the 0.2 code, but we can probably do better now
namespace Singularity
{
    class AtomItemDataSource : FeedProvider
    {
        public override bool parse_data(Xml.Doc doc)
        {
            stored_feed = new Feed();
            stored_feed.last_update = new DateTime.now_utc();
            _data = new Gee.ArrayList<Item>();
            Xml.Node* node = doc.get_root_element();

            while(node != null && node->name != "feed")
                node = node->next;

            if(node == null)
                return false;

            readAtomFeed(node->children);

            return true;
        }

        private void readAtomFeed(Xml.Node* node)
        {
            for(; node != null; node = node->next) {
                if(node->type == Xml.ElementType.ELEMENT_NODE) {
                    switch(node->name) {
                        case "title":
                            stored_feed.title = get_node_contents(node).strip().replace("&", "&amp;");
                        break;

                        case "link":
                            stored_feed.site_link = get_node_contents(node);
                        break;

                        case "icon":
                            IconRequest req = new IconRequest(get_node_contents(node));
                            if(req.send()) {
                                stored_feed.icon = req.buf;
                            }
                        break;

                        case "description":
                            stored_feed.description = get_node_contents(node);
                        break;

                        case "entry":
                            Item item = readAtomItem(node);
                            if(item != null)
                                _data.add(item);
                        break;

                        default:
                            //stderr.printf("Feed element <%s> is not currently supported.\n", node->name);
                        break;
                    }
                }
            }
        }

        private Item? readAtomItem(Xml.Node* node)
        {
            Item new_item = new Item();

            for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
                if(dat->type == Xml.ElementType.ELEMENT_NODE) {
                    switch(dat->name) {
                        case "title":
                            new_item.title = get_node_contents(dat, true);
                        break;

                        case "link":
                            if(dat->has_prop("rel") == null || dat->has_prop("rel")->children->content == "alternate") {
                                new_item.link = dat->has_prop("href")->children->content;
                            } else if(dat->has_prop("rel")->children->content == "enclosure") {
                                Attachment a = Attachment();
                                a.url = dat->has_prop("href")->children->content;
                                if(dat->has_prop("title") != null)
                                    a.name = dat->has_prop("title")->children->content;
                                else
                                    a.name = a.url.substring(a.url.last_index_of_char('/') + 1);
                                if(dat->has_prop("length") != null)
                                    a.size = int.parse(dat->has_prop("length")->children->content);
                                if(dat->has_prop("type") != null)
                                    a.mimetype = dat->has_prop("type")->children->content;

                                new_item.attachments.add(a);
                            }
                        break;

                        case "content":
                        case "summary":
                            if(new_item.content == null || new_item.content.strip() == "" || dat->get_prop("type") == "html" || dat->get_prop("type") == "xhtml")
                                new_item.content = get_node_contents(dat, true);
                        break;


                        case "id":
                        case "guid":
                            new_item.guid = get_node_contents(dat, true);
                        break;

                        case "updated":
                            string input = get_node_contents(dat, true);
                            string[] date_strs = input.split(" ");
                            if(date_strs.length < 5)
                                break;
                            string[] time_strs = date_strs[4].split(":");
                            if(time_strs.length < 3)
                                break;
                            new_item.time_published = new DateTime.utc(int.parse(date_strs[3]), get_month(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                            new_item.time_updated = new DateTime.utc(int.parse(date_strs[3]), get_month(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                        break;

                        case "author":
                        case "creator":
                            new_item.author = Person(get_node_contents(dat, true));
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
                } else if(new_item.title != null && new_item.title.length > 0) {
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
    }
}
