namespace Singularity
{
// TODO: Implement this
public class GridViewBuilder : ViewBuilder, GLib.Object
{
    public string head;
    public static const string builder_class = "grid";
    public  string star_svg = "file:///usr/local/share/singularity/star.svg";

    public GridViewBuilder(string css_data, string star_data)
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
//        builder.append_printf("<body class=\"%s\">", builder_class);
//        foreach(Item i in items) {
//            builder.append_printf("<article class=\"%s\">", builder_class);
//            builder.append_printf("<div class=\"%s\" id=\"preview\">", builder_class);
//            builder.append_printf("<h1 class=\"%s title\"><a href=\"%s\">%s</a></h1>", builder_class, i.link, i.title);
//            builder.append("</div>");
//            // TODO: Tags
//            builder.append("</article>");
//        }
//
//        builder.append("</body></html>");

        return builder.str;
    }
}
}
