namespace Singularity
{
// TODO: Implement this
public class GridViewBuilder : ViewBuilder, GLib.Object
{
    public string head;
    public const string builder_class = "grid";
    public  string star_svg = "file:///usr/local/share/singularity/star.svg";

    public GridViewBuilder()
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
