using Gee;
using Xml;

// TODO: Schema validation
namespace Singularity
{
    static const string OPML_VERSION = "1.1";

    public class OPMLFeedDataSource : ReversibleDataSource<CollectionNode, Xml.Doc*>
    {
        public override bool parse_data(Xml.Doc* doc)
        {
            Xml.Node* node = doc->get_root_element();
            while(node != null && node->name != "opml")
                node = node->next;
    
            if(node == null) {
                return false;
            }
    
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

                collection.add_node(new CollectionNode.with_collection(new_collection));
            } else {
                Feed new_feed  = new Feed();
                new_feed.title = title;
                new_feed.link  = url;

                collection.add_node(new CollectionNode.with_feed(new_feed));
            }
        }

        private void encode_outline(Ns* ns, Xml.Node* node, CollectionNode cn)
        {
            // TODO: Write out the contents of cn
            Xml.Node* outline = new Xml.Node(ns, "outline");
            node->add_child(outline);

            if(cn.contents == CollectionNode.Contents.FEED) {
                outline->new_prop("xmlUrl",  cn.feed.link);
                outline->new_prop("title", cn.feed.title);
                outline->new_prop("text",  cn.feed.title);
            } else {
                foreach(CollectionNode child in cn.collection.nodes) {
                    outline->new_prop("title", cn.collection.title);
                    outline->new_prop("text",  cn.collection.title);
                    encode_outline(ns, outline, child);
                }
            }
        }
    }
}
