public class Feed {
	private int _id;
	private Gee.ArrayList<Item> _items;
	
	public int id   { get { return _id; } } //Databse entry id
	public string title       { get; set; } //Feed title
	public string link        { get; set; } //Feed link
	public string description { get; set; } //Feed description
	
	public Feed.from_db(SQLHeavy.QueryResult result) {
		_items = new Gee.ArrayList<Item>();
		try {
			_id = result.fetch_int(0);
			title = result.fetch_string(1);
			link = result.fetch_string(2);
			description = result.fetch_string(3);
		} catch(SQLHeavy.Error e) {
			stderr.printf("Error loading feed data: %s\n", e.message);
			return;
		}
	}
	
	public void add_item(Item new_item) {
		stdout.printf("Adding Item...\n");
		_items.add(new_item);
	}
	
	public Item get_item(int id = 0) {
		return _items[id];
	}
}
