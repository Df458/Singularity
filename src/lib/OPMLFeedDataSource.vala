namespace Singularity
{
    class OPMLFeedDataSource : DataSource<Feed, unowned Xml.Doc>
    {
        public override bool parse_data(Xml.Doc doc)
        {
            return false;
        }
    }
}
