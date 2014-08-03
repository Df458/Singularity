using Sqlite;

public class DatabaseManager {
	Database db;
	bool open = false;
	
	public DatabaseManager.from_string(string location) {
		int err = Database.open(location, out db);
		if(err != Sqlite.OK) {
			stderr.printf("IO Error: Cannot open database: %s\n", db.errmsg());
			return;
		}
		
		open = true;
	}
	
	public void loadFeedItems(Feed feed, int item_count = -1, int starting_id = -1) {
		// TODO: All of this
		int err = db.exec("", (column_count, values, column_names) => {
            for (int i = 0; i < n_columns; i++) {
                stdout.printf ("%s = %s\n", column_names[i], values[i]);
            }
            stdout.printf ("\n");
            return 0;
        }, null);
        
        if(err != Sqlite.OK) {
			stderr.printf("Database Error: %s\n", db.errmsg());
			return;
		}
	}
}
