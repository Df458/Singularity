/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2014  Hugues Ross <hugues.ross@gmail.com>

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

// modules: webkit2gtk-4.0 libsoup-2.4 granite libxml-2.0 sqlheavy-0.1 glib-2.0 gee-0.8

using Gtk;

class SettingsPane : VBox {
    Switch auto_update_switch;
    SpinButton auto_update_time_entry;
    ButtonBox confirm_buttons;

    public signal void done();

    public SettingsPane() {
        confirm_buttons = new HButtonBox();
        Gtk.Button cancel_button = new Gtk.Button.with_label("Cancel");
        cancel_button.clicked.connect(() => {done();});
        Gtk.Button confirm_button = new Gtk.Button.with_label("Confirm");
        confirm_button.clicked.connect(save);
        confirm_buttons.add(cancel_button);
        confirm_buttons.add(confirm_button);

        auto_update_switch = new Switch();
        auto_update_switch.state_set.connect((state) => {
            auto_update_time_entry.set_sensitive(state);
            return false;
        });
        auto_update_time_entry = new SpinButton.with_range(1, 10000, 1);
        auto_update_time_entry.snap_to_ticks = true;

        pack_start(auto_update_switch);
        pack_start(auto_update_time_entry);
        pack_end(confirm_buttons);
        this.show_all();
    }

    public void sync() {
        auto_update_switch.set_active(app.auto_update);
        auto_update_time_entry.set_value(app.timeout_value / 60);
    }

    public void save() {
        app.auto_update = auto_update_switch.get_active();
        app.timeout_value = (int)auto_update_time_entry.get_value() * 60;
        app.update_settings();
        done();
    }
}
