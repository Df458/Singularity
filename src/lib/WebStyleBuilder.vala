using Gtk;

namespace Singularity {
    public class WebStyleBuilder {
        public static string get_css (StyleContext ctx) {
            Value font_family = ctx.get_property ("font-family", Gtk.StateFlags.NORMAL);
            Value font_size = ctx.get_property ("font-size", Gtk.StateFlags.NORMAL);
            Gdk.RGBA foreground = ctx.get_color (Gtk.StateFlags.NORMAL);
            string[] family = (string[])font_family;

            string template =
                """body {
                    font-family: "%s";
                    font-size: %s;
                    color: %s;
                }""";

            return template.printf (
                family[0],
                font_size.get_double ().to_string (),
                foreground.to_string ()
            );
        }
    }
}
