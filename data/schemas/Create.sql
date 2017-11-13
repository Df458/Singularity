CREATE TABLE "feeds" (
	id 		INTEGER PRIMARY KEY AUTOINCREMENT,
	parent_id	INTEGER NOT NULL DEFAULT -1,
	type		INTEGER NOT NULL CHECK(type = 0 OR type = 1),
	title		VARCHAR,
	link		VARCHAR UNIQUE,
	site_link	VARCHAR,
	description	VARCHAR,
	rights		VARCHAR,
	generator	VARCHAR,
	last_update	DATE
);

CREATE TABLE items (
	guid		VARCHAR PRIMARY KEY NOT NULL,
	parent_id	INTEGER NOT NULL,
	weak_guid	VARCHAR NOT NULL,
	title		VARCHAR NOT NULL DEFAULT "Untitled",
	link		VARCHAR,
	content		VARCHAR,
	rights		VARCHAR,
	publish_time	DATE NOT NULL,
	update_time	DATE NOT NULL,
	load_time	DATE NOT NULL,
	unread		BOOLEAN NOT NULL DEFAULT 1,
	starred		BOOLEAN NOT NULL DEFAULT 0,
		FOREIGN KEY(parent_id) REFERENCES feeds(id)
    );

CREATE TABLE icons (
    "id"          INTEGER PRIMARY KEY,
    "width"       INTEGER NOT NULL,
    "height"      INTEGER NOT NULL,
    "alpha"       INTEGER NOT NULL CHECK(alpha = 0 OR alpha = 1),
    "bits"        INTEGER NOT NULL,
    "rowstride"   INTEGER NOT NULL,
    "data"        BLOB NOT NULL
);

CREATE TABLE enclosures (
    "guid" TEXT PRIMARY KEY NOT NULL,
    "feed_id" INTEGER NOT NULL,
    "item_guid" TEXT NOT NULL,
    "uri" TEXT NOT NULL,
    "name" TEXT,
    "length" INTEGER,
    "mimetype" TEXT
);
