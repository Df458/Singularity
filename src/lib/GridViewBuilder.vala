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
        error("buildPageHTML: Unimplemented");
    }

    public string buildItemHTML(Item item, int id)
    {
        error("buildItemHTML: Unimplemented");
    }
}
}
