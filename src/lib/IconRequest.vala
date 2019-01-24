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

// Web request for getting an icon for a feed
public class IconRequest : Object {
    public string uri { get; construct; }
    public bool request_sent { get; private set; default = false; }
    public bool error_exists { get { return error_message != null; } }
    public string? error_message { get; private set; default = null; }
    public Gdk.Pixbuf? buf { get; private set; }

    public IconRequest (string to_fetch) {
        string turi = to_fetch;
        if (!to_fetch.has_prefix ("http://") && !to_fetch.has_prefix ("https://") && !to_fetch.has_prefix ("file://"))
            turi = "http://" + to_fetch;

        Object (uri: turi);

        try {
            m_request = m_session.request (uri);
        } catch (Error e) {
            warning ("Failed to create iocn request: %s", e.message);
        }
    }

    public bool send () {
        request_sent = true;

        if (m_request == null) {
            error_message = "Invalid URL";
            return false;
        }

        try {
            InputStream stream = m_request.send ();
            buf = new Gdk.Pixbuf.from_stream (stream);
            buf.add_alpha (false, 0, 0, 0);
            buf = buf.scale_simple (16, 16, Gdk.InterpType.BILINEAR);
        } catch (Error e) {
            warning ("Failed to retrieve data stream: %s", e.message);
            return false;
        }

        return true;
    }

    private Soup.Session m_session = new Soup.Session ();
    private Soup.Request? m_request;
}
}
