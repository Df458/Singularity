using Gee;

namespace Singularity.Tests
{
    class MockDataSource<T> : DataSource<T>
    {
        public Collection<T> held_data;

        public MockDataSource(Collection<T> data)
        {
            held_data = data;
        }

        public MockDataSource.single(T data)
        {
            held_data = new HashSet<T>();
            held_data.add(data);
        }

        public Collection<T> get_data(string uri)
        {
            return held_data;
        }
    }
}
