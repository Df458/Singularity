using Gee;
using Xml;

// TODO: Schema validation
namespace Singularity
{

    static const string OPML_VERSION = "1.1";

    class OPMLFeedDataSource : ReversibleDataSource<Feed, unowned Xml.Doc>
    {
        public override bool parse_data(Xml.Doc doc)
        {
            _data = new ArrayList<Feed>();
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
    
            for(node = node->children; node != null; node = node->next) {
                if(node->type == Xml.ElementType.ELEMENT_NODE) {
                    if(node->name == "outline") {
                        if(node->has_prop("xmlUrl") != null) {
                            // TODO: Fix interdependency
                            /* app.createFeed(node->has_prop("xmlUrl")->children->content); */
                        }
                        for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
                            if(dat->has_prop("xmlUrl") != null) {
                                // FIXME: Fix interdependency
                                /* app.createFeed(dat->has_prop("xmlUrl")->children->content); */
                            }
                        }
                    }
                }
            }
            return true;
        }

        public override unowned Xml.Doc encode_data(Gee.List<Feed> to_encode)
        {
            export_doc = new Xml.Doc();

            // TODO: Nest things by collection
            Ns* ns = null;
            Xml.Node* base_node = export_doc.new_node(ns, "opml");
            base_node->new_prop("version", OPML_VERSION);
            Xml.Node body_node = new Xml.Node(ns, "body");
            base_node->add_child(body_node);

            // TODO: Add content type
            foreach(Feed f in to_encode) {
                Xml.Node feed_node = new Xml.Node(ns, "outline");
                body_node.add_child(feed_node);
                feed_node.new_prop("title", f.title);
                feed_node.new_prop("text",  f.title);
                feed_node.new_prop("xmlUri",  f.link);
            }

            return export_doc;
        }

        private Xml.Doc export_doc;
    }
}
