public class Item {
	private string _guid;

	public string title       { get; set; } //Item title
	public string link        { get; set; } //Item link
	public string description { get; set; } //Item description
	public string guid { get { return _guid; } } //Unique identifier
	
	public Item.from_db(SQLHeavy.QueryResult result) {
		try {
			title = result.fetch_string(1);
			link = result.fetch_string(2);
			description = result.fetch_string(3);
			_guid = result.fetch_string(8);
		} catch(SQLHeavy.Error e) {
			stderr.printf("Error loading feed data: %s\n", e.message);
			return;
		}
	}
}
