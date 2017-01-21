using Gtk;

public class ImportDialog : FileChooserDialog {
    public ImportDialog(Window window) {
        Object(transient_for: window);
    }

    construct {
        action = FileChooserAction.OPEN;
        title = "Select a file to import";

        add_button("Import", ResponseType.OK);
        add_button("Cancel", ResponseType.CANCEL);

        response.connect(on_response);
    }

    public signal void import_request(File to_import);

    private void on_response(int type) {
        if(type == ResponseType.OK)
            import_request(get_file());
        close();
    }
}

public class ExportDialog : FileChooserDialog {
    public ExportDialog(Window window) {
        Object(transient_for: window);
    }

    construct {
        action = FileChooserAction.SAVE;
        title = "Export to\u2026";

        add_button("Export", ResponseType.OK);
        add_button("Cancel", ResponseType.CANCEL);

        response.connect(on_response);
    }

    public signal void export_request(File to_import);

    private void on_response(int type) {
        if(type == ResponseType.OK)
            export_request(get_file());
        close();
    }
}
