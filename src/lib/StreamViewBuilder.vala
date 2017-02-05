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

namespace Singularity
{
public class StreamViewBuilder : ViewBuilder, GLib.Object
{
    public string head;
    public const string builder_class = "stream";
    public  string star_svg = "file:///usr/local/share/singularity/star.svg";
    public  string read_svg = "file:///usr/local/share/singularity/read.svg";

    public StreamViewBuilder()
    {
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
    }

    public string buildPageHTML(Gee.List<Item> items, int limit)
    {
        StringBuilder builder = new StringBuilder("<html>");
        builder.append(head);
        builder.append("<body onload=\"prepare()\">");
        int id = 0;
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
        head_builder.append("<hr>");
        head_builder.append("</header>");

        content_builder.append(item.content != null ? item.content : "No content");
        content_builder.append("</section>");

        // TODO: Attachments
        // TODO: Tags
        footer_builder.append_printf("</footer>");

        builder.append_printf("<article class=\"%s\" data-id=\"%d\" data-read=\"%s\" data-starred=\"%s\">%s%s%s</article>", builder_class, id, item.unread ? "false" : "true", item.starred ? "true" : "false", head_builder.str, content_builder.str, footer_builder.str);

        return builder.str;
    }
}
}
