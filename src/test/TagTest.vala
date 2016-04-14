using Valadate;

namespace Singularity.Tests
{
    [Test (name="Tag TestCases")]
    public class TagTest : Framework.TestCase
    {
        [Test (name="tag_name")]
        public void testTagName()
        {
            Tag tag = Tag("Test");
            Assert.equals("Test", tag.name, "wrong name");
        }
        [Test (name="tag_link")]
        public void testTagLink()
        {
            Tag tag = Tag("Test", "http://example.com");
            Assert.equals("http://example.com", tag.link, "wrong link");
        }
        [Test (name="tag_label")]
        public void testTagLabel()
        {
            Tag tag = Tag("Test", "http://example.com", "Test Label");
            Assert.equals("Test Label", tag.label, "wrong label");
        }
    }
}
