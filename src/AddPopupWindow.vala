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

class AddPopupWindow : Dialog {
    private Entry url_input;

    public AddPopupWindow(Window owner) {
	this.set_transient_for(owner);
	this.set_modal(true);
	this.title = "Add a feed";
	//this.focus_out_event.connect(() => {
	    //this.hide();
	    //return true;
	//});

	add_buttons("Cancel", 0, "Preview", 1, "Ok", 2);
	this.response.connect((sig) => {
	    if(sig == 0) {
		url_input.set_text("");
		this.hide();
	    } else if(sig == 2) {
		app.createFeed(url_input.get_text());
		url_input.set_text("");
		this.hide();
	    }
	});


	Box content_box = get_content_area() as Box;

	url_input = new Entry();
	url_input.editable = true;
	url_input.input_purpose = InputPurpose.URL;
	content_box.pack_start(url_input, false, true, 0);
    }
}
