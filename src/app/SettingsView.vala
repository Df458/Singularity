/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

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
using Singularity;

[GtkTemplate (ui="/org/df458/Singularity/SettingsView.ui")]
class SettingsView : Box
{
    public void sync() {
        if(!AppSettings.auto_update)
            auto_update_combo.active = 0;
        else
            start_update_switch.set_active(AppSettings.start_update);
        auto_update_time_label.set_sensitive(AppSettings.auto_update);
        auto_update_time_entry.set_sensitive(AppSettings.auto_update);
        read_spin.set_value(AppSettings.read_rule[0]);
        unread_spin.set_value(AppSettings.unread_rule[0]);
        read_incr_combo.set_active(AppSettings.read_rule[1]);
        unread_incr_combo.set_active(AppSettings.unread_rule[1]);
        if(AppSettings.read_rule[2] == 1)
            read_action_combo.set_active(-1);
        else
            read_action_combo.set_active(AppSettings.read_rule[2] / 2); // 0 or 2 becomes 0 or 1
        unread_action_combo.set_active(AppSettings.unread_rule[2]);
        always_ask_check.set_active(AppSettings.ask_download_location);
        download_to_button.set_current_folder(AppSettings.default_download_location.get_path());
        download_to_label.set_sensitive(!AppSettings.ask_download_location);
        download_to_button.set_sensitive(!AppSettings.ask_download_location);
        link_command_entry.set_text(AppSettings.link_command);
        cookie_db_button.set_filename(AppSettings.cookie_db_path);
    }

    public signal void done();

    [GtkChild]
    private ComboBoxText auto_update_combo;
    [GtkChild]
    private Switch start_update_switch;
    [GtkChild]
    private SpinButton auto_update_time_entry;
    [GtkChild]
    private SpinButton read_spin;
    [GtkChild]
    private SpinButton unread_spin;
    [GtkChild]
    private ComboBoxText read_incr_combo;
    [GtkChild]
    private ComboBoxText unread_incr_combo;
    [GtkChild]
    private ComboBoxText read_action_combo;
    [GtkChild]
    private ComboBoxText unread_action_combo;
    [GtkChild]
    private Switch always_ask_check;
    [GtkChild]
    private FileChooserButton download_to_button;
    [GtkChild]
    private FileChooserButton cookie_db_button;
    [GtkChild]
    private Entry link_command_entry;
    [GtkChild]
    private Label auto_update_time_label;
    [GtkChild]
    private Label download_to_label;

    [GtkCallback]
    private void on_update_combo_changed() {
        int id = auto_update_combo.active;
        auto_update_time_entry.set_sensitive(false);
        auto_update_time_label.set_sensitive(false);
        switch(id) {
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
                auto_update_time_entry.set_sensitive(true);
                auto_update_time_label.set_sensitive(true);
            break;
        }
    }

    [GtkCallback]
    private bool should_always_ask(bool ask) {
        download_to_button.set_sensitive(!ask);
        download_to_label.set_sensitive(!ask);
        return false;
    }

    [GtkCallback]
    private void read_action_changed() {
        int id = read_action_combo.active;
        read_incr_combo.set_sensitive(id > 0);
        read_spin.set_sensitive(id > 0);
    }

    [GtkCallback]
    private void unread_action_changed() {
        int id = unread_action_combo.active;
        unread_incr_combo.set_sensitive(id > 0);
        unread_incr_combo.set_sensitive(id > 0);
        unread_spin.set_sensitive(id > 0);
    }

    [GtkCallback]
    private void save()
    {
        AppSettings.auto_update = auto_update_combo.active != 0;
        AppSettings.start_update = start_update_switch.get_active();
        AppSettings.read_rule[0] = (int)read_spin.get_value();
        AppSettings.read_rule[1] = read_incr_combo.get_active();
        if(read_action_combo.get_active() != -1)
            AppSettings.read_rule[2] = read_action_combo.get_active() * 2; // 0 or 1 becomes 0 or 2
        AppSettings.unread_rule[0] = (int)unread_spin.get_value();
        AppSettings.unread_rule[1] = unread_incr_combo.get_active();
        AppSettings.unread_rule[2] = unread_action_combo.get_active();
        AppSettings.ask_download_location = always_ask_check.get_active();
        AppSettings.default_download_location = File.new_for_path(download_to_button.get_filename());
        AppSettings.link_command = link_command_entry.text;
        AppSettings.cookie_db_path = cookie_db_button.get_filename();
        AppSettings.save();
        done();
    }

    [GtkCallback]
    private void reset()
    {
        start_update_switch.active   = true;
        auto_update_combo.active     = 2;
        always_ask_check.active      = true;
        link_command_entry.text      = "xdg-open %s";
        read_spin.value              = 6;
        read_incr_combo.active       = 1;
        read_action_combo.active     = 1;
        unread_spin.value            = 0;
        unread_incr_combo.active     = -1;
        unread_action_combo.active   = 0;
    }

    [GtkCallback]
    private void cancel() { done(); }
}
