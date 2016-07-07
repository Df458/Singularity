using Gee;

namespace Singularity
{

public class UpdateQueue : Object
{
    private AsyncQueue<Feed> m_update_requests;

    public UpdateQueue()
    {
        // TODO: Load existing queued requests and put them at the front

        m_update_requests = new AsyncQueue<Feed>();
        m_processing_thread = new Thread<void*>(null, this.process);
    }

    public void request_update(Feed f)
    {
        /* stderr.printf("Update Requested: %s\n", f.to_string()); */
        m_update_requests.push(f);
    }

    public void set_paused(bool paused)
    {
        // TODO: Implement this
        warning("UpdateQueue.set_paused: unimplemented");
    }

    public signal void update_processed(UpdatePackage update);

    private Thread<void*>   m_processing_thread;

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
