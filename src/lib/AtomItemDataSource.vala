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
using GXml;

namespace Singularity {
    // FeedProvider implementation for Atom feeds
    // Parses Atom feeds and converts them into Feed objects
    // TODO: Simplify the parser functions by taking better advantage of GXml
    class AtomItemDataSource : FeedProvider {
        // Main parsing function, takes a GXml.GDocument and uses it to init
        // its internal feed
        // Returns true if successful
        public override bool parse_data (GXml.GDocument doc) {
            stored_feed = new Feed ();
            stored_feed.last_update = new DateTime.now_utc ();
            _data = new Gee.ArrayList<Item> ();
            GXml.Node? node = doc["feed"];

            if (node == null)
                return false;

            readAtomFeed (node);

            return true;
        }

        // Parses a <feed> node to populate the internal feed
        private void readAtomFeed (GXml.Node node) {
            foreach (GXml.Node n in node.children_nodes) {
                if (n.type_node == GXml.NodeType.ELEMENT) {
                    switch (n.name) {
                        case "title":
                            stored_feed.title = n.value.strip ().replace ("&", "&amp;");
                        break;

                        case "link":
                            stored_feed.site_link = n.value;
                        break;

                        case "icon":
                            IconRequest req = new IconRequest (n.value);
                            if (req.send ()) {
                                stored_feed.icon = req.buf;
                            }
                        break;

                        case "description":
                            stored_feed.description = n.value;
                        break;

                        case "entry":
                            Item item = readAtomItem (n);
                            if (item != null)
                                _data.add (item);
                        break;

                        default:
                            //stderr.printf ("Feed element <%s> is not currently supported.\n", node->name);
                        break;
                    }
                }
            }
        }

        // Parses an <entry> node and tries to create a new Item from it
        // Returns the item if successful, otherwise returns null
        private Item? readAtomItem (GXml.Node node) {
            Item new_item = new Item ();

            foreach (GXml.Node dat in node.children_nodes) {
                if (dat.type_node == GXml.NodeType.ELEMENT) {
                    switch (dat.name) {
                        case "title":
                            new_item.title = dat.value;
                        break;

                        case "link":
                            if (!dat.attrs.has_key ("rel") || dat.attrs["rel"].value == "alternate") {
                                new_item.link = dat.attrs["href"].value;
                            } else if (dat.attrs["rel"].value == "enclosure") {
                                Attachment a = new Attachment ();
                                a.url = dat.attrs["href"].value;
                                if (dat.attrs.has_key ("title"))
                                    a.name = dat.attrs["title"].value;
                                else
                                    a.name = a.url.substring (a.url.last_index_of_char ('/') + 1);
                                if (dat.attrs.has_key ("length"))
                                    a.size = int.parse (dat.attrs["length"].value);
                                if (dat.attrs["type"] != null)
                                    a.mimetype = dat.attrs["type"].value;

                                new_item.attachments.add (a);
                            }
                        break;

                        case "content":
                        case "summary":
                            if (new_item.content == null
                                || new_item.content.strip () == ""
                                || dat.attrs["type"].value == "html"
                                || dat.attrs["type"].value == "xhtml") {
                                if (dat.attrs["type"].value == "xhtml") {
                                    StringBuilder builder = new StringBuilder ();
                                    foreach (GXml.Node child in dat.children_nodes)
                                        if (child.type_node == GXml.NodeType.ELEMENT) {
                                            builder.append (child.to_string () + "\n");
                                        }
                                    new_item.content = builder.str;
                                } else {
                                    new_item.content = dat.value;
                                }
                            }
                        break;


                        case "id":
                        case "guid":
                            new_item.weak_guid = dat.value;
                        break;

                        case "updated":
                            string input = dat.value;
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

                        case "author":
                        case "creator":
                            new_item.author = new Person.from_xml (dat);
                        break;

                        case "enclosure":
                            if (dat.attrs["url"] != null) {
                                Attachment a = new Attachment ();
                                a.url = dat.attrs["url"].value;
                                if (dat.attrs["length"] != null)
                                    a.size = int.parse (dat.attrs["length"].value);
                                if (dat.attrs["type"] != null)
                                    a.mimetype = dat.attrs["type"].value;

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
            if (new_item.guid == null || new_item.guid == "") {
                if (new_item.link != null && new_item.link.length > 0) {
                    new_item.weak_guid = new_item.link;
                } else if (new_item.title != null && new_item.title.length > 0) {
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
    }
}
