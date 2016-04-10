using Gee;

namespace Singularity {
public class OPML
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
            // TODO: verbose
            /* if(verbose) */
            /*     stderr.printf("Error: No defining node was found\n"); */
            return feeds;
        }

        node = node->children;
        while(node != null && node->name != "body")
            node = node->next;

        if(node == null) {
            // TODO: verbose
            /* if(verbose) */
            /*     stderr.printf("Error: No body was found\n"); */
            return feeds;
        }

        stderr.printf("Entering body...\n");
        for(node = node->children; node != null; node = node->next) {
            if(node->type == Xml.ElementType.ELEMENT_NODE) {
                if(node->name == "outline") {
                    stderr.printf("Found outline node...\n");
                    if(node->has_prop("xmlUrl") != null) {
                        stderr.printf("Creating feed...\n");
                        // TODO: Fix interdependency
                        /* app.createFeed(node->has_prop("xmlUrl")->children->content); */
                    }
                    stderr.printf("Iterating Children...\n");
                    for(Xml.Node* dat = node->children; dat != null; dat = dat->next) {
                        if(dat->has_prop("xmlUrl") != null) {
                            stderr.printf("Creating feed...\n");
                            // FIXME: Fix interdependency
                            /* app.createFeed(dat->has_prop("xmlUrl")->children->content); */
                        }
                    }
                }
            }
        }
        return feeds;
    }

    public bool export(File to_export, ArrayList<Feed> feeds)
    {
        Xml.TextWriter writer = new Xml.TextWriter.filename(to_export.get_uri());
        writer.set_indent(true);

        // TODO: Nest things by collection
        writer.start_document();
        writer.start_element("opml");
        writer.write_attribute("version", "1.1");
        writer.start_element("body");
        // TODO: Add content type
        foreach(Feed f in feeds) {
            writer.start_element("outline");
            /* writer.write_attribute("title",  f.title); */
            /* writer.write_attribute("text",   f.title); */
            /* writer.write_attribute("xmlUrl", f.origin_link); */
            writer.end_element();
        }
        writer.end_element();
        writer.end_element();
        writer.end_document();
        return false;
    }
}
}
