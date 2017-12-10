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
using Singularity;

// Popup window that displays feed information
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
