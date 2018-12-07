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
using Gee;
using Xml;

namespace Singularity
{
    const string OPML_VERSION = "1.1";

    // DataSource for importing/exporting feeds from/to OPML files
    // TODO: Update to use GXml
    // TODO: Ensure that collection tree is always correct
    public class OPMLFeedDataSource : ReversibleDataSource<CollectionNode, Xml.Doc*>
    {
        public override bool parse_data(Xml.Doc* doc)
        {
            Xml.Node* node = doc->get_root_element();
            while(node != null && node->name != "opml")
                node = node->next;
    
            if(node == null)
                return false;
    
            node = node->children;
            while(node != null && node->name != "body")
                node = node->next;
    
            if(node == null) {
                return false;
            }
    
            FeedCollection root = new FeedCollection.root();
            for(node = node->children; node != null; node = node->next) {
                if(node->type == Xml.ElementType.ELEMENT_NODE && node->name == "outline") {
                    parse_outline(node, root);
                }
            }

            _data = root.nodes;

            return true;
        }

        public override Xml.Doc* encode_data(Gee.List<CollectionNode> to_encode)
        {
            Xml.Doc* export_doc = new Xml.Doc();

            Ns* ns = null;
            Xml.Node* base_node = export_doc->new_node(ns, "opml");
            export_doc->set_root_element(base_node);
            base_node->new_prop("version", OPML_VERSION);
            Xml.Node* body_node = new Xml.Node(ns, "body");
            base_node->add_child(body_node);

            foreach(CollectionNode cn in to_encode) {
                encode_outline(ns, body_node, cn);
            }

            return export_doc;
        }

        private void parse_outline(Xml.Node* node, FeedCollection collection)
        {
            string title;
            string? url;

            title = node->get_prop("text");
            if(title == null)
                return;

            url = node->get_prop("xmlUrl");

            if(url == null) {
                FeedCollection new_collection = new FeedCollection(title);
                for(Xml.Node* n = node->children; n != null; n = n->next)
                    parse_outline(n, new_collection);

                collection.add_node(new CollectionNode(new_collection));
            } else {
                Feed new_feed  = new Feed();
                new_feed.title = title;
                new_feed.link  = url;

                collection.add_node(new CollectionNode(new_feed));
            }
        }

        private void encode_outline(Ns* ns, Xml.Node* node, CollectionNode cn)
        {
            // TODO: Write out the contents of cn
            Xml.Node* outline = new Xml.Node(ns, "outline");
            node->add_child(outline);

            if(cn.data is Feed) {
                Feed feed = cn.data as Feed;
                outline->new_prop("xmlUrl",  feed.link);
                outline->new_prop("title", feed.title);
                outline->new_prop("text",  feed.title);
            } else {
                FeedCollection collection = cn.data as FeedCollection;
                outline->new_prop("title", collection.title);
                outline->new_prop("text",  collection.title);
                foreach(CollectionNode child in collection.nodes) {
                    encode_outline(ns, outline, child);
                }
            }
        }
    }
}
