using Gee;

namespace Singularity
{
    public interface DataSource<T>
    {
        public abstract Collection<T> get_data(string uri);
    }
}
