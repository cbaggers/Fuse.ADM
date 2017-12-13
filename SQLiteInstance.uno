using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class SQLiteInstance
{
    static object _sqliteGlobalLock = new object();
    static SQLThread _thread;
    static string _dbFileName;

    static List<string> _queries = new List<string>();
    static Dictionary<string, List<SQLQueryExpression>> _expressions = new Dictionary<string, List<SQLQueryExpression>>();

    static public void Initialize(string file)
    {
        lock (_sqliteGlobalLock)
        {
            if (_thread!=null) return;
            _dbFileName = file;
            debug_log "MakeInstance";
            _thread = new SQLThread();
        }
    }

    bool IsInitialized
    {
        get
        {
            lock (_sqliteGlobalLock)
            {
                return _thread != null;
            }
        }
    }

    static public void RegisterQuery(string sql)
    {
        lock (_sqliteGlobalLock)
        {
            if (!_queries.Contains(sql))
            {
                _queries.Add(sql);
            }
        }
    }

    static public void RegisterTable(Table.Description table)
    {
        debug_log "Got a table: " + table;
        _thread.Invoke(new CreateTable(table).Run);
    }

    static public void RegisterQueryExpression(Query query, SQLQueryExpression expr)
    {
        lock (_sqliteGlobalLock)
        {
            var queryID = query.SQL;
            if (!_expressions.ContainsKey(queryID))
            {
                _expressions[queryID] = new List<SQLQueryExpression>();
            }

            var exprs = _expressions[queryID];
            if (!exprs.Contains(expr))
            {
                exprs.Add(expr);
            }
        }
    }

    class CreateTable
    {
        Table.Description _table;

        public CreateTable(Table.Description table)
        {
            _table = table;
        }

        public void Run(SQLiteDb db)
        {
            var info = TableInfo(db);
            if (info.Count>0)
            {
                Alter(db, info);
            }
            else
            {
                Create(db);
            }
        }

        Dictionary<string, string> TableInfo(SQLiteDb db)
        {
            var query = "PRAGMA table_info(" + _table.Name + ")";
            var res = db.Query(query, new string[0]);
            var info = new Dictionary<string, string>();
            foreach (var col in res)
            {
                info[col["name"]] = col["type"];
            }
            return info;
        }

        void Create(SQLiteDb db)
        {
            var cols = new List<string>();
            foreach (var col in _table.Columns)
            {
                cols.Add("`" + col.Name + "` TEXT");
            }
            var query = "CREATE TABLE `" + _table.Name + "` (" + string.Join(", ", cols.ToArray()) + ");";
            db.Execute(query, new string[0]);
        }

        void Alter(SQLiteDb db, Dictionary<string, string> info)
        {
            // search for additions and modifications
            // remove what we have handled
            foreach (var col in _table.Columns)
            {
                if (info.ContainsKey(col.Name))
                {
                    if (info[col.Name] != col.Type)
                    {
                        debug_log "col Name=" + col.Name + " Type=" + col.Type;
                        debug_log "info Name=" + col.Name + " Type=" + info[col.Name];
                        ModifyColumn(db);
                    }
                    else
                    {
                        debug_log "Skipped Col";
                    }
                    info.Remove(col.Name);
                }
                else
                {
                    AddColumn(db, col);
                }
                // cols.Add("`" + col.Name + "` TEXT");
            }
            // whatever remains are removals
            foreach (var col in info)
            {
                RemoveColumn(db); //col["name"]);
            }
        }

        void AddColumn(SQLiteDb db, Column.Description col)
        {
            debug_log "ADD COLUMN!";
            var query = "ALTER TABLE " + _table.Name + " ADD " + col.Name + " " + col.Type;
            db.Execute(query, new string[0]);

        }

        void RemoveColumn(SQLiteDb db)
        {
            debug_log "TODO: RemoveColumn";
        }
        void ModifyColumn(SQLiteDb db)
        {
            debug_log "TODO: ModifyColumn";
        }
    }

    class SQLThread
    {
        readonly ConcurrentQueue<Action<SQLiteDb>> _queue = new ConcurrentQueue<Action<SQLiteDb>>();
        Thread _thread;
        SQLiteDb _db;

        public SQLThread()
        {
            _thread = new Thread(SQLMainLoop);
            if defined(DotNet)
            {
                // TODO: Create a method for canceling the thread safely
                // Threads are by default foreground threads
                // Foreground threads prevents the owner process from exiting, before the thread is safely closed
                // This is a workaround by setting the thread to be a background thread.
                _thread.IsBackground = true;
            }

            _thread.Start();
        }

        void SQLMainLoop()
        {
            debug_log "in SQLMainLoop";
            _db = SQLiteDb.Open(_dbFileName);
            debug_log "db open: " + _dbFileName;
            debug_log "start the main sql loop";
            while (true)
            {
                lock (_sqliteGlobalLock)
                {
                    try
                    {
                        Action<SQLiteDb> action;
                        if (_queue.TryDequeue(out action))
                        {
                            action(_db);
                        }
                    }
                    catch (Exception e)
                    {
                        debug_log "{TODO} we just swallowed an error: " + e.Message;
                    }

                    foreach (var query in _queries)
                    {
                        if (!_expressions.ContainsKey(query)) continue;

                        var recipients = _expressions[query];
                        if (recipients.Count == 0) continue;

                        try
                        {
                            var res = new QueryResult(_db.Query(query, new string[0]));
                            var i = 0;
                            foreach (var recip in recipients)
                            {
                                debug_log "sending: " + res + " to " + recip + " (" + i + ")" ;
                                recip.DispatchQueryResult(res);
                                i++;
                            }
                        }
                        catch (Exception e)
                        {
                            debug_log "arsed: " + e.Message;
                        }
                    }
                }
                Thread.Sleep(2000);
            }
        }

        public void Invoke(Action<SQLiteDb> action)
        {
            _queue.Enqueue(action);
        }
    }
}
