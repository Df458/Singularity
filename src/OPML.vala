using Gee;

class OPML
{
    public OPML()
    {
    }

    // TODO: Clean this up and add collection support
    public ArrayList<Feed> import(Xml.Node* node)
    {
        ArrayList<Feed> feeds = new ArrayList<Feed>();

        while(node != null && node->name != "opml")
            node = node->next;

        if(node == null) {
            if(verbose)
                stderr.printf("Error: No defining node was found\n");
            return feeds;
        }

        node = node->children;
        while(node != null && node->name != "body")
            node = node->next;

        if(node == null) {
            if(verbose)
                stderr.printf("Error: No body was found\n");
            return feeds;
        }

        for(node = node->children; node != null; node = node->next) {
            if(node->type == Xml.ElementType.ELEMENT_NODE) {
                if(node->name == "outline") {
                    if(node->has_prop("type") != null && node->has_prop("type")->children->content == "rss" && node->has_prop("xmlUrl") != null) {
                        app.createFeed(node->has_prop("xmlUrl")->children->content);
                    }
                    for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
                        if(dat->has_prop("type") != null && dat->has_prop("type")->children->content == "rss" && dat->has_prop("xmlUrl") != null) {
                            app.createFeed(dat->has_prop("xmlUrl")->children->content);
                        }
                    }
                }
            }
        }
        return feeds;
    }

    public bool export(File to_export)
    {
        return false;
    }
}
