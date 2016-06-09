namespace Singularity
{
    class RSSItemDataSource : FeedProvider
    {
        public override bool parse_data(Xml.Doc doc)
        {
            stored_feed = new Feed();
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
                                    stored_feed.title = getNodeContents(dat);
                                break;

                                case "link":
                                    stored_feed.link = getNodeContents(dat);
                                break;

                                case "description":
                                    stored_feed.description = getNodeContents(dat);
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

        private Item? readRSSItem(Xml.Node* node)
        {
            Item new_item = new Item();

            for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
                if(dat->type == Xml.ElementType.ELEMENT_NODE) {
                    switch(dat->name) {
                        case "title":
                            new_item.title = getNodeContents(dat);
                        break;

                        case "link":
                            new_item.link = getNodeContents(dat);
                        break;

                        case "description":
                            new_item.content = getNodeContents(dat);
                        break;

                        case "guid":
                            new_item.guid = getNodeContents(dat);
                        break;

                        case "pubDate":
                            string input = getNodeContents(dat);
                            string[] date_strs = input.split(" ");
                            if(date_strs.length < 5)
                                break;
                            string[] time_strs = date_strs[4].split(":");
                            if(time_strs.length < 3)
                                break;
                            new_item.time_published = new DateTime.utc(int.parse(date_strs[3]), getMonth(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                            new_item.time_updated = new DateTime.utc(int.parse(date_strs[3]), getMonth(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
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
                            new_item.time_published = new DateTime.utc(int.parse(date_strs[0]), int.parse(date_strs[1]), int.parse(date_strs[2]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                            new_item.time_updated = new DateTime.utc(int.parse(date_strs[0]), int.parse(date_strs[1]), int.parse(date_strs[2]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2]));
                        break;

                        case "author":
                        case "creator":
                            new_item.author = Person(getNodeContents(dat));
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
            if(new_item.guid == "") {
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
                                                    /* title = getNodeContents(cdat); */
                                                break;

                                                case "link":
                                                    /* link = getNodeContents(cdat); */
                                                break;

                                                case "description":
                                                    /* description = getNodeContents(cdat); */
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
