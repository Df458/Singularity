namespace Singularity
{
    public abstract class FeedProvider : DataSource<Item, unowned Xml.Doc>
    {
        public Feed? stored_feed = null;
    }
}
