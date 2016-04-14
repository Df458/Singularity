namespace Singularity
{
    public struct Person
    {
        public string? name     { get; set; }
        public string? url      { get; set; }
        public string? email    { get; set; }
        public bool    is_valid { get { return (name != null && name.length != 0) || (email != null && email.length != 0); } }

        public Person(string? name, string? url = null, string? email = null)
        {
            this.name  = name;
            this.url   = url;
            this.email = email;
        }
    }
}
