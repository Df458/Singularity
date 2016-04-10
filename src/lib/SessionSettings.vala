namespace Singularity
{
public class SessionSettings
{
    // Properties
    public bool    background    { get { return m_background; } }
    public string  database_path { get { return m_database; } }
    public bool    is_valid      { get { return m_valid_options; } }
    public bool    verbose       { get { return m_verbose; } }
    public string? user_css      { get { return m_user_css; } }

    // Constructors
    public SessionSettings(string[] args)
    {
        OptionEntry opt1 = { "database",  'd',  0,  OptionArg.STRING,  ref m_database,    "database path", "DATABASE" };
        OptionEntry opt2 = { "css-path",  'c',  0,  OptionArg.STRING,  ref m_user_css,    "css path",      "STYLESHEET" };
        OptionEntry opt3 = { "no-gui",    'n',  0,  OptionArg.NONE,    ref m_background,  "check for new entries, then exit without opening the main window" };
        OptionEntry opt4 = { "verbose",   'v',  0,  OptionArg.NONE,    ref m_verbose,     "display extra information" };
        OptionEntry end = { null };
        OptionEntry[] options = {
            opt1,
            opt2,
            opt3,
            opt4,
            end
        };
        OptionContext context = new OptionContext("- Singularity");
        context.add_main_entries(options, null);
        try {
            context.parse(ref args);
        } catch(OptionError e) {
            stderr.printf("Failed to parse arguments: %s\n", e.message);
            return;
        }
        m_valid_options = true;
    }

    // Private data
    string   m_database = "";
    string?  m_user_css = null;
    bool     m_verbose = false;
    bool     m_background = false;
    bool     m_valid_options = false;
}
}
