namespace Singularity.Tests
{
    [Test (name="SessionSettings TestCases")]
    public class SettingsTest : Valadate.Framework.TestCase
    {
        const string[] testargs_flag  = { "", "--invalid-argument" };

        [Test (name="SessionSettings Flag Validation Test")]
        public void test_invalid_flag()
        {
            SessionSettings flag_settings = new SessionSettings(testargs_flag);
            assert_true(flag_settings.is_valid == false);
        }
    }
}
