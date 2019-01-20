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

namespace Singularity.App {
    /**
     * Popup window that displays feed information
     */
    [GtkTemplate (ui = "/org/df458/Singularity/PropertiesWindow.ui")]
    public class PropertiesWindow : Gtk.Window {
        /**
         * @param window The parent window
         * @param feed The Feed to display
         */
        public PropertiesWindow (Window window, Feed feed) {
            modal = true;
            window_position = WindowPosition.CENTER_ON_PARENT;
            set_transient_for (window);

            title_label.label = "<b>%s</b>".printf (feed.title);
            uri_entry.text = feed.link;
            if (feed.icon != null) {
                feed_icon.pixbuf = feed.icon;
            } else {
                feed_icon.icon_name = "application-rss+xml-symbolic";
            }

            site_link.label = "Go to website";
            site_link.uri = feed.site_link;
            link_revealer.reveal_child = feed.site_link != null && feed.site_link != "";

            description_label.label = (feed.description == null || feed.description == "")
                ? "No Description"
                : feed.description;
            rights_label.label = feed.rights ?? "None";

            if (feed.tags.size > 0) {
                var builder = new StringBuilder ();
                foreach (Tag t in feed.tags) {
                    builder.append ("%s, ".printf (t.label ?? t.name));
                }
                builder.erase (builder.len - 2);
                tags_label.label = builder.str;
            }

            Gee.List<Item> items = feed.get_items ();
            if (items.size != 0) {
                DateTime last_time = new DateTime.from_unix_utc (0);
                foreach (Item i in items) {
                    if (i.time_published.compare (last_time) > 0) {
                        last_time = i.time_published;
                    } else if (i.time_published.compare (new DateTime.from_unix_utc (0)) == 0) {
                        last_time = i.time_loaded;
                    }
                }

                last_time = last_time.to_local ();
                updated_label.label = "%d/%d/%04d, %02d:%02d".printf (
                        last_time.get_month (),
                        last_time.get_day_of_month (),
                        last_time.get_year (),
                        last_time.get_hour (),
                        last_time.get_minute ());
            }
        }

        [GtkCallback]
        private void on_copy_uri () {
            Clipboard.get_default (Gdk.Display.get_default ()).set_text (uri_entry.text, -1);
        }

        [GtkChild]
        private Label title_label;
        [GtkChild]
        private Image feed_icon;
        [GtkChild]
        private Entry uri_entry;
        [GtkChild]
        private LinkButton site_link;
        [GtkChild]
        private Label description_label;
        [GtkChild]
        private Label rights_label;
        [GtkChild]
        private Label tags_label;
        [GtkChild]
        private Label updated_label;
        [GtkChild]
        private Revealer link_revealer;
    }
}
