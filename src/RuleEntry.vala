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

class RuleEntry : Box {
    private Label label;
    private SpinButton count_button;
    private ComboBoxText increment_selector;
    private ComboBoxText action_selector;

    public RuleEntry(string label_string, bool read, bool starred) {
        Object(orientation: Orientation.HORIZONTAL, spacing: 0);
        label = new Label(label_string + ": After ");
        count_button = new SpinButton.with_range(0, 1000, 1);
        increment_selector = new ComboBoxText();
        increment_selector.append_text("Never");
        increment_selector.append_text("Minutes");
        increment_selector.append_text("Hours");
        increment_selector.append_text("Days");
        increment_selector.append_text("Months");
        increment_selector.append_text("Years");
        increment_selector.changed.connect(() => {
            count_button.set_sensitive(increment_selector.get_active() != 0);
        });

        action_selector = new ComboBoxText();
        action_selector.append_text("Do nothing");
        action_selector.append_text("Mark as " + (read ? "unread" : "read"));
        action_selector.append_text("Mark as " + (starred ? "unstarred" : "starred"));
        action_selector.append_text("Delete");

        this.pack_start(label, false, false);
        this.pack_start(count_button, false, false);
        this.pack_start(increment_selector, false, false, 0);
        this.pack_start(action_selector, false, false, 0);
    }

    public void sync(int[] rule) {
        count_button.set_value(rule[0]);
        increment_selector.set_active(rule[1]);
        action_selector.set_active(rule[2]);

        if(rule[1] == 0)
            count_button.set_sensitive(false);
    }

    public int[] get_value() {
        int[] output = {0, 0, 0};
        output[0] = (int)count_button.get_value();
        output[1] = increment_selector.get_active();
        output[2] = action_selector.get_active();
        return output;
    }
}
