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
using Granite.Widgets;

class AddPane : VBox {
    Entry url_input;
    ButtonBox confirm_buttons;

    public signal void done();

    public AddPane() {
        spacing = 5;
        confirm_buttons = new HButtonBox();
        Gtk.Button cancel_button = new Gtk.Button.with_label("Cancel");
        cancel_button.clicked.connect(() => {
            url_input.set_text("");
            done();
        });
        Gtk.Button confirm_button = new Gtk.Button.with_label("Confirm");
        confirm_button.clicked.connect(() => {
            app.createFeed(url_input.get_text());
            url_input.set_text("");
            done();
        });
        confirm_buttons.add(cancel_button);
        confirm_buttons.add(confirm_button);

        url_input = new Entry();
        url_input.editable = true;
        url_input.input_purpose = InputPurpose.URL;

        pack_start(url_input, false, true, 0);
        pack_end(confirm_buttons, false, false);
        this.show_all();
    }
}
