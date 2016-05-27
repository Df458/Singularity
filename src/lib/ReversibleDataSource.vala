namespace Singularity
{
    public abstract class ReversibleDataSource<DataType, ParseType> : DataSource<DataType, ParseType>
    {
        public abstract ParseType encode_data(Gee.List<DataType> to_encode);
    }
}
