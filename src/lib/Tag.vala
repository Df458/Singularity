namespace Singularity
{
    public struct Tag
    {
        public string  name  { get; set; }
        public string? link  { get; set; }
        public string? label { get; set; }

        public Tag(string name, string? link = null, string? label = null)
        {
            this.name  = name;
            this.link  = link;
            this.label = label;
        }
    }
}
