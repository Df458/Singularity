using Gee;

namespace Singularity
{

public class UpdateQueue : Object
{
    public  AsyncQueue<Feed> update_requests { get; construct; }

    public UpdateQueue()
    {
        Object(update_requests: new AsyncQueue<Feed>());
        m_update_queue  = new Gee.ArrayQueue<Feed>();
        // TODO: Load existing queued requests and put them at the front

        m_processing_thread = new Thread<void*>(null, this.process);
    }

    public void request_update(Feed f)
    {
        // TODO: Implement this
        warning("UpdateQueue.request_update: unimplemented");
    }

    public void set_paused(bool paused)
    {
        // TODO: Implement this
        warning("UpdateQueue.set_paused: unimplemented");
    }

    public signal void update_processed(UpdatePackage update);

    private Gee.Queue<Feed> m_update_queue;
    private Thread<void*>   m_processing_thread;

    private void* process()
    {
        // TODO: Implement this
        warning("UpdateQueue.process: unimplemented");

        return null;
    }
}

}
