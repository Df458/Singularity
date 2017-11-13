using Gtk;
using Singularity;

[GtkTemplate (ui = "/org/df458/Singularity/PropertiesWindow.ui")]
public class PropertiesWindow : Gtk.Window
{
    [GtkChild]
        public Label title_label;
    [GtkChild]
        public Image feed_icon;
    [GtkChild]
        public Entry uri_entry;

    public void set_feed(Feed f)
    {
        title_label.label = f.title;
        uri_entry.text = f.link;
        if(f.icon != null)
            feed_icon.pixbuf = f.icon;
        else
            feed_icon.icon_name = "application-rss+xml-symbolic";
    }
}
