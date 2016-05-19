namespace Singularity
{
    public interface Subscription<T> : DataEntry
    {
        public abstract bool get_should_update();
        public abstract bool update_contents(DataSource<T> source);
    }
}
