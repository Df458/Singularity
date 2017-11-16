namespace Singularity
{
    public abstract class FeedProvider : DataSource<Item, unowned GXml.GDocument>
    {
        public Feed? stored_feed = null;
    }
}
