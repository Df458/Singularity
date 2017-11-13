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
using Singularity;

/* const string DEFAULT_SCHEMA_DIR = "/usr/local/share/singularity/schemas"; */
const string DEFAULT_SCHEMA_DIR = "../data/schemas";

public class DatabaseManager
{
    public bool is_open { get; private set; }

    public DatabaseManager.from_path(string path)
    {
        m_database_mutex = Mutex();

        try {
            m_database = new Database(path, FileMode.READ | FileMode.WRITE | FileMode.CREATE);
            if(m_database.schema_version == 0) {
                info("Initializing database\u2026");
                init_schema();
            }

            while(update_schema_version());
        } catch(SQLHeavy.Error e) {
            error("Failed to initialize the database at %s: %s", path, e.message);
        }
        is_open = true;

        processors = {};
        for(int i = 0; i < RequestPriority.COUNT; ++i) {
            processors[i] = new DatabaseRequestProcessor(m_database_mutex, m_database);
        }
    }

    public void queue_request(DatabaseRequest req, RequestPriority prio = RequestPriority.DEFAULT)
    {
        processors[prio].requests.push(req);
    }

    public async void execute_request(DatabaseRequest req, RequestPriority prio = RequestPriority.DEFAULT)
    {
        SourceFunc func = execute_request.callback;
        req.processing_complete.connect(() => {Idle.add(func);});
        processors[prio].requests.push(req);

        yield;
    }

    /* public signal void query_complete(DatabaseRequest req, bool success = true); */

    //-------------------------------------------------------------------------

    private Database m_database;
    private Mutex    m_database_mutex;
    private DatabaseRequestProcessor[] processors;

    private bool update_schema_version(string schema_dir = DEFAULT_SCHEMA_DIR)
    {
        StringBuilder builder = new StringBuilder(schema_dir);
        builder.append_printf("/Update-to-%d.sql", m_database.user_version + 1);
        File script = File.new_for_path(builder.str);
        if(!script.query_exists())
            return false;

        try {
            m_database.run_script(builder.str);
        } catch(SQLHeavy.Error e) {
            error("Cannot update database version to %d: %s", m_database.user_version + 1, e.message);
        }
        m_database.user_version += 1;
        return true;
    }

    private void init_schema(string schema_dir = DEFAULT_SCHEMA_DIR)
    {
        StringBuilder builder = new StringBuilder(schema_dir);
        builder.append("/Create.sql");
        File script = File.new_for_path(builder.str);
        if(!script.query_exists())
            error("Cannot create database: Schema initializer %s not found", builder.str);

        try {
            m_database.run_script(builder.str);
        } catch(SQLHeavy.Error e) {
            error("Cannot create database: %s", e.message);
        }
    }

/*     private async void cleanup_id(int id) */
/*     { */
/*         StringBuilder q_builder = new StringBuilder("DELETE FROM items WHERE `parent_id` = :id AND ("); */
/*         bool delete_read = m_global_settings.read_rule[2] == 2; */
/*         bool delete_unread = m_global_settings.unread_rule[2] == 2; */
/*         if(!delete_read && !delete_unread) */
/*             return; */
/*         DateTime read_time = new DateTime.now_utc(); */
/*         DateTime unread_time = new DateTime.now_utc(); */
/*  */
/*         if(delete_read) { */
/*             q_builder.append("(`unread` = 0 AND `load_time` < :read_time)"); */
/*             read_time = read_time.add_minutes(-1); */
/*             switch(m_global_settings.read_rule[1]) { */
/*                 case 0: */
/*                     read_time = read_time.add_days(m_global_settings.read_rule[0] * -1); */
/*                     break; */
/*                 case 1: */
/*                     read_time = read_time.add_months(m_global_settings.read_rule[0] * -1); */
/*                     break; */
/*                 case 2: */
/*                     read_time = read_time.add_years(m_global_settings.read_rule[0] * -1); */
/*                     break; */
/*             } */
/*             if(delete_unread) */
/*                 q_builder.append(" OR "); */
/*             else */
/*                 q_builder.append(")"); */
/*         } */
/*  */
/*         if(delete_unread) { */
/*             q_builder.append_printf("(`unread` = 1 AND `load_time` < :unread_time))"); */
/*             switch(m_global_settings.unread_rule[1]) { */
/*                 case 0: */
/*                     unread_time = unread_time.add_days(m_global_settings.unread_rule[0] * -1); */
/*                     break; */
/*                 case 1: */
/*                     unread_time = unread_time.add_months(m_global_settings.unread_rule[0] * -1); */
/*                     break; */
/*                 case 2: */
/*                     unread_time = unread_time.add_years(m_global_settings.unread_rule[0] * -1); */
/*                     break; */
/*             } */
/*             stderr.printf("Deleting unread\u2026\n"); */
/*         } */
/*  */
/*         try { */
/*             Query q_clean = new Query(db, q_builder.str); */
/*             q_clean[":id"] = id; */
/*             if(delete_read) */
/*                 q_clean[":read_time"] = read_time.to_unix(); */
/*             if(delete_unread) */
/*                 q_clean[":unread_time"] = unread_time.to_unix(); */
/*             yield q_clean.execute_async(); */
/*         } catch(SQLHeavy.Error e) { */
/*             error("Can't clean up id: %s: %s", e.message, q_builder.str); */
/*         } */
/*     } */
}

public class DatabaseRequestProcessor
{
    public AsyncQueue<DatabaseRequest> requests { get; set; }

    public DatabaseRequestProcessor(Mutex m, Database db) {
        requests = new AsyncQueue<DatabaseRequest>();
        processing_thread = new Thread<void*>(null, process);
        data_mutex = m;
        database = db;
    }

    private Thread<void*> processing_thread;
    private unowned Mutex data_mutex;
    private unowned Database database;

    private void* process()
    {
        while(true) {
            DatabaseRequest req = requests.pop();
            RequestStatus status = RequestStatus.CONTINUE;
            data_mutex.lock();
            do {
                Query q = req.build_query(database);
                try {
                    QueryResult res = q.execute();
                    status = req.process_result(res);
                } catch(SQLHeavy.Error e) {
                    error("Failed to process request: %s. Query is [%s]", e.message, q.sql);
                }
            } while(status == RequestStatus.CONTINUE);
            data_mutex.unlock();

            req.processing_complete();
        }
    }
}
