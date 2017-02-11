namespace Singularity
{
    public struct Attachment
    {
        public string name    { get; set; }
        public string url      { get; set; }
        public int size        { get; set; }
        public string mimetype { get; set; }

        public Attachment.from_record(SQLHeavy.Record r) {
            name = r.get_string("name");
            url = r.get_string("uri");
            size = r.get_int("length");
            mimetype = r.get_string("mimetype");
        }
    }
}
