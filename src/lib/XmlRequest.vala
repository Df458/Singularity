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
    public string   uri           { get; construct; }
    public bool     request_sent  { get; private set; }
    public bool     error_exists  { get { return error_message != null; } }
    public string?  error_message { get; private set; }
    public Xml.Doc* doc           { get; private set; }

    private Soup.Session m_session;
    private Soup.Message m_message;

    public XmlRequest(string to_fetch)
    {
        Object(uri: to_fetch);
        doc = null;
        error_message = null;
        request_sent = false;
        m_session = new Soup.Session();
        m_message = new Soup.Message("GET", uri);
    }

    public bool send()
    {
        MainLoop loop = new MainLoop();
        request_sent = true;

        try {
            m_session.queue_message(m_message, (s, m) =>
            {
                loop.quit();
            });
        } catch(Error e) {
            error_message = e.message;
            return false;
        }

        loop.run();

        string data = (string)m_message.response_body.data;
        doc = Xml.Parser.parse_doc(data);

        if(doc == null && data != null) {
            warning("Spilt then parse\u2026");
            data = data.split("<!DOCTYPE html")[0];
            doc = Xml.Parser.parse_doc(data);
        }

        if(doc == null) {
            error_message = "Failed to parse document";
            return false;
        }

        return true;
    }

    public async bool send_async()
    {

        m_session.use_thread_context = true;
        string data;
        try {
            yield m_session.send_async(m_message);
            data = (string)m_message.response_body.data;
        } catch(Error e) {
            request_sent = true;
            error_message = e.message;
            return false;
        }

        request_sent = true;

        doc = Xml.Parser.parse_doc(data);

        if(doc == null && data != null) {
            data = data.split("<!DOCTYPE html")[0];
            doc = Xml.Parser.parse_doc(data);
        }

        if(doc == null) {
            error_message = "Failed to parse document";
            return false;
        }

        return true;
    }
}
}
