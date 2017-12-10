namespace Singularity
{
    // DataSource that can translate their output back to the source format
    public abstract class ReversibleDataSource<DataType, ParseType> : DataSource<DataType, ParseType>
    {
        public abstract ParseType encode_data(Gee.List<DataType> to_encode);
    }
}
