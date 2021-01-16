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

namespace Singularity {
    // Container for all application-wide settings
    // This class acts as a bridge between the app and the GSettings API, with functions
    // for saving/loading
    public class AppSettings {
        public static bool auto_update;
        public static bool start_update;
        public static bool display_unread_only;
        public static uint auto_update_freq;
        public static uint last_view;
        public static int items_per_list;
        public static bool download_attachments;
        public static bool ask_download_location;
        public static File default_download_location;
        public static string link_command;
        public static string cookie_db_path;

        // Saves the settings to GSettings
        public static void save ()
            requires (m_source != null) {
            m_source.set_boolean ("auto-update", auto_update);
            m_source.set_boolean ("start-update", start_update);
            m_source.set_boolean ("unread-only", display_unread_only);
            m_source.set_uint ("auto-update-freq", auto_update_freq);
            m_source.set_uint ("last-view", last_view);
            m_source.set_boolean ("download-attachments", download_attachments);
            m_source.set_boolean ("ask-download-location", ask_download_location);
            m_source.set_string ("default-download-location", default_download_location.get_path ());
            m_source.set_string ("link-command", link_command);
            m_source.set_string ("cookie-db-path", cookie_db_path);
        }

        // Loads the settings from GSettings, optionally taking an ID to initialize
        // the source
        public static void load (string? id = null)
            requires (id != null || m_source != null) {
                if (id != null)
                    m_source = new Settings (id);

                auto_update = m_source.get_boolean ("auto-update");
                start_update = m_source.get_boolean ("start-update");
                display_unread_only = m_source.get_boolean ("unread-only");
                auto_update_freq = m_source.get_uint ("auto-update-freq");
                last_view = m_source.get_uint ("last-view");
                items_per_list = m_source.get_int ("items-per-list");
                download_attachments = m_source.get_boolean ("download-attachments");
                ask_download_location = m_source.get_boolean ("ask-download-location");
                default_download_location = File.new_for_path (m_source.get_string ("default-download-location"));
                link_command = m_source.get_string ("link-command");
                cookie_db_path = m_source.get_string ("cookie-db-path");
            }

        // Resets the values in this object to the defaults.
        // Note that this only occurs on the application side, so you must
        // call save () to have the changes occur in the settings.
        public static void reset () {
            auto_update = true;
            start_update = true;
            auto_update_freq = 10;
            last_view = 0;
            download_attachments = true;
            ask_download_location = true;
            default_download_location = File.new_for_path (Environment.get_home_dir () + "/Downloads");
            link_command = "xdg-open %s";
            cookie_db_path = "";
        }

        // Container for argument-based settings
        // This class parses in the program's arguments, and provides them
        // as settings
        public class Arguments {
            public static bool background {
                get {
                    return m_background_update || m_list_feeds || m_subscribe_url != null;
                }}
            public static string? database_path { get { return m_database; } }
            public static bool verbose { get { return m_verbose; } }
            public static string? user_css { get { return m_user_css; } }
            public static bool background_update { get { return m_background_update; } }
            public static bool list_feeds { get { return m_list_feeds; } }
            public static string? subscribe_url { get { return m_subscribe_url; } }

            // Parses the provided arguments.
            // Returns true if the arguments were parsed correctly, or false if
            // there were errors.
            public static bool parse (string[] args) {
                OptionContext context = new OptionContext ("- Singularity");
                context.set_help_enabled (true);
                context.add_main_entries (options, null);
                try {
                    context.parse (ref args);
                } catch (OptionError e) {
                    stderr.printf ("Error: %s\n", e.message);
                    return false;
                }

                if (m_database == null)
                    m_database = Environment.get_user_data_dir () + "/singularity/feeds.db";

                try {
                    File default_data_file = File.new_for_path (m_database).get_parent ();
                    if (!default_data_file.query_exists ()) {
                        if (verbose)
                            info ("Default data location does not exist, and will be created.\n");
                        default_data_file.make_directory_with_parents ();
                    }
                } catch (Error e) {
                    error ("Failed to initialize the directory at %s: %s\n", m_database, e.message);
                }

                return true;
            }

            private static string? m_database = null;
            private static string? m_user_css = null;
            private static bool m_verbose = false;
            private static bool m_background_update = false;
            private static bool m_list_feeds = false;
            private static string? m_subscribe_url = null;

            // Argument information, used for parsing
            private const OptionEntry[] options = {
                { "database", 'd', 0, OptionArg.STRING, ref m_database, "database path", "DATABASE" },
                { "css-path", 'c', 0, OptionArg.STRING, ref m_user_css, "css path", "STYLESHEET" },
                { "verbose", 'v', 0, OptionArg.NONE, ref m_verbose, "display extra information" },
                {
                    "update-feeds",
                    'u',
                    0,
                    OptionArg.NONE,
                    ref m_background_update,
                    "check for new items, then exit without opening the main window" },
                {
                    "list-feeds",
                    'l',
                    0,
                    OptionArg.NONE,
                    ref m_list_feeds,
                    "list all subscribed feeds, then exit without opening the main window" },
                {
                    "subscribe",
                    's',
                    0,
                    OptionArg.STRING,
                    ref m_subscribe_url,
                    "Subscribe to a feed, then exit without opening the main window", "URL" },
                { null }
            };
        }

        private static Settings? m_source = null;
    }
}
