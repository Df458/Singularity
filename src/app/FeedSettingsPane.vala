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

using Gtk;

namespace Singularity {
class FeedSettingsPane : VBox
{
    ButtonBox          confirm_buttons;
    CheckButton        rule_enable_button;
    RuleEntry          uu_entry;
    RuleEntry          ru_entry;
    RuleEntry          us_entry;
    RuleEntry          rs_entry;
    CheckButton        dl_enable_button;
    FileChooserButton  dl_location_button;
    CheckButton        dl_always_ask;
    Feed               current_feed;

    public signal void done();

    public FeedSettingsPane()
    {
        spacing = 6;
        margin = 18;
        confirm_buttons = new HButtonBox();
        Gtk.Button cancel_button = new Gtk.Button.with_label("Cancel");
        cancel_button.clicked.connect(() => {done();});
        Gtk.Button confirm_button = new Gtk.Button.with_label("Confirm");
        /* confirm_button.clicked.connect(save); */
        confirm_buttons.add(cancel_button);
        confirm_buttons.add(confirm_button);

        rule_enable_button = new CheckButton.with_label("Override global rule settings");
        rule_enable_button.toggled.connect(() => {
            uu_entry.set_sensitive(rule_enable_button.get_active());
            ru_entry.set_sensitive(rule_enable_button.get_active());
            us_entry.set_sensitive(rule_enable_button.get_active());
            rs_entry.set_sensitive(rule_enable_button.get_active());
        });
        uu_entry = new RuleEntry("unread and unstarred entries", false, false);
        ru_entry = new RuleEntry("read and unstarred entries", true, false);
        us_entry = new RuleEntry("unread and starred entries", false, true);
        rs_entry = new RuleEntry("read and starred entries", true, true);

        dl_enable_button = new CheckButton.with_label("Override global download settings");
        dl_enable_button.toggled.connect(() => {
            dl_location_button.set_sensitive(dl_enable_button.get_active());
            dl_always_ask.set_sensitive(dl_enable_button.get_active());
        });
        dl_location_button = new FileChooserButton("download to", FileChooserAction.SELECT_FOLDER);

        dl_always_ask = new CheckButton.with_label("Always ask for a location");

        Box dl_box = new Box(Orientation.HORIZONTAL, 0);
        dl_box.pack_start(new Label("download attachments to: "), false, false);
        dl_box.pack_start(dl_location_button, false, false);

        pack_start(rule_enable_button, false, false);
        pack_start(uu_entry, false, false);
        pack_start(ru_entry, false, false);
        pack_start(us_entry, false, false);
        pack_start(rs_entry, false, false);
        pack_start(new Gtk.Separator(Orientation.HORIZONTAL), false, false);
        pack_start(dl_enable_button, false, false);
        pack_start(dl_box, false, false);
        pack_start(dl_always_ask, false, false);
        pack_end(confirm_buttons, false, false);
        this.show_all();
    }

    /* public void sync(Feed f) */
    /* { */
    /*     current_feed = f; */
    /*     rule_enable_button.set_active(f.override_rules); */
    /*     // TODO: Replace these */
    /*     //uu_entry.sync(f.unread_unstarred_rule); */
    /*     //ru_entry.sync(f.read_unstarred_rule); */
    /*     //us_entry.sync(f.unread_starred_rule); */
    /*     //rs_entry.sync(f.read_starred_rule); */
    /*     uu_entry.set_sensitive(rule_enable_button.get_active()); */
    /*     ru_entry.set_sensitive(rule_enable_button.get_active()); */
    /*     us_entry.set_sensitive(rule_enable_button.get_active()); */
    /*     rs_entry.set_sensitive(rule_enable_button.get_active()); */
    /*     dl_enable_button.set_active(f.override_location); */
    /*     dl_always_ask.set_active(f.get_location); */
    /*     dl_location_button.set_sensitive(dl_enable_button.get_active()); */
    /*     dl_always_ask.set_sensitive(dl_enable_button.get_active()); */
    /*     dl_location_button.set_current_folder(f.default_location); */
    /* } */

    /* public void save() */
    /* { */
    /*     current_feed.override_rules = rule_enable_button.get_active(); */
    /*     // TODO: Replace these */
    /*     //current_feed.unread_unstarred_rule = uu_entry.get_value(); */
    /*     //current_feed.read_unstarred_rule = ru_entry.get_value(); */
    /*     //current_feed.unread_starred_rule = us_entry.get_value(); */
    /*     //current_feed.read_starred_rule = rs_entry.get_value();    */
    /*     current_feed.override_location = dl_enable_button.get_active(); */
    /*     current_feed.get_location = dl_always_ask.get_active(); */
    /*     current_feed.default_location = dl_location_button.get_filename(); */
    /*     // FIXME: Fix interdependency */
    /*     app.update_feed_settings(current_feed); */
    /*     done(); */
    /* } */
}
}
