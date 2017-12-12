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
        if (_instance!=null) return;

        lock (_sqliteGlobalLock)
        {
            if (_instance!=null) return;
            _instance = MakeInstance();
        }
    }

    static object MakeInstance()
    {
        return new SQLThread();
    }

    static public void RegisterQuery(string name, string sql)
    {
        lock (_sqliteGlobalLock)
        {
            _queries[name] = sql;
            if (!_expressions.ContainsKey(name))
            {
                _expressions[name] = new List<SQLQueryExpression>();
            }
        }
    }

    static public void RegisterQueryExpression(string queryName, SQLQueryExpression expr)
    {
        EnsureInitialized();

        var exprs = _expressions[queryName];
        if (!exprs.Contains(expr))
        {
            exprs.Add(expr);
        }
    }

    class SQLThread
    {
        Thread _thread;

        public SQLThread()
        {
            _thread = new Thread(SQLMainLoop);
        }

        void SQLMainLoop()
        {
            while (true)
            {
                // weeee
            }
        }
    }
}
