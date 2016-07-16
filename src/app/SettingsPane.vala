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

using Gtk;

namespace Singularity {

class SettingsPane : SettingsGrid
{
    public SettingsPane(GlobalSettings gs)
    {
        settings = gs;

        row_spacing = 18;
        column_spacing = 12;
        halign = Align.CENTER;

        init_structure();
        init_content();
        connect_signals();

        this.show_all();
    }

    public void sync()
    {
        if(!settings.auto_update)
            auto_update_combo.active = 0;
        else
            /* switch(settings.timeout_value / 60) { */
            /*     case 5: */
            /*         auto_update_combo.active = 1; */
            /*         break; */
            /*     case 10: */
            /*         auto_update_combo.active = 2; */
            /*         break; */
            /*     case 30: */
            /*         auto_update_combo.active = 3; */
            /*         break; */
            /*     case 60: */
            /*         auto_update_combo.active = 4; */
            /*         break; */
            /*     default: */
            /*         auto_update_combo.active = 5; */
            /*         break; */
            /* } */
        start_update_switch.set_active(settings.start_update);
        /* auto_update_time_entry.set_value(settings.timeout_value / 60); */
        this.get_label_for_child(auto_update_time_entry).set_sensitive(settings.auto_update);
        auto_update_time_entry.set_sensitive(settings.auto_update);
        read_spin.set_value(settings.read_rule[0]);
        unread_spin.set_value(settings.unread_rule[0]);
        read_incr_combo.set_active(settings.read_rule[1]);
        unread_incr_combo.set_active(settings.unread_rule[1]);
        if(settings.read_rule[2] == 1)
            read_action_combo.set_active(-1);
        else
            read_action_combo.set_active(settings.read_rule[2] / 2); // 0 or 2 becomes 0 or 1
        unread_action_combo.set_active(settings.unread_rule[2]);
        always_ask_check.set_active(settings.ask_download_location);
        download_to_button.set_current_folder(settings.default_download_location.get_path());
        download_to_button.set_sensitive(!settings.ask_download_location);
        link_command_entry.set_text(settings.link_command);
    }

    public signal void done();

    private GlobalSettings settings;

    // Update Controls
    private Switch start_update_switch;
    private ComboBoxText   auto_update_combo;
    private SpinButton     auto_update_time_entry;

    // Link and Attachment Controls
    private Box       download_box;
    private FileChooserButton download_to_button;
    private CheckButton       always_ask_check;
    private Entry             link_command_entry;

    // Rule Controls
    private Box          unread_box;
    private Box          read_box;
    private SpinButton   unread_spin;
    private SpinButton   read_spin;
    private ComboBoxText unread_incr_combo;
    private ComboBoxText read_incr_combo;
    private ComboBoxText unread_action_combo;
    private ComboBoxText read_action_combo;

    private ButtonBox confirm_buttons;
    private Button confirm_button;
    private Button cancel_button;
    private Button reset_button;

    private void init_structure()
    {
        download_box       = new Box(Orientation.HORIZONTAL, 6);
        confirm_buttons    = new ButtonBox(Orientation.HORIZONTAL);
        unread_box         = new Box(Orientation.HORIZONTAL, 0);
        read_box           = new Box(Orientation.HORIZONTAL, 0);

        confirm_buttons.set_spacing(6);
        confirm_buttons.set_layout(ButtonBoxStyle.START);

        read_box.get_style_context().add_class(STYLE_CLASS_LINKED);
        unread_box.get_style_context().add_class(STYLE_CLASS_LINKED);

        this.attach(confirm_buttons,    0, 3, 2, 1);
    }

    private void init_content()
    {
        link_command_entry = new Entry();

        confirm_button = new Button.with_label("Confirm");
        cancel_button  = new Button.with_label("Cancel");
        reset_button   = new Button.with_label("Reset");

        start_update_switch    = new Switch();
        auto_update_combo      = new ComboBoxText();
        auto_update_time_entry = new SpinButton.with_range(1, 1000, 1);
        download_to_button     = new FileChooserButton("download to", FileChooserAction.SELECT_FOLDER);
        always_ask_check       = new CheckButton.with_label("Always ask");
        read_spin              = new SpinButton.with_range(1, 1000, 1);
        unread_spin            = new SpinButton.with_range(1, 1000, 1);
        read_incr_combo        = new ComboBoxText();
        unread_incr_combo      = new ComboBoxText();
        read_action_combo      = new ComboBoxText();
        unread_action_combo    = new ComboBoxText();

        start_update_switch.halign     = Align.START;

        auto_update_combo.append_text("Never");
        auto_update_combo.append_text("Every 5 Minutes");
        auto_update_combo.append_text("Every 10 Minutes");
        auto_update_combo.append_text("Every 30 Minutes");
        auto_update_combo.append_text("Every Hour");
        auto_update_combo.append_text("Custom\u2026");

        read_incr_combo.append_text("Days");
        read_incr_combo.append_text("Months");
        read_incr_combo.append_text("Years");
        unread_incr_combo.append_text("Days");
        unread_incr_combo.append_text("Months");
        unread_incr_combo.append_text("Years");
        read_action_combo.append_text("Do Nothing");
        read_action_combo.append_text("Delete");
        unread_action_combo.append_text("Do Nothing");
        unread_action_combo.append_text("Mark Read");
        unread_action_combo.append_text("Delete");

        reset_button.get_style_context().add_class("destructive-action");

        download_box.add(download_to_button);
        download_box.add(always_ask_check);
        this.add("Update on Startup", start_update_switch, 0);
        this.add("Auto-update", auto_update_combo, 0);
        this.add("Update Time (minutes)", auto_update_time_entry, 0);
        this.add("Download to", download_box, 1);
        this.add("Custom Link Command", link_command_entry, 1);
        read_box.add(read_spin);
        read_box.add(read_incr_combo);
        read_box.add(read_action_combo);
        this.add("Read Items", read_box, 2);
        unread_box.add(unread_spin);
        unread_box.add(unread_incr_combo);
        unread_box.add(unread_action_combo);
        this.add("Unread Items", unread_box, 2);
        confirm_buttons.add(confirm_button);
        confirm_buttons.add(cancel_button);
        confirm_buttons.add(reset_button);
        confirm_buttons.set_child_secondary(reset_button, true);
    }

    private void connect_signals()
    {
        auto_update_combo.changed.connect(() =>
        {
            int id = auto_update_combo.active;
            auto_update_time_entry.set_sensitive(id == 5);
            this.get_label_for_child(auto_update_time_entry).set_sensitive(id == 5);
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
            }
        });

        always_ask_check.toggled.connect(() =>
        {
            download_to_button.set_sensitive(!always_ask_check.active);
        });

        read_action_combo.changed.connect(() =>
        {
            int id = read_action_combo.active;
            read_incr_combo.set_sensitive(id > 0);
            read_spin.set_sensitive(id > 0);
        });

        unread_action_combo.changed.connect(() =>
        {
            int id = unread_action_combo.active;
            unread_incr_combo.set_sensitive(id > 0);
            unread_spin.set_sensitive(id > 0);
        });

        confirm_button.clicked.connect(save);
        cancel_button.clicked.connect(() => {done();});
        reset_button.clicked.connect(reset);
    }

    private void save()
    {
        settings.auto_update = auto_update_combo.active != 0;
        settings.start_update = start_update_switch.get_active();
        /* settings.timeout_value = (int)auto_update_time_entry.get_value() * 60; */
        settings.read_rule[0] = (int)read_spin.get_value();
        settings.read_rule[1] = read_incr_combo.get_active();
        if(read_action_combo.get_active() != -1)
            settings.read_rule[2] = read_action_combo.get_active() * 2; // 0 or 1 becomes 0 or 2
        settings.unread_rule[0] = (int)unread_spin.get_value();
        settings.unread_rule[1] = unread_incr_combo.get_active();
        settings.unread_rule[2] = unread_action_combo.get_active();
        settings.ask_download_location = always_ask_check.get_active();
        settings.default_download_location = File.new_for_path(download_to_button.get_filename());
        settings.link_command = link_command_entry.text;
        settings.save();
        done();
    }

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
}
}
