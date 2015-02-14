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

using Gee;

Singularity app;

static string db_path;

static string css_path;
    
static bool verbose;

static bool nogui;

static string new_sub;

const OptionEntry[] options =
{
    { "database", 'd', 0, OptionArg.STRING, ref db_path, "database path", "DATABASE" },
    { "css-path", 'c', 0, OptionArg.STRING, ref css_path, "css path", "STYLESHEET" },
    { "no-gui", 'n', 0, OptionArg.NONE, ref nogui, "check for new entries, then exit without opening the main window" },
    { "verbose", 'v', 0, OptionArg.NONE, ref verbose, "display extra information", null},
    { "verbose", 'v', 0, OptionArg.NONE, ref verbose, "display extra information", null},
    { null }
};

public static int main (string[] args){
    db_path = Environment.get_user_data_dir() + "/singularity/feeds.db";
    css_path = Environment.get_user_data_dir() + "/singularity/default.css";
    OptionContext ctx = new OptionContext("- Singularity");

    ctx.add_main_entries(options, null);
    try {
        ctx.parse(ref args);
    } catch(OptionError e) {
        stderr.printf("Failed to parse args: %s\n", e.message);
        return 1;
    }

    if(args.length > 1) {
        new_sub = args[1].replace("feed://", "http://");
    }

    Gtk.init(ref args);

    app = new Singularity();
    return app.runall();
}
