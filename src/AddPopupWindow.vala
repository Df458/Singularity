using Gtk;
using Granite.Widgets;

class AddPopupWindow : Dialog {
    private TextView url_input;

    public AddPopupWindow(Window owner) {
	this.set_transient_for(owner);
	this.title = "Add a feed";
	this.focus_out_event.connect(() => {
	    this.hide();
	    return true;
	});

	add_buttons("Cancel", 0, "Preview", 1, "Ok", 2);
	this.response.connect((sig) => {
	    if(sig == 0){
		url_input.buffer.text = "";
		this.hide();
	    } else if(sig == 2) {
		app.createFeed(url_input.buffer.text);
		this.hide();
	    }
	});


	Box content_box = get_content_area() as Box;

	url_input = new TextView();
	url_input.editable = true;
	url_input.input_purpose = InputPurpose.URL;
	content_box.pack_start(url_input, false, true, 0);
    }
}
