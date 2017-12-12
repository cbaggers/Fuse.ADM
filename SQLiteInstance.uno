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

    static Dictionary<string, string> _queries = new Dictionary<string, string>();
    static Dictionary<string, List<SQLQueryExpression>> _expressions = new Dictionary<string, List<SQLQueryExpression>>();

    static public void EnsureInitialized()
    {
        debug_log "in EnsureInitialized";
        if (_instance!=null) return;

        lock (_sqliteGlobalLock)
        {
            if (_instance!=null) return;
            _instance = MakeInstance();
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
            _queries[name] = sql;
        }
    }

    static public void RegisterQueryExpression(string queryName, SQLQueryExpression expr)
    {
        EnsureInitialized();

        lock (_sqliteGlobalLock)
        {
            if (!_expressions.ContainsKey(queryName))
            {
                _expressions[queryName] = new List<SQLQueryExpression>();
            }

            var exprs = _expressions[queryName];
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
            while (true)
            {
                // weeee
            }
        }
    }
}
