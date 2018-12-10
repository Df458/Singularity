using Gee;

namespace Singularity.Tests {
    public struct TestCase {
        public string name;
        public TestFunc func;

        public TestCase(string n, TestFunc f) {
            name = n;
            func = f;
        }
    }

    public interface UnitTest {
        public abstract string name { get; }
        public abstract void add_tests(string path);

        protected void add_cases(string path, TestCase[] test_cases) {
            foreach(var c in test_cases) {
                Test.add_func("%s/%s".printf(path, c.name), c.func);
            }
        }
    }
}
