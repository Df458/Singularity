using Gee;

namespace Singularity
{

public class UpdateQueue : Object
{
    public  AsyncQueue<Feed> update_requests { get; construct; }

    public UpdateQueue()
    {
        Object(update_requests: new AsyncQueue<Feed>());
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

    private Thread<void*>   m_processing_thread;

    private void* process()
    {
        while(true) {
            Feed f = update_requests.pop();
            UpdateGenerator gen = new UpdateGenerator(f);
            update_processed(gen.do_update());
        }
    }
}

}
