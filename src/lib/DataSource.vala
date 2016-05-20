namespace Singularity
{
    public abstract class DataSource<DataType, ParseType>
    {
        public Gee.List<DataType> data { get { return _data; } }

        public DataType @get(int index)
        {
            return _data.get(index);
        }

        public abstract bool parse_data(ParseType type);

        protected Gee.List<DataType> _data;
    }
}
