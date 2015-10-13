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
    Switch start_update_switch;
    SpinButton auto_update_time_entry;
    ButtonBox confirm_buttons;
    RuleEntry uu_entry;
    RuleEntry ru_entry;
    RuleEntry us_entry;
    RuleEntry rs_entry;
    FileChooserButton dl_location_button;
    CheckButton dl_always_ask;

    public signal void done();

    public SettingsPane() {
        spacing = 5;
        confirm_buttons = new HButtonBox();
        Gtk.Button cancel_button = new Gtk.Button.with_label("Cancel");
        cancel_button.clicked.connect(() => {done();});
        Gtk.Button confirm_button = new Gtk.Button.with_label("Confirm");
        confirm_button.clicked.connect(save);
        confirm_buttons.add(cancel_button);
        confirm_buttons.add(confirm_button);

        start_update_switch = new Switch();
        auto_update_switch = new Switch();
        auto_update_switch.state_set.connect((state) => {
            auto_update_time_entry.set_sensitive(state);
            return false;
        });
        auto_update_time_entry = new SpinButton.with_range(1, 10000, 1);
        auto_update_time_entry.snap_to_ticks = true;

        uu_entry = new RuleEntry("unread and unstarred entries", false, false);
        ru_entry = new RuleEntry("read and unstarred entries", true, false);
        us_entry = new RuleEntry("unread and starred entries", false, true);
        rs_entry = new RuleEntry("read and starred entries", true, true);

        Box start_update_box = new Box(Orientation.HORIZONTAL, 0);
        start_update_box.pack_start(new Label("Update subscriptions on startup: "), false, false);
        start_update_box.pack_start(start_update_switch, false, false);
        Box auto_update_box = new Box(Orientation.HORIZONTAL, 0);
        auto_update_box.pack_start(new Label("Auto-update subscriptions: "), false, false);
        auto_update_box.pack_start(auto_update_switch, false, false);
        auto_update_box.pack_start(new Label(" every "), false, false);
        auto_update_box.pack_start(auto_update_time_entry);
        auto_update_box.pack_start(new Label(" minutes."), false, false);

        dl_location_button = new FileChooserButton("download to", FileChooserAction.SELECT_FOLDER);

        dl_always_ask = new CheckButton.with_label("Always ask for a location");

        Box dl_box = new Box(Orientation.HORIZONTAL, 0);
        dl_box.pack_start(new Label("download attachments to: "), false, false);
        dl_box.pack_start(dl_location_button, false, false);

        pack_start(auto_update_box, false, false);
        pack_start(start_update_box, false, false);
        pack_start(new Gtk.Separator(Orientation.HORIZONTAL), false, false);
        pack_start(uu_entry, false, false);
        pack_start(ru_entry, false, false);
        pack_start(us_entry, false, false);
        pack_start(rs_entry, false, false);
        pack_start(new Gtk.Separator(Orientation.HORIZONTAL), false, false);
        pack_start(dl_box, false, false);
        pack_start(dl_always_ask, false, false);
        pack_end(confirm_buttons, false, false);
        this.show_all();
    }

    public void sync() {
        auto_update_switch.set_active(app.auto_update);
        start_update_switch.set_active(app.start_update);
        auto_update_time_entry.set_value(app.timeout_value / 60);
        auto_update_time_entry.set_sensitive(app.auto_update);
        uu_entry.sync(app.unread_unstarred_rule);
        ru_entry.sync(app.read_unstarred_rule);
        us_entry.sync(app.unread_starred_rule);
        rs_entry.sync(app.read_starred_rule);
        dl_always_ask.set_active(app.get_location);
        dl_location_button.set_current_folder(app.default_location);
    }

    public void save() {
        app.auto_update = auto_update_switch.get_active();
        app.start_update = start_update_switch.get_active();
        app.timeout_value = (int)auto_update_time_entry.get_value() * 60;
        app.unread_unstarred_rule = uu_entry.get_value();
        app.read_unstarred_rule = ru_entry.get_value();
        app.unread_starred_rule = us_entry.get_value();
        app.read_starred_rule = rs_entry.get_value();   
        app.get_location = dl_always_ask.get_active();
        app.default_location = dl_location_button.get_filename();
        app.update_settings();
        done();
    }
}
