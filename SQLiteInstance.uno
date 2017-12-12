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
    static object _instance;
    static string _dbFileName;

    static List<string> _queries = new List<string>();
    static Dictionary<string, List<SQLQueryExpression>> _expressions = new Dictionary<string, List<SQLQueryExpression>>();

    static public void Initialize(string file)
    {
        lock (_sqliteGlobalLock)
        {
            if (_instance!=null) return;
            _dbFileName = file;
            _instance = MakeInstance();
        }
    }

    bool IsInitialized
    {
        get
        {
            lock (_sqliteGlobalLock)
            {
                return _instance == null;
            }
        }
    }

    static object MakeInstance()
    {
        debug_log "in MakeInstance";
        return new SQLThread();
    }

    static public void RegisterQuery(string name, string sql)
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
        // var cols = new List<string>();
        // foreach (var col in table.Elements)
        // {
        //     cols.Add("`" + col.Name + "` TEXT");
        // }
        // var query = "CREATE TABLE `" + table.Name + "` (" + string.Join(", ", cols.ToArray()) + ")";
        // debug_log "query: " + query;
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

    class SQLThread
    {
        Thread _thread;

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
            SQLiteDb.Open(_dbFileName);
            debug_log "db open: " + _dbFileName;
            debug_log "start the main sql loop";
            while (true)
            {
                lock (_sqliteGlobalLock)
                {
                    // time to do shit
                }
            }
        }
    }
}
