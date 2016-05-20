namespace Singularity
{
    class RSSItemDataSource : DataSource<Item, unowned Xml.Doc>
    {
        public override bool parse_data(Xml.Doc doc)
        {
            return false;
        }
    }
}
