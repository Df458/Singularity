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
    /** This class is responsible for retrieving Xml data from external sources */
    public class XmlRequest : WebFeedRequest {
        public XmlRequest (string uri, Soup.Session s) {
            base (uri, s);
        }

        /**
         * Get the provider from this request
         *
         * @return A FeedProvider, or null if not loaded
         */
        public override FeedProvider? get_provider () {
            return _feed_provider;
        }

        /**
         * Create the XML document from a string containing data
         *
         * @param data The data to parse
         * @return true on success; otherwise, false
         */
        protected override bool create_doc (string? data) {
            if (data == null) {
                error_message = "Message data was not received";
                return false;
            }

            GXml.GDocument? doc = null;
            string doc_data = clean_xml (data);
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
            } else if (doc["rss"] != null || doc["RDF"] != null) {
                _feed_provider = new RSSItemDataSource ();
                _feed_provider.parse_data (doc);
            } else if (doc["feed"] != null) {
                _feed_provider = new AtomItemDataSource ();
                _feed_provider.parse_data (doc);
            }

            return true;
        }

        private FeedProvider? _feed_provider = null;
    }
}
