namespace Singularity
{
    public static const string data_folder_name = "singularity";
    public class DataLocator : Object
    {
        public string? data_location { get; private set; }

        public DataLocator(SessionSettings settings)
        {
            data_location = Environment.get_user_data_dir() + "/" + data_folder_name;
            if(settings.database_path != null)
                data_location = settings.database_path;
            try {
                File default_data_file = File.new_for_path(data_location);
                if(!default_data_file.query_exists()) {
                    if(settings.verbose)
                        info("Default data location does not exist, and will be created.\n");
                    default_data_file.make_directory_with_parents();
                }
            } catch(Error e) {
                error("Failed to initialize the directory at %s: %s\n", data_location, e.message);
            }
        }
    }
}
