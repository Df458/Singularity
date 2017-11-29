namespace Singularity
{
// TODO: Implement this
public class GridViewBuilder : ViewBuilder, GLib.Object
{
    public string head;
    public const string builder_class = "grid";
    public  string star_svg = "file:///usr/local/share/singularity/star.svg";
    public  string read_svg = "file:///usr/local/share/singularity/read.svg";

    private bool is_tile = true;

    public GridViewBuilder()
    {
        try {
            head = "<head><style>\n%s\n%s\n</style></head>".printf(resource_to_string("default.css"), resource_to_string("grid.css"));
        } catch(Error e) {
            warning("Failed to read style information");
            head = "";
        }
    }

    public string buildPageHTML(Gee.List<Item> items, int limit)
    {
        is_tile = true;
        StringBuilder builder = new StringBuilder("<html>");
        builder.append(head);
        builder.append("<body onload=\"prepare()\"><section class=\"content\">");
        int id = 0;
        foreach(Item i in items) {
            builder.append(buildItemHTML(i, id));
            ++id;
            if(id == limit)
                break;
        }
        is_tile = false;
        id = 0;
        builder.append("</section>");
        builder.append("<div class=\"darkener full-hidden\" onclick=\"hide()\"></div>");
        foreach(Item i in items) {
            builder.append(buildItemHTML(i, id));
            ++id;
            if(id == limit)
                break;
        }
        builder.append("</body></html>");

        return builder.str;
    }

    public string buildItemHTML(Item item, int id)
    {
        StringBuilder builder = new StringBuilder();
        StringBuilder head_builder    = new StringBuilder("<header>");

        if(is_tile) {
            head_builder.append("<section class=\"title\">");
            head_builder.append_printf("%s</section>", item.title == "" ? "Untitled Post" : item.title);

            builder.append_printf("<article class=\"%s\" data-id=\"%d\" data-read=\"%s\" onclick=\"view_item(this)\" data-starred=\"%s\"", item.unread ? "unread %s".printf(builder_class) : builder_class, id, item.unread ? "false" : "true", item.starred ? "true" : "false");
            string? icon = extract_image(item.content);
            if(icon != null)
                builder.append_printf(" style=\"background-image: url(\'%s\');\"", icon);
            builder.append_printf(">%s</article>", head_builder.str);
        } else {
            head_builder.append("<section class=\"title\">");
            head_builder.append_printf("<a href=\"%s\">%s</a>", item.link, item.title == "" ? "Untitled Post" : item.title);
            head_builder.append("<div class=\"button-box\">");
            head_builder.append_printf("<img class=\"read-button\", src=\"%s\"/>", read_svg);
            head_builder.append_printf("<img class=\"star\", src=\"%s\"/>", star_svg);
            head_builder.append("</div>");
            head_builder.append("</section>");
            if(item.time_published.compare(new DateTime.from_unix_utc(0)) != 0) {
                string datestr = item.time_published.format("%A, %B %e %Y");
                head_builder.append_printf("Posted on <time class=\"date\" datetime=\"%s\">%s</time>", datestr, datestr);
            }
            // TODO: Posted by section
            head_builder.append("<hr>");
            head_builder.append("</header>");

            builder.append_printf("<article class=\"full-hidden full-article\">%s%s</article>", head_builder.str, item.content);
        }

        return builder.str;
    }
}
}
