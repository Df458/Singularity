/*
	Singularity - A web newsfeed aggregator
	Copyright (C) 2017  Hugues Ross <hugues.ross@gmail.com>

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

// TODO: Change this to be more sensible, and pick a directory based on whether it's installed or not
const string DEFAULT_SCHEMA_DIR = "/usr/local/share/singularity/schemas";
/* const string DEFAULT_SCHEMA_DIR = "../data/schemas"; */

// This class manages the database.
// It is responsible for creating and updating the database schema, as well as managing the DatabaseRequestProcessors
public class DatabaseManager
{
    public bool is_open { get; private set; }
    public int  pending_requests
    {
        get
        {
            int count = 0;
            foreach(DatabaseRequestProcessor p in processors)
                count += p.requests.length();

            return count;
        }
    }

    public DatabaseManager.from_path(string path)
    {
        try {
            m_database = new Database(path, FileMode.READ | FileMode.WRITE | FileMode.CREATE);
            if(m_database.schema_version == 0) {
                warning("Initializing database\u2026");
                init_schema();
            }

            while(update_schema_version());
        } catch(SQLHeavy.Error e) {
            error("Failed to initialize the database at %s: %s", path, e.message);
        }
        is_open = true;

        for(int i = 0; i < RequestPriority.COUNT; ++i) {
            processors[i] = new DatabaseRequestProcessor(m_database_mutex, m_database);
        }
    }

    // Queue a request for the processors to execute
    public void queue_request(DatabaseRequest req, RequestPriority prio = RequestPriority.DEFAULT)
    {
        processors[prio].requests.push(req);
    }

    // Queues a request, then yields until finished
    public async void execute_request(DatabaseRequest req, RequestPriority prio = RequestPriority.DEFAULT)
    {
        SourceFunc func = execute_request.callback;
        req.processing_complete.connect(() => {Idle.add((owned)func);});
        queue_request(req);

        yield;
    }

    private Database m_database;
    private Mutex    m_database_mutex = Mutex();
    private DatabaseRequestProcessor[] processors = {};

    // Attempt to sequentially update the database schema
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

    // Run the initial database creation schema
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
}

// Wraps database requests using a provided handle and mutex
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
