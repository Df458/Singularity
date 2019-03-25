namespace Singularity {
// Constructs HTML for the column view
public class GridViewBuilder : ViewBuilder, GLib.Object {
    public GridViewBuilder (Gtk.StyleContext ctx) {
        try {
            head = "<head><style>\n%s\n%s\n%s\n</style></head>".printf (
                resource_to_string ("default.css"),
                resource_to_string ("grid.css"),
                WebStyleBuilder.get_css (ctx)
                );
        } catch (Error e) {
            warning ("Failed to read style information");
        }
    }

    public string buildPageHTML (Gee.List<Item> items, int limit) {
        is_tile = true;
        StringBuilder builder = new StringBuilder ("<html>");
        builder.append (head);
        builder.append ("<body onload=\"prepare ()\"><section class=\"content\">");
        int id = 0;
        foreach (Item i in items) {
            builder.append (buildItemHTML (i, id));
            ++id;
            if (id == limit)
                break;
        }
        is_tile = false;
        id = 0;
        builder.append ("</section>");
        builder.append ("<div class=\"darkener full-hidden\" onclick=\"hide ()\"></div>");
        foreach (Item i in items) {
            builder.append (buildItemHTML (i, id));
            ++id;
            if (id == limit)
                break;
        }
        builder.append ("</body></html>");

        return builder.str;
    }

    private string buildItemHTML (Item item, int id) {
        StringBuilder builder = new StringBuilder ();
        StringBuilder head_builder = new StringBuilder ("<header>");

        if (is_tile) {
            head_builder.append ("<section class=\"title\">");
            head_builder.append_printf ("%s</section>", item.title == "" ? "Untitled Post" : item.title);

            builder.append_printf ("<article class=\"%s\" data-id=\"%d\" data-read=\"%s\" data-starred=\"%s\"",
                item.unread ? "unread %s".printf (builder_class) : builder_class, id,
                item.unread ? "false" : "true",
                item.starred ? "true" : "false");
            builder.append (" onclick=\"view_item (this)\"");
            string? icon = extract_image (item.content);
            if (icon != null)
                builder.append_printf (" style=\"background-image: url (\'%s\');\"", icon);
            builder.append_printf (">%s</article>", head_builder.str);
        } else {
            head_builder.append ("<section class=\"title\">");
            head_builder.append_printf ("<a href=\"%s\">%s</a>",
                item.link,
                item.title == "" ? "Untitled Post" : item.title);
            head_builder.append ("<div class=\"button-box\">");
            head_builder.append_printf ("<img class=\"read-button\", src=\"%s\"/>", read_svg);
            head_builder.append_printf ("<img class=\"star\", src=\"%s\"/>", star_svg);
            head_builder.append ("</div>");
            head_builder.append ("</section>");
            if (item.author != null || item.time_published.compare (new DateTime.from_unix_utc (0)) != 0)
                head_builder.append ("Posted ");
            if (item.time_published.compare (new DateTime.from_unix_utc (0)) != 0) {
                string datestr = item.time_published.format ("%A, %B %e %Y");
                head_builder.append_printf ("on <time class=\"date\" datetime=\"%s\">%s</time> ", datestr, datestr);
            }
            if (item.author != null) {
                if (item.author.url != null)
                    head_builder.append_printf ("<a href=\"%s\">", item.author.url);
                if (item.author.name != null)
                    head_builder.append_printf ("by %s", item.author.name);
                else if (item.author.email != null)
                    head_builder.append_printf ("by %s", item.author.email);
                if (item.author.url != null)
                    head_builder.append_printf ("</a>");
            }

            head_builder.append ("<hr>");
            head_builder.append ("</header>");

            builder.append_printf ("<article class=\"full-hidden full-article\">%s%s</article>",
                head_builder.str,
                item.content);
        }

        return builder.str;
    }

    private string head = "";
    private bool is_tile = true;

    private const string builder_class = "grid";
    private const string star_svg = "file:///usr/local/share/singularity/star.svg";
    private const string read_svg = "file:///usr/local/share/singularity/read.svg";
}
}
