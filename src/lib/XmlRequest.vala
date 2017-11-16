/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

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

namespace Singularity
{
    public class XmlRequest : Object
    {

        public enum ContentType
        {
            INVALID = -1,
            RSS,
            ATOM,
            COUNT
        }

        public string   uri           { get; construct; }
        public bool     request_sent  { get; private set; }
        public bool     error_exists  { get { return error_message != null; } }
        public string?  error_message { get; private set; }
        public GXml.GDocument doc      { get; private set; }
        public string   doc_data      { get; private set; }

        public XmlRequest(string to_fetch, Soup.Session s)
        {
            string turi = to_fetch;
            if(!to_fetch.has_prefix("http://") && !to_fetch.has_prefix("https://") && !to_fetch.has_prefix("file://"))
                turi = "http://" + to_fetch;

            Object(uri: turi);
            doc = null;
            error_message = null;
            request_sent = false;
            m_session = s;
            m_message = new Soup.Message("GET", uri);
        }

        public bool send()
        {
            MainLoop loop = new MainLoop();
            request_sent = true;

            if(m_message == null) {
                error_message = "Invalid URL";
                return false;
            }

            m_session.queue_message(m_message, (s, m) =>
            {
                loop.quit();
            });

            loop.run();

            string data = (string)m_message.response_body.data;

            return create_doc(data);
        }

        public async bool send_async()
        {
            SourceFunc callback = this.send_async.callback;
            request_sent = true;
            string? data = null;

            if(m_session == null) {
                error_message = "Broken Session";
                warning("Failed to create session");
                return false;
            }

            if(m_message == null) {
                error_message = "Invalid URL";
                warning("Failed to retrieve URL");
                return false;
            }

            m_session.queue_message(m_message, (s, m) =>
            {
                data = (string)m.response_body.data;
                Idle.add((owned) callback);
            });

            yield;

            if(data == null) {
                error_message = "Message data was not received";
                warning("Failed to receive message data");
                return false;
            }

            return create_doc(data);
        }

        public ContentType determine_content_type()
        {
            if(doc == null)
                return ContentType.INVALID;

            if(doc["rss"] != null || doc["RDF"] != null)
                return ContentType.RSS;
            else if(doc["feed"] != null)
                return ContentType.ATOM;

            return ContentType.INVALID;
        }

        public FeedProvider? get_provider_from_request()
        {
            switch(determine_content_type())
            {
                case ContentType.RSS:
                    return new RSSItemDataSource();
                case ContentType.ATOM:
                    return new AtomItemDataSource();
                default:
                    return null;
            }
        }

        private bool create_doc(string data)
        {
            doc_data = clean_xml(data);
            try {
                doc = new GXml.GDocument.from_string(doc_data);

                if(doc == null && data != null) {
                    doc_data = doc_data.split("<!DOCTYPE html")[0];
                    doc = new GXml.GDocument.from_string(doc_data);
                }
            } catch(GLib.Error e) {
                warning("Failed to parse document: %s\nData:\n%s", e.message, doc_data);
                doc = null;
            }

            if(doc == null) {
                error_message = "Failed to parse document";
                return false;
            }

            return true;
        }

        private Soup.Session? m_session = null;
        private Soup.Message? m_message;
    }
}
