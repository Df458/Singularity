using Gtk;
using Singularity;

[GtkTemplate (ui = "/org/df458/Singularity/ItemListEntry.ui")]
public class ItemListEntry : Grid {
    public Item item { get; construct; }
    public ItemListEntry(Item i) {
        Object(item: i);
        title_label.label = i.title;
        if(i.content == "" || i.content == null) {
            description_label.visible = false;
        } else {
            string desc = xml_to_plain(i.content);
            description_label.label = desc.substring(0, desc.index_of("\n"));
        }
        Pango.AttrList list = new Pango.AttrList();
        list.insert(Pango.attr_weight_new(Pango.Weight.BOLD));
        if(item.unread)
            title_label.attributes = list;
        unread_icon.reveal_child = item.unread;
    }

    public void viewed() {
        Pango.AttrList list = new Pango.AttrList();
        title_label.attributes = list;
        unread_icon.reveal_child = false;
    }

    [GtkChild]
    private Label title_label;
    [GtkChild]
    private Label description_label;
    [GtkChild]
    private Revealer unread_icon;
}
