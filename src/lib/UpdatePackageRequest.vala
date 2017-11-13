/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2016  Hugues Ross <hugues.ross@gmail.com>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
using SQLHeavy;

namespace Singularity
{
    public class UpdatePackageRequest : DatabaseRequest, GLib.Object
    {
        public enum Status
        {
            FEED = 0,
            ICON_INSERT,
            UNREAD_PRE,
            /* CRTABLE, */
            /* CRINDEX, */
            INSERT_ENCLOSURE,
            INSERT,
            /* COPY, */
            /* DRTABLE, */
            CLEANUP,
            UNREAD,
            COUNT
        }

        public UpdatePackage package { get; construct; }
        public int unread_count { get; private set; }

        public UpdatePackageRequest(UpdatePackage pak, bool use_owner_id = true)
        {
            Object(package: pak);
            m_use_owner_id = use_owner_id;

            foreach(Item i in package.new_items)
                i.prepare_for_db();
        }

        public Query build_query(Database db)
        {
            switch(m_status) {
                case Status.ICON_INSERT:
                    StringBuilder q_builder = new StringBuilder("INSERT OR REPLACE INTO icons (id, width, height, alpha, bits, rowstride, data) VALUES ");
                    q_builder.append_printf("(%d, %d, %d, %d, %d, %d, :data)", package.feed.id, package.feed.icon.width, package.feed.icon.height, package.feed.icon.has_alpha ? 1 : 0, package.feed.icon.bits_per_sample, package.feed.icon.rowstride);
                    Query q;
                    try {
                        q = new Query(db, q_builder.str);
                        q.set_blob(":data", package.feed.icon.get_pixels_with_length());
                    } catch(SQLHeavy.Error e) {
                        error("Failed to save item updates: %s", e.message);
                    }
                    return q;

                case Status.INSERT:
                    StringBuilder q_builder = new StringBuilder("REPLACE INTO items (guid, parent_id, weak_guid, title, link, content, rights, publish_time, update_time, load_time, unread, starred) VALUES ");
                    add_item(q_builder, package.new_items[0], true);
                    for(int i = 1; i < package.new_items.size; i++)
                        add_item(q_builder, package.new_items[i], false);
                    Query q;
                    try {
                        q = new Query(db, q_builder.str);
                    } catch(SQLHeavy.Error e) {
                        error("Failed to save item updates for %s: %s. Cammand was:\n%s", package.feed.to_string(), e.message, q_builder.str);
                    }
                    return q;

                case Status.INSERT_ENCLOSURE:
                    StringBuilder q_builder = new StringBuilder("REPLACE INTO enclosures (feed_id, item_guid, guid, uri, name, length, mimetype) VALUES ");
                    bool first = true;
                    foreach(Item i in package.new_items) {
                        foreach(Attachment a in i.attachments) {
                            if(!first)
                                q_builder.append(",\n");

                            a.prepare_for_db(i);
                            q_builder.append_printf("(%d, %s, %s, %s, %s, %d, %s)", package.feed.id, sql_str(i.guid), sql_str(a.guid), sql_str(a.url), sql_str(a.name), a.size, sql_str(a.mimetype));
                            first = false;
                        }
                    }
                    Query q;
                    try {
                        q = new Query(db, q_builder.str);
                    } catch(SQLHeavy.Error e) {
                        error("Failed to save item enclosures: %s", e.message);
                    }
                    return q;

                case Status.CLEANUP:
                    StringBuilder q_builder = new StringBuilder("DELETE FROM items");
                    q_builder.append_printf(" WHERE `parent_id` = %d AND (", package.feed.id);
                    bool delete_read = AppSettings.read_rule[2] == 2;
                    bool delete_unread = AppSettings.unread_rule[2] == 2;
                    DateTime read_time = new DateTime.now_utc();
                    DateTime unread_time = new DateTime.now_utc();

                    if(delete_read) {
                        switch(AppSettings.read_rule[1]) {
                            case 0:
                                read_time = read_time.add_days(AppSettings.read_rule[0] * -1);
                            break;
                            case 1:
                                read_time = read_time.add_months(AppSettings.read_rule[0] * -1);
                            break;
                            case 2:
                                read_time = read_time.add_years(AppSettings.read_rule[0] * -1);
                            break;
                        }
                        q_builder.append_printf("(`unread` = 0 AND `load_time` < %lld)", read_time.to_unix());
                        if(delete_unread)
                            q_builder.append(" OR ");
                        else
                            q_builder.append(")");
                    }

                    if(delete_unread) {
                        switch(AppSettings.unread_rule[1]) {
                            case 0:
                                unread_time = unread_time.add_days(AppSettings.unread_rule[0] * -1);
                            break;
                            case 1:
                                unread_time = unread_time.add_months(AppSettings.unread_rule[0] * -1);
                            break;
                            case 2:
                                unread_time = unread_time.add_years(AppSettings.unread_rule[0] * -1);
                            break;
                        }
                        q_builder.append_printf("(`unread` = 1 AND `load_time` < %lld))", unread_time.to_unix());
                    }
                    Query q;
                    try {
                        q = new Query(db, q_builder.str);
                    } catch(SQLHeavy.Error e) {
                        error("Failed to clean table: %s", e.message);
                    }
                    return q;

                case Status.UNREAD_PRE:
                case Status.UNREAD:
                    Query q;
                    StringBuilder q_builder = new StringBuilder("SELECT sum(items.unread) AS unread_count FROM items");
                    q_builder.append_printf(" WHERE parent_id = %d", package.feed.id);
                    try {
                        q = new Query(db, q_builder.str);
                    } catch(SQLHeavy.Error e) {
                        error("Failed to clean table: %s", e.message);
                    }
                    return q;
            }

            if(m_use_owner_id) {
                StringBuilder q_builder = new StringBuilder();
                q_builder.append_printf("UPDATE feeds SET title = %s, link = %s, site_link = %s, description = %s, rights = %s, generator = %s, last_update = %lld WHERE id = %d", sql_str(package.feed.title), sql_str(package.feed.link), sql_str(package.feed.site_link), sql_str(package.feed.description), sql_str(package.feed.rights), sql_str(package.feed.generator), package.feed.last_update.to_unix(), package.feed.id);
                Query q;
                try {
                    q = new Query(db, q_builder.str);
                } catch(SQLHeavy.Error e) {
                    error("Failed to update: %s", e.message);
                }
                return q;
            }

            StringBuilder q_builder = new StringBuilder();
            q_builder.append_printf("SELECT id FROM feeds WHERE link = %s", sql_str(package.feed.link));
            Query q;
            try {
                q = new Query(db, q_builder.str);
            } catch(SQLHeavy.Error e) {
                error("Failed to get owner id: %s", e.message);
            }
            return q;
        }

        public RequestStatus process_result(QueryResult res)
        {
            m_status += 1;

            if(m_status == Status.INSERT_ENCLOSURE) {
                int count = 0;
                foreach(Item i in package.new_items)
                    count += i.attachments.size;
                if(count == 0)
                    m_status += 1;
            }

            if(m_status == Status.ICON_INSERT && !m_use_owner_id) {
                try {
                    package.feed.prepare_for_db(res.fetch_int(res.field_index("id")));
                } catch(SQLHeavy.Error e) {
                    error("Failed to fix id for update: %s", e.message);
                }
            }

            if((m_status == Status.ICON_INSERT && package.feed.icon == null) ||
               (m_status == Status.CLEANUP && AppSettings.read_rule[2] != 2 && AppSettings.unread_rule[2] != 2))
                m_status += 1;

            if(m_status == Status.INSERT && package.new_items.size == 0)
                m_status = Status.CLEANUP;

            try {
                if(m_status == Status.UNREAD_PRE + 1) {
                    unread_count = res.get_int("unread_count") * -1;
                }

                if(m_status == Status.UNREAD + 1) {
                    unread_count += res.get_int("unread_count");
                }

            } catch(SQLHeavy.Error e) {
                error("Failed retrieve unread counts: %s", e.message);
            }


            if(m_status == Status.COUNT)
                return RequestStatus.DEFAULT;

            return RequestStatus.CONTINUE;
        }

        private void add_item(StringBuilder q_builder, Item i, bool first)
        {
            if(!first)
                q_builder.append(",\n");
            i.prepare_for_db();
            q_builder.append_printf(" (%s, %d, %s, %s, %s, %s, %s, %lld, %lld, %lld, %d, %d)", sql_str(i.guid), package.feed.id, sql_str(i.weak_guid), sql_str(i.title), sql_str(i.link), sql_str(i.content), sql_str(i.rights), i.time_published.to_unix(), i.time_updated.to_unix(), i.time_loaded.to_unix(), i.unread, i.starred);
        }

        private Status m_status = Status.FEED;
        private bool m_use_owner_id = true;
    }
}
