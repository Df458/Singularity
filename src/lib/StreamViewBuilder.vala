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

namespace Singularity {
public class StreamViewBuilder : ViewBuilder, GLib.Object
{
    public string head;
    public static const string builder_class = "stream";
    public  string star_svg = "file:///usr/local/share/singularity/star.svg";

    public StreamViewBuilder(string css_data, string star_data)
    {
        StringBuilder builder = new StringBuilder("<head><style>");
        builder.append_printf("%s</style></head>", css_data);
        head = builder.str;
        star_svg = star_data;
    }

    public string buildHTML(Gee.List<Item> items)
    {
        StringBuilder builder = new StringBuilder("<html>");
//        builder.append(head);
//        builder.append("<body>");
//        foreach(Item i in items) {
//            StringBuilder head_builder    = new StringBuilder("<header ");
//            StringBuilder content_builder = new StringBuilder("<section ");
//            StringBuilder footer_builder  = new StringBuilder("<footer ");
//
//            head_builder.append_printf("class=\"%s\">", builder_class);
//            head_builder.append_printf("<img class=\"%s star\" %s, src=\"data:image/svg;base64,%s\"/>", builder_class, i.starred ? "id=\"active\"" : "", star_svg);
//            head_builder.append_printf("<h1 class=\"%s title\"><a href=\"%s\">%s</a></h1>", builder_class, i.link, i.title == "" ? "Untitled Post" : i.title);
//            // TODO: Posted section
//            head_builder.append_printf("<hr class=\"%s\" id=\"header-separator\"/>", builder_class);
//
//            content_builder.append_printf("class=\"%s content\">%s</section>", builder_class, i.description != null ? i.description : "No content");
//
//            footer_builder.append_printf("class=\"%s\">", builder_class);
//            // TODO: Attachments
//            // TODO: Tags
//            footer_builder.append_printf("</footer>");
//
//            builder.append_printf("<article class=\"%s\">%s%s%s</article>", builder_class, head_builder.str, content_builder.str, footer_builder.str);
//        }
//        builder.append("</body></html>");

        return builder.str;
    }
}
}
