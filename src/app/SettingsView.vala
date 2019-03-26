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
using DFLib;
using Gtk;

namespace Singularity {
    // View widget for viewing/editing application settings
    [GtkTemplate (ui="/org/df458/Singularity/SettingsView.ui")]
    class SettingsView : Bin {
        public void sync () {
            if (!AppSettings.auto_update) {
                auto_update_combo.active = 0;
            }
            start_update_switch.set_active (AppSettings.start_update);
            auto_update_time_label.set_sensitive (AppSettings.auto_update);
            auto_update_time_entry.set_sensitive (AppSettings.auto_update);
            link_command_entry.set_text (AppSettings.link_command);
            cookie_db_button.set_filename (AppSettings.cookie_db_path);
        }

        public signal void done ();

        [GtkChild]
        private ComboBoxText auto_update_combo;
        [GtkChild]
        private Switch start_update_switch;
        [GtkChild]
        private SpinButton auto_update_time_entry;
        [GtkChild]
        private FileChooserButton cookie_db_button;
        [GtkChild]
        private Entry link_command_entry;
        [GtkChild]
        private Label auto_update_time_label;

        [GtkCallback]
        private void on_update_combo_changed () {
            int id = auto_update_combo.active;
            auto_update_time_entry.set_sensitive (false);
            auto_update_time_label.set_sensitive (false);
            switch (id) {
                case 1:
                    auto_update_time_entry.value = 5;
                break;
                case 2:
                    auto_update_time_entry.value = 10;
                break;
                case 3:
                    auto_update_time_entry.value = 30;
                break;
                case 4:
                    auto_update_time_entry.value = 60;
                break;
                case 5:
                    auto_update_time_entry.set_sensitive (true);
                    auto_update_time_label.set_sensitive (true);
                break;
            }
        }

        [GtkCallback]
        private void save () {
            AppSettings.auto_update = auto_update_combo.active != 0;
            AppSettings.start_update = start_update_switch.get_active ();
            AppSettings.link_command = link_command_entry.text;
            AppSettings.cookie_db_path = cookie_db_button.get_filename ();
            AppSettings.save ();
            done ();
        }

        [GtkCallback]
        private void reset () {
            start_update_switch.active = true;
            auto_update_combo.active = 2;
            link_command_entry.text = "xdg-open %s";
        }

        [GtkCallback]
        private void cancel () {
            done ();
        }
    }
}
