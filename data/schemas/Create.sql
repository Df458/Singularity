CREATE TABLE feeds (
    "id" INTEGER,
    "parent_id" INTEGER,
    "title" TEXT,
    "link" TEXT,
    "origin" TEXT,
    "description" TEXT,
    "icon" TEXT,
    "last_load_guids" TEXT,
    "last_load_time" INTEGER,
    "rules" TEXT,
    "override_download" INTEGER,
    "ask_download_location" INTEGER,
    "default_location" TEXT);
CREATE TABLE items (
    "parent_id" INTEGER,
    "guid" TEXT,
    "title" TEXT,
    "link" TEXT,
    "description" TEXT,
    "content" TEXT,
    "author" TEXT,
    "pubdate" INTEGER,
    "source" TEXT,
    "comments_url" TEXT,
    "tags" TEXT,
    "savedate" INTEGER,
    "unread" INTEGER,
    "starred" INTEGER);
CREATE TABLE enclosures (
    "item_id" TEXT NOT NULL,
    "guid" TEXT NOT NULL UNIQUE,
    "uri" TEXT NOT NULL,
    "name" TEXT,
    "length" INTEGER,
    "mimetype" TEXT);
CREATE TABLE tags (
);
PRAGMA user_version = 1;
