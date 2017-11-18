/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

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
using Singularity;

public class ColumnViewBuilder : ViewBuilder, GLib.Object
{
    public string head;
    public const string builder_class = "column";
    public string star_svg = "file:///usr/local/share/singularity/star.svg";
    public string read_svg = "file:///usr/local/share/singularity/read.svg";
    public int page = -1;

    public ColumnViewBuilder()
    {
        try {
            File css_resource = File.new_for_uri("resource:///org/df458/Singularity/default.css");
            FileInputStream stream = css_resource.read();
            DataInputStream data_stream = new DataInputStream(stream);

            StringBuilder builder = new StringBuilder("<head><style>\n");
            string? str = data_stream.read_line();
            do {
                builder.append(str + "\n");
                str = data_stream.read_line();
            } while(str != null);
            builder.append_printf("</style></head>");
            head = builder.str;
        } catch(Error e) {
            warning("Failed to read style information");
            head = "";
        }
    }

    public string buildPageHTML(Gee.List<Item> items, int limit)
    {
        StringBuilder builder = new StringBuilder("<html>");
        builder.append(head);

        if(page > items.size || page < 0) {
            builder.append("</html>");
            return builder.str;
        }

        builder.append_printf("<body>%s</body></html>", buildItemHTML(items[page], 0));

        return builder.str;
    }

    public string buildItemHTML(Item item, int id)
    {
        StringBuilder builder = new StringBuilder();

        StringBuilder head_builder    = new StringBuilder("<header>");
        StringBuilder content_builder = new StringBuilder("<section class=\"content\">");
        StringBuilder footer_builder  = new StringBuilder("<footer>");

        head_builder.append("<section class=\"title\">");
        head_builder.append_printf("<a href=\"%s\">%s</a>", item.link, item.title == "" ? "Untitled Post" : item.title);
        head_builder.append("<div>");
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

        content_builder.append(item.content != null ? item.content : "No content");
        content_builder.append("</section>");

        if(item.attachments.size > 0) {
            footer_builder.append("<section class=\"attachments-list\">");
            foreach(Attachment a in item.attachments) {
                footer_builder.append_printf("<span class=\"attachment\"><a href=\"%s\">%s</a> (%s, %d)</span> ", a.url, a.name, a.mimetype, a.size);
            }
            footer_builder.append("</section>");
        }
        // TODO: Tags
        footer_builder.append_printf("</footer>");

        builder.append_printf("<article class=\"%s\" data-id=\"%d\" data-read=\"%s\" data-starred=\"%s\">%s%s%s</article>", builder_class, id, item.unread ? "false" : "true", item.starred ? "true" : "false", head_builder.str, content_builder.str, footer_builder.str);
        ++id;

        return builder.str;
    }
}
