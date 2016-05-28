namespace Singularity
{
    class RSSItemDataSource : DataSource<Item, unowned Xml.Doc>
    {
        public override bool parse_data(Xml.Doc doc)
        {
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
                                    /* title = getNodeContents(dat); */
                                break;

                                case "link":
                                    /* link = getNodeContents(dat); */
                                break;

                                case "description":
                                    /* description = getNodeContents(dat); */
                                break;

                                case "item":
                                    _data.add(readRSSItem(dat));
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

        private Item readRSSItem(Xml.Node* node)
        {
            /* _time_added = new DateTime.now_utc(); */
            /* for(Xml.Node* dat = node->children; dat != null; dat = dat->next) { */
            /*     if(dat->type == Xml.ElementType.ELEMENT_NODE) { */
            /*         switch(dat->name) { */
            /*             case "title": */
            /*                 title = getNodeContents(dat); */
            /*             break; */
            /*  */
            /*             case "link": */
            /*                 link = getNodeContents(dat); */
            /*             break; */
            /*  */
            /*             case "description": */
            /*                 description = getNodeContents(dat); */
            /*             break; */
            /*  */
            /*             case "guid": */
            /*                 _guid = getNodeContents(dat); */
            /*             break; */
            /*  */
            /*             case "pubDate": */
            /*                 string input = getNodeContents(dat); */
            /*                 string[] date_strs = input.split(" "); */
            /*                 if(date_strs.length < 5) */
            /*                     break; */
            /*                 string[] time_strs = date_strs[4].split(":"); */
            /*                 if(time_strs.length < 3) */
            /*                     break; */
            /*                 _time_posted = new DateTime.utc(int.parse(date_strs[3]), getMonth(date_strs[2]), int.parse(date_strs[1]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2])); */
            /*             break; */
            /*  */
            /*             case "date": */
            /*                 string[] big_strs = getNodeContents(dat).split("T"); */
            /*                 if(big_strs.length < 2) */
            /*                     break; */
            /*                 string[] date_strs = big_strs[0].split("-"); */
            /*                 if(date_strs.length < 3) */
            /*                     break; */
            /*                 string[] time_strs = big_strs[1].split(":"); */
            /*                 if(time_strs.length < 3) */
            /*                     break; */
            /*                 _time_posted = new DateTime.utc(int.parse(date_strs[0]), int.parse(date_strs[1]), int.parse(date_strs[2]), int.parse(time_strs[0]), int.parse(time_strs[1]), int.parse(time_strs[2])); */
            /*             break; */
            /*  */
            /*             case "author": */
            /*             case "creator": */
            /*                 author = getNodeContents(dat); */
            /*             break; */
            /*  */
            /*             case "enclosure": */
            /*                 if(dat->has_prop("url") != null) */
            /*                     enclosure_url = dat->has_prop("url")->children->content; */
            /*                 if(dat->has_prop("length") != null) */
            /*                     enclosure_length = int.parse(dat->has_prop("length")->children->content); */
            /*                 if(dat->has_prop("type") != null) */
            /*                     enclosure_type = dat->has_prop("type")->children->content; */
            /*             break; */
            /*  */
            /*             default: */
            /*                 //stderr.printf("Item element <%s> is not currently supported.\n", dat->name); */
            /*             break; */
            /*         } */
            /*     } */
            /* } */
            /* unread = true; */
            /* if(_guid == "" || _guid == null) { */
            /*     _guid = link; */
            /*     if(link == "" || link == null) { */
            /*         _guid = title; */
            /*         if(title == "" || title == null) { */
            /*             _guid = ""; */
            /*         } */
            /*     } */
            /* } */
            /* if(_guid != "") */
            /*     _empty = false; */
            return new Item();
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
                                    _data.add(readRDFItem(dat));
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

        private Item readRDFItem(Xml.Node* node)
        {
            warning("unimplemented");
            return new Item();
        }
    }
}
