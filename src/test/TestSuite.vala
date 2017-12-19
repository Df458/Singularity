using Gee;

namespace Singularity.Tests
{
public class TestSuite : Object
{
    public string Name { get; construct; }

    public TestSuite(string name)
    {
        Object(Name: name);
    }

    public void add(UnitTest test)
    {
        test.add_tests("/singularity/%s".printf(Name));
    }
}
}
