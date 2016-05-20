namespace Singularity
{
    public interface Subscription<ItemType, ParseType> : DataEntry
    {
        public abstract bool get_should_update();
        public abstract bool update_contents(DataSource<ItemType, ParseType> source);
    }
}
