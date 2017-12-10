/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2017  Hugues Ross <hugues.ross@gmail.com>

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

namespace Singularity
{
// Dialog for importing OPML files
[GtkTemplate (ui="/org/df458/Singularity/ImportDialog.ui")]
public class ImportDialog : FileChooserDialog
{
    public ImportDialog(Window window)
    {
        Object(transient_for: window);
    }

    public signal void import_request(File to_import);

    [GtkCallback]
    private void on_response(int type)
    {
        if(type == ResponseType.OK)
            import_request(get_file());
        close();
    }
}

// Dialog for exporting OPML files
[GtkTemplate (ui="/org/df458/Singularity/ExportDialog.ui")]
public class ExportDialog : FileChooserDialog
{
    public ExportDialog(Window window)
    {
        Object(transient_for: window);
    }

    public signal void export_request(File to_import);

    [GtkCallback]
    private void on_response(int type)
    {
        if(type == ResponseType.OK)
            export_request(get_file());
        close();
    }
}
}
