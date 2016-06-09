namespace Singularity
{
    public struct Attachment
    {
        public string? name { get; set; }
        public string url   { get; set; }

        public Attachment(string name, string? url = null)
        {
            this.name  = name;
            this.url   = url;
        }
    }
}
