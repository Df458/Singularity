/*
     Singularity - A web newsfeed aggregator
     Copyright (C) 2020  Hugues Ross <hugues.ross@gmail.com>

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
using Gee;

namespace Singularity {
    /**
     * Widget for displaying a single feed's update error message
     */
    [GtkTemplate (ui = "/org/df458/Singularity/ErrorLabel.ui")]
    public class ErrorLabel : Bin {
        public ErrorLabel (Feed feed, string message) {
            title_label.label = feed.title;
            error_label.label = message;

            if (feed.icon != null) {
                feed_icon.pixbuf = feed.icon;
            }
        }

        [GtkCallback]
        public void on_copy () {
            var clipboard = Clipboard.get_default (get_display ());
            clipboard.set_text ("%s: %s".printf(title_label.label, error_label.label), -1);
        }

        [GtkChild]
        private Label error_label;

        [GtkChild]
        private Image feed_icon;

        [GtkChild]
        private Label title_label;
    }
}
