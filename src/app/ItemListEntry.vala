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
using Gtk;

namespace Singularity
{
// Widget used for the ColumnView's item list
[GtkTemplate (ui = "/org/df458/Singularity/ItemListEntry.ui")]
public class ItemListEntry : Box {
    public Item item { get; construct; }

    public ItemListEntry(Item i) {
        Object(item: i);
        if(i.title == "" || i.title == null)
            title_label.label = "Untitled";
        else
            title_label.label = i.title.replace("\n", " ");
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

        update_view();
    }

    public void viewed() {
        Pango.AttrList list = new Pango.AttrList();
        title_label.attributes = list;

        update_view();
    }

    public void update_view() {
        unread_indicator.reveal_child = item.unread || item.starred;
        unread_icon.set_from_icon_name(item.starred ? "starred-symbolic" : "mail-unread", IconSize.LARGE_TOOLBAR);
    }

    [GtkChild]
    private Label title_label;
    [GtkChild]
    private Label description_label;
    [GtkChild]
    private Revealer unread_indicator;
    [GtkChild]
    private Image unread_icon;
}
}
