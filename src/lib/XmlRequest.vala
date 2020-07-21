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
    // This class is responsible for retrieving Xml data from external sources
    public class XmlRequest : Object {

        public enum ContentType {
            INVALID = -1,
            RSS,
            ATOM,
            COUNT
        }

        public string uri { get; construct; }
        public bool request_sent { get; private set; }
        public bool error_exists { get { return error_message != null; } }
        public string? error_message { get; private set; }
        public GXml.GDocument doc { get; private set; }
        public string doc_data { get; private set; }

        public XmlRequest (string to_fetch, Soup.Session s) {
            string turi = to_fetch;
            if (!to_fetch.has_prefix ("http://")
                && !to_fetch.has_prefix ("https://")
                && !to_fetch.has_prefix ("file://"))
                turi = "http://" + to_fetch;

            Object (uri: turi);
            doc = null;
            error_message = null;
            request_sent = false;
            m_session = s;
            m_message = new Soup.Message ("GET", uri);
        }

        public bool send () {
            MainLoop loop = new MainLoop ();
            request_sent = true;

            if (m_message == null) {
                error_message = "Invalid URL";
                return false;
            }

            m_session.queue_message (m_message, (s, m) =>
            {
                loop.quit ();
            });

            loop.run ();

            if (m_message.status_code >= 400) {
                error_message = get_status_error (m_message.status_code);
                return false;
            }

            string data = (string)m_message.response_body.data;
            return create_doc (data);
        }

        public async bool send_async () {
            SourceFunc callback = this.send_async.callback;
            request_sent = true;
            string? data = null;

            if (m_session == null) {
                error_message = "Broken Session";
                warning ("Failed to create session");
                return false;
            }

            if (m_message == null) {
                error_message = "Invalid URL";
                warning ("Failed to retrieve URL");
                return false;
            }

            m_session.queue_message (m_message, (s, m) =>
            {
                data = (string)m.response_body.data;
                Idle.add ((owned) callback);
            });

            yield;

            if (m_message.status_code >= 400) {
                error_message = get_status_error (m_message.status_code);
                return false;
            }

            return create_doc (data);
        }

        public ContentType determine_content_type () {
            if (doc == null)
                return ContentType.INVALID;

            if (doc["rss"] != null || doc["RDF"] != null)
                return ContentType.RSS;
            else if (doc["feed"] != null)
                return ContentType.ATOM;

            return ContentType.INVALID;
        }

        public FeedProvider? get_provider_from_request () {
            switch (determine_content_type ()) {
                case ContentType.RSS:
                    return new RSSItemDataSource ();
                case ContentType.ATOM:
                    return new AtomItemDataSource ();
                default:
                    stderr.printf ("Unknown content found: %s", doc_data);
                    return null;
            }
        }

        /**
         * Create the XML document from a string containing data
         *
         * @param data The data to parse
         * @return true on success; otherwise, false
         */
        private bool create_doc (string? data) {
            if (data == null) {
                error_message = "Message data was not received";
                return false;
            }

            doc_data = clean_xml (data);
            try {
                doc = new GXml.GDocument.from_string (doc_data);

                if (doc == null && data != null) {
                    doc_data = doc_data.split ("<!DOCTYPE html")[0];
                    doc = new GXml.GDocument.from_string (doc_data);
                }
            } catch (GLib.Error e) {
                error_message = "Failed to parse document:\n\"%s\"".printf (doc_data);
                doc = null;
            }

            if (doc == null) {
                if (error_message != null) {
                    error_message = "Failed to parse document: Unknown Error";
                }
                return false;
            }

            return true;
        }

        /**
         * Get a textual error from the given HTTP status code
         *
         * @param status_code The status code
         * @return A string containing an error message
         */
        private string get_status_error (uint status_code) {
            string description = "";
            switch (status_code) {
                case Soup.Status.NOT_FOUND:
                    description = "Not found";
                    break;
                case Soup.Status.FORBIDDEN:
                    description = "Forbidden";
                    break;
                case Soup.Status.UNAUTHORIZED:
                    description = "Unauthorized";
                    break;
                default:
                    return "Server returned error code %u".printf(status_code);
            }

            return "Server returned error code %u: %s".printf(status_code, description);
        }

        public string get_base_uri () {
            return m_message.uri.get_host ();
        }

        private Soup.Session? m_session = null;
        private Soup.Message? m_message;
    }
}
