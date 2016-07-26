using Gee;

namespace Singularity
{

// FIXME: Remove deleted feeds
public class UpdateQueue : Object
{
    public int length { get { return m_update_requests.length(); } }

    public UpdateQueue()
    {
        // TODO: Load existing queued requests and put them at the front

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

    public void set_paused(bool paused)
    {
        // TODO: Implement this
        warning("UpdateQueue.set_paused: unimplemented");
    }

    public signal void update_processed(UpdatePackage update);

    private AsyncQueue<Feed> m_update_requests;
    private Thread<void*>[] m_processing_threads;
    private int thread_count = 4;

    private void* process()
    {
        while(true) {
            Feed f = m_update_requests.pop();
            /* stderr.printf("Update started: %s", f.to_string()); */
            UpdateGenerator gen = new UpdateGenerator(f);
            UpdatePackage pak = gen.do_update();
            /* stderr.printf("Update finished: %s", f.to_string()); */
            update_processed(pak);
        }
    }
}

}
