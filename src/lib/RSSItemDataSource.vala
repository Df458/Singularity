/*
    Singularity - A web newsfeed aggregator
    Copyright (C) 2017  Hugues Ross <hugues.ross@gmail.com>

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

namespace Singularity {
    // FeedProvider implementation for RSS/RDF feeds
    // Parses Atom feeds and converts them into Feed objects
    // TODO: Simplify the parser functions by taking better advantage of GXml
    class RSSItemDataSource : FeedProvider {
        // Main parsing function, takes a GXml.GDocument and uses it to init
        // its internal feed
        // Returns true if successful
        public override bool parse_data (GXml.GDocument doc) {
            stored_feed = new Feed ();
            stored_feed.last_update = new DateTime.now_utc ();
            _data = new Gee.ArrayList<Item> ();
            GXml.Node? node = doc["rss"];

            if (node == null)
                node = doc["RDF"];
            else {
                readRSSFeed (node);
                return true;
            }

            if (node == null)
                return false;

            readRDFFeed (node);

            return true;
        }

        // Parses a <rss> node to populate the internal feed
        private void readRSSFeed (GXml.Node node) {
            foreach (GXml.Node n in node.children_nodes) {
                if (n.type_node == GXml.NodeType.ELEMENT) {
                    foreach (GXml.Node dat in n.children_nodes) {
                        if (dat.type_node == GXml.NodeType.ELEMENT) {
                            switch (dat.name) {
                                case "title":
                                    stored_feed.title = dat.value.strip ().replace ("&", "&amp;");
                                break;

                                case "link":
                                    stored_feed.site_link = dat.value;
                                break;

                                case "image":
                                    GXml.Node url = dat["url"];
                                    if (url != null) {
                                        IconRequest req = new IconRequest (url.value);
                                        if (req.send ())
                                            stored_feed.icon = req.buf;
                                    }
                                break;

                                case "description":
                                    stored_feed.description = dat.value;
                                break;

                                case "item":
                                    Item item = readRSSItem (dat);
                                    if (item != null)
                                        _data.add (item);
                                break;

                                default:
                                    //stderr.printf ("Feed element <%s> is not currently supported.\n", dat->name);
                                break;
                            }
                        }
                    }
                }
            }
        }

        // Parses an <item> node and tries to create a new Item from it
        // Returns the item if successful, otherwise returns null
        private Item? readRSSItem (GXml.Node node) {
            Item new_item = new Item ();

            foreach (GXml.Node n in node.children_nodes) {
                if (n.type_node == GXml.NodeType.ELEMENT) {
                    switch (n.name) {
                        case "title":
                            new_item.title = n.value;
                        break;

                        case "link":
                            new_item.link = n.value;
                        break;

                        case "description":
                            new_item.content = n.value;
                        break;

                        case "guid":
                            new_item.weak_guid = n.value;
                        break;

                        case "pubDate":
                            string input = n.value;
                            string[] date_strs = input.split (" ");
                            if (date_strs.length < 5)
                                break;
                            string[] time_strs = date_strs[4].split (":");
                            if (time_strs.length < 3)
                                break;
                            new_item.time_published = new DateTime.utc (
                                int.parse (date_strs[3]),
                                get_month (date_strs[2]),
                                int.parse (date_strs[1]),
                                int.parse (time_strs[0]),
                                int.parse (time_strs[1]),
                                int.parse (time_strs[2]));
                            new_item.time_updated = new DateTime.utc (
                                int.parse (date_strs[3]),
                                get_month (date_strs[2]),
                                int.parse (date_strs[1]),
                                int.parse (time_strs[0]),
                                int.parse (time_strs[1]),
                                int.parse (time_strs[2]));
                        break;

                        case "date":
                            string[] big_strs = n.value.split ("T");
                            if (big_strs.length < 2)
                                break;
                            string[] date_strs = big_strs[0].split ("-");
                            if (date_strs.length < 3)
                                break;
                            string[] time_strs = big_strs[1].split (":");
                            if (time_strs.length < 3)
                                break;
                            new_item.time_published = new DateTime.utc (
                                int.parse (date_strs[0]),
                                int.parse (date_strs[1]),
                                int.parse (date_strs[2]),
                                int.parse (time_strs[0]),
                                int.parse (time_strs[1]),
                                int.parse (time_strs[2]));
                            new_item.time_updated = new DateTime.utc (
                                int.parse (date_strs[0]),
                                int.parse (date_strs[1]),
                                int.parse (date_strs[2]),
                                int.parse (time_strs[0]),
                                int.parse (time_strs[1]),
                                int.parse (time_strs[2]));
                        break;

                        case "author":
                        case "creator":
                            new_item.author = new Person (n.value);
                        break;

                        case "enclosure":
                            if (n.attrs.has_key ("url")) {
                                Attachment a = new Attachment ();
                                a.url = n.attrs["url"].value;
                                a.name = a.url.substring (a.url.last_index_of_char ('/') + 1);
                                if (n.attrs.has_key ("length"))
                                    a.size = int.parse (n.attrs["length"].value);
                                if (n.attrs.has_key ("type"))
                                    a.mimetype = n.attrs["type"].value;

                                new_item.attachments.add (a);
                            } else
                                warning ("Failed to load attachment: No URL");
                        break;

                        default:
                            //stderr.printf ("Item element <%s> is not currently supported.\n", dat->name);
                        break;
                    }
                }
            }
            if (new_item.weak_guid == null || new_item.weak_guid == "") {
                if (new_item.link != null && new_item.link.length > 0) {
                    new_item.weak_guid = new_item.link;
                } else if (new_item.title.length > 0) {
                    new_item.weak_guid = new_item.title;
                } else if (new_item.content != null && new_item.content.length > 0) {
                    new_item.weak_guid = new_item.content;
                } else {
                    warning ("Could not establish GUID for feed, as it has no guid, title, link, or content");
                    return null;
                }
            }

            return new_item;
        }

        // Parses a <RDF> node to populate the internal feed
        private void readRDFFeed (GXml.Node node) {
            foreach (GXml.Node dat in node.children_nodes) {
                if (dat.type_node == GXml.NodeType.ELEMENT) {
                    switch (dat.name) {
                        case "channel":
                            foreach (GXml.Node cdat in dat.children_nodes) {
                                if (cdat.type_node == GXml.NodeType.ELEMENT) {
                                    switch (cdat.name) {
                                        case "title":
                                            stored_feed.title = cdat.value.strip ().replace ("&", "&amp;");
                                        break;

                                        case "link":
                                            stored_feed.site_link = cdat.value;
                                        break;

                                        case "description":
                                            stored_feed.description = cdat.value;
                                        break;
                                    }
                                }
                            }
                        break;

                        case "item":
                            Item? item = readRSSItem (dat);
                            if (item != null)
                                _data.add (item);
                        break;

                        default:
                            //stderr.printf ("Feed element <%s> is not currently supported.\n", dat->name);
                        break;
                    }
                }
            }
        }
    }
}
