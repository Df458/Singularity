using Gee;
using Xml;

// TODO: Schema validation
namespace Singularity
{
    static const string OPML_VERSION = "1.1";

    class OPMLFeedDataSource : ReversibleDataSource<CollectionNode, unowned Xml.Doc>
    {
        public override bool parse_data(Xml.Doc doc)
        {
            Xml.Node* node = doc.get_root_element();
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

        public override unowned Xml.Doc encode_data(Gee.List<CollectionNode> to_encode)
        {
            export_doc = new Xml.Doc();

            // TODO: Nest things by collection
            /* Ns* ns = null; */
            /* Xml.Node* base_node = export_doc.new_node(ns, "opml"); */
            /* base_node->new_prop("version", OPML_VERSION); */
            /* Xml.Node body_node = new Xml.Node(ns, "body"); */
            /* base_node->add_child(body_node); */
            /*  */
            /* // TODO: Add content type */
            /* foreach(Feed f in to_encode) { */
            /*     Xml.Node feed_node = new Xml.Node(ns, "outline"); */
            /*     body_node.add_child(feed_node); */
            /*     feed_node.new_prop("title", f.title); */
            /*     feed_node.new_prop("text",  f.title); */
            /*     feed_node.new_prop("xmlUri",  f.link); */
            /* } */

            return export_doc;
        }

        private Xml.Doc export_doc;

        private void parse_outline(Xml.Node node, FeedCollection collection)
        {
            string title;
            string? url;

            title = node.get_prop("text");
            if(title == null)
                return;

            url = node.get_prop("xmlUrl");

            if(url == null) {
                FeedCollection new_collection = new FeedCollection(title);
                for(Xml.Node* n = node.children; n != null; n = n->next)
                    parse_outline(n, new_collection);

                collection.add_node(new CollectionNode.with_collection(new_collection));
            } else {
                Feed new_feed  = new Feed();
                new_feed.title = title;
                new_feed.link  = url;

                collection.add_node(new CollectionNode.with_feed(new_feed));
            }
        }

        private void encode_outline(Xml.Node node, CollectionNode cn)
        {
            // TODO: Write out the contents of cn
        }
    }
}
