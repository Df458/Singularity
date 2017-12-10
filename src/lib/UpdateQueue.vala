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
using Gee;

namespace Singularity
{
const string USER_AGENT = "Singularity RSS Reader/0.3 [http://github.com/Df458/Singularity]";

// This class takes in feeds, and schedules/executes their updates
// FIXME: Remove deleted feeds
public class UpdateQueue : Object
{
    public int length { get { return m_update_requests.length(); } }

    public UpdateQueue()
    {
        // TODO: Load existing queued requests and put them at the front

        update_cookie_path();

        m_update_requests = new AsyncQueue<Feed>();
        m_processing_threads = new Thread<void*>[thread_count];
        for(int i = 0; i < thread_count; ++i)
            m_processing_threads[i] = new Thread<void*>(null, this.process);
    }

    public void request_update(Feed f, bool high_priority = false)
    {
        if(high_priority)
            m_update_requests.push_front(f);
        else
            m_update_requests.push(f);
    }

    public void update_cookie_path()
    {
        if(AppSettings.cookie_db_path != "")
            m_cookies = new Soup.CookieJarDB(AppSettings.cookie_db_path, true);
        else
            m_cookies = null;
    }

    public signal void update_processed(UpdatePackage update);

    private AsyncQueue<Feed> m_update_requests;
    private Thread<void*>[] m_processing_threads;
    private Soup.CookieJarDB? m_cookies = null;
    private int thread_count = 4;

    private void* process()
    {
        while(true) {
            Soup.Session session = new Soup.Session();
            if(m_cookies != null)
                session.add_feature(m_cookies);
            session.user_agent = USER_AGENT;

            Feed f = m_update_requests.pop();
            UpdateGenerator gen = new UpdateGenerator(f, session);
            UpdatePackage pak = gen.do_update();
            update_processed(pak);
        }
    }
}

}
