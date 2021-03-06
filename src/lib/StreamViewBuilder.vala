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

namespace Singularity {
// Constructs HTML for the stream view
public class StreamViewBuilder : ViewBuilder, GLib.Object {
    public StreamViewBuilder (Gtk.StyleContext ctx, string empty_star_icon, string star_icon, string unread_icon, string read_icon) {
        try {
            head = "<head><style>\n%s\n%s\n%s\n%s\n</style></head>".printf (
                css_prepend.printf(empty_star_icon, star_icon, unread_icon, read_icon),
                resource_to_string ("default.css"),
                resource_to_string ("stream.css"),
                WebStyleBuilder.get_css (ctx)
                );
        } catch (Error e) {
            warning ("Failed to read style information");
        }
    }

    public string buildPageHTML (Gee.List<Item> items, int limit) {
        StringBuilder builder = new StringBuilder ("<html>");
        builder.append (head);
        builder.append ("<body onload=\"prepare ()\">");
        int id = 0;
        foreach (Item i in items) {
            builder.append (buildItemHTML (i, id));
            ++id;
            if (id == limit)
                break;
        }
        builder.append ("</body></html>");

        return builder.str;
    }

    public string buildItemHTML (Item item, int id) {
        StringBuilder builder = new StringBuilder ();
        StringBuilder head_builder = new StringBuilder ("<header>");
        StringBuilder content_builder = new StringBuilder ("<section class=\"content\">");
        StringBuilder footer_builder = new StringBuilder ("<footer>");

        head_builder.append ("<section class=\"title\">");
        head_builder.append_printf ("<a href=\"%s\">%s</a>",
            item.link,
            item.title == "" ? "Untitled Post" : item.title);
        head_builder.append ("<div class=\"button-box\">");
        head_builder.append_printf ("<img class=\"read-button\"/>");
        head_builder.append_printf ("<img class=\"star\"/>");
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

        if (item.icon != null)
        {
            content_builder.append_printf ("<img src=\"%s\" style=\"max-width: 25%; margin: 0 1em; float: left;\"/>", item.icon);
        }
        content_builder.append (item.content != null ? item.content : "No content");
        content_builder.append ("</section>");

        if (item.attachments.size > 0)
            content_builder.append ("<hr>");

        if (item.attachments.size > 0) {
            footer_builder.append ("<section class=\"attachments-list\">");
            foreach (Attachment a in item.attachments) {
                footer_builder.append_printf ("<span class=\"attachment\"><a href=\"%s\">%s</a> (%s, %d)</span>\n",
                    a.url,
                    a.name,
                    a.mimetype,
                    a.size);
            }
            footer_builder.append ("</section>");
        }

        // TODO: Tags
        footer_builder.append_printf ("</footer>");

        builder.append_printf ("<article class=\"%s\" data-id=\"%d\" data-read=\"%s\" data-starred=\"%s\">",
            builder_class,
            id,
            item.unread ? "false" : "true",
            item.starred ? "true" : "false");
        builder.append_printf (head_builder.str);
        builder.append_printf (content_builder.str);
        builder.append_printf (footer_builder.str);
        builder.append_printf ("</article>");

        return builder.str;
    }

    private string head = "";
    private const string css_prepend = @"html { --star-empty: url(%s); --star-filled: url(%s); --unread: url(%s); --read: url(%s); }";
    private const string builder_class = "stream";
}
}
