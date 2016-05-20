namespace Singularity.Tests
{
    class MockDataSource<T, U> : DataSource<T, U>
    {
        public MockDataSource(Gee.List<T> new_data)
        {
            _data = new_data;
        }

        public override bool parse_data(U type)
        {
            return true;
        }
    }
}
