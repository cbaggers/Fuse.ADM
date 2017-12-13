using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class SQLiteInstance
{
    class QueryCacheItem
    {
        public bool Dirty;
        public readonly List<string> Tables;

        public QueryCacheItem(string sql)
        {
            Dirty = true;
            Tables = GetTablesFromQuery(sql);
        }
    }

    static object _sqliteGlobalLock = new object();
    static SQLThread _thread;
    static string _dbFileName;

    static Dictionary<string, QueryCacheItem> _queries = new Dictionary<string, QueryCacheItem>();
    static Dictionary<string, List<IQuerySubscription>> _expressions = new Dictionary<string, List<IQuerySubscription>>();

    static public void Initialize(string file)
    {
        lock (_sqliteGlobalLock)
        {
            if (_thread!=null) return;
            _dbFileName = file;
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

    static public void RegisterSelect(string sql)
    {
        lock (_sqliteGlobalLock)
        {
            _queries[sql] = new QueryCacheItem(sql);
        }
        _thread.Nudge();
    }

    static public void UnRegisterSelect(string sql)
    {
        lock (_sqliteGlobalLock)
        {
            if (_queries.ContainsKey(sql))
            {
                _queries.Remove(sql);
            }
        }
        _thread.Nudge();
    }

    static public void RegisterTable(Table.Description table)
    {
        _thread.Invoke(new CreateTable(table).Run);
    }

    static public void DeleteTable(Table.Description table)
    {
        _thread.Invoke(new DropTable(table).Run);
    }

    static public void RegisterQueryExpression(IQuerySubscription expr)
    {
        lock (_sqliteGlobalLock)
        {
            var queryID = expr.Query.SQL;
            assert queryID != null;

            if (!_expressions.ContainsKey(queryID))
            {
                _expressions[queryID] = new List<IQuerySubscription>();
            }

            var exprs = _expressions[queryID];
            if (!exprs.Contains(expr))
            {
                exprs.Add(expr);
            }
        }
        _thread.Nudge();
    }

    static public void UnRegisterQueryExpression(IQuerySubscription expr)
    {
        lock (_sqliteGlobalLock)
        {
            // so over the top, should better datastructures
            foreach (var key in _expressions.Keys)
            {
                _expressions[key].Remove(expr);
            }
        }
        _thread.Nudge();
    }

    public static void ExecuteMutating(string sql, List<string> queryParams=null)
    {
        _thread.Invoke(new MutatingExecute(sql, queryParams).Run);
    }

    static List<string> GetTablesFromQuery(string sql, List<string> targetTokens=null)
    {
        // hacky hack hack
        if (targetTokens == null)
        {
            targetTokens = new List<string>();
            targetTokens.Add("FROM");
        }

        var res = new List<string>();
        var tokenIsTableName = false;
        foreach (var token in sql.Split())
        {
            if (tokenIsTableName)
            {
                res.Add(token);
                tokenIsTableName = false;
            }
            else if (targetTokens.Contains(token.ToUpper()))
            {
                tokenIsTableName = true;
            }
        }
        return res;
    }

    static void MarkTableDirty(SQLiteDb db, Table.Description table)
    {
        foreach (var query in _queries.Keys)
        {
            var cacheData = _queries[query];
            if (cacheData.Tables.Contains(table.Name))
            {
                cacheData.Dirty = true;
            }
        }
    }

    class MutatingExecute
    {
        readonly string _sql;
        readonly string[] _queryParams;

        public MutatingExecute(string sql, List<string> queryParams)
        {
            _sql = sql;
            _queryParams = queryParams!=null ? queryParams.ToArray() : new string[0];
        }

        public void Run(SQLiteDb db)
        {
            db.Execute(_sql, _queryParams);

            var sqlUpper = _sql.ToUpper();
            var targetTokens = new List<string>();
            targetTokens.Add("UPDATE");
            if (sqlUpper.Contains("INSERT")) targetTokens.Add("INTO");
            if (sqlUpper.Contains("DELETE")) targetTokens.Add("FROM");
            var tablesModified = GetTablesFromQuery(_sql, targetTokens);
            foreach (var query in _queries.Keys)
            {
                var cacheData = _queries[query];
                foreach (var table in tablesModified)
                {
                    if (cacheData.Tables.Contains(table))
                    {
                        cacheData.Dirty = true;
                        break;
                    }
                }
            }
        }
    }

    class DropTable
    {
        Table.Description _table;

        public DropTable(Table.Description table)
        {
            _table = table;
        }

        public void Run(SQLiteDb db)
        {
            db.Execute("DROP TABLE IF EXISTS " + _table.Name, new string[0]);
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
            MarkTableDirty(db, _table);
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
            var currentColumnNames = info.Keys.ToArray();
            var unchangedColumns = new List<string>();
            var remakeTable = false;

            foreach (var col in _table.Columns)
            {
                if (info.ContainsKey(col.Name))
                {
                    if (info[col.Name] != col.Type)
                    {
                        remakeTable = true;
                    }
                    else
                    {
                        unchangedColumns.Add(col.Name);
                    }
                    info.Remove(col.Name);
                }
                else
                {
                    AddColumn(db, col);
                }
            }

            // if remakeTable is true then there were column modifications
            // if info.Count>0 then there are column deletions
            if (remakeTable || info.Count>0)
            {
                RemakeTable(db, unchangedColumns);
            }
        }

        void AddColumn(SQLiteDb db, Column.Description col)
        {
            var query = "ALTER TABLE " + _table.Name + " ADD " + col.Name + " " + col.Type;
            db.Execute(query, new string[0]);

        }

        void RemakeTable(SQLiteDb db, List<string> unchangedColumns)
        {
            var qp = new string[0];
            var tmpTableName = _table.Name + "_old";
            var columnsToCopy = string.Join(",", unchangedColumns.ToArray());

            db.Execute("ALTER TABLE " + _table.Name + " RENAME TO " + tmpTableName, qp);
            Create(db);
            db.Execute("INSERT INTO " + _table.Name + "(" + columnsToCopy + ") SELECT " + columnsToCopy + " FROM " + tmpTableName, qp);
            db.Execute("DROP TABLE " + tmpTableName, qp);
        }
    }

    class OnUI
    {
        IQuerySubscription _target;
        QueryResult _res;

        public OnUI(IQuerySubscription target, QueryResult res)
        {
            _target = target;
            _res = res;
        }
        public void Run()
        {
            _target.DispatchQueryResult(_res);
        }
    }

    class SQLThread
    {
        readonly ConcurrentQueue<Action<SQLiteDb>> _queue = new ConcurrentQueue<Action<SQLiteDb>>();
        readonly AutoResetEvent _hasTasks = new AutoResetEvent(true);
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
            _db = SQLiteDb.Open(_dbFileName);
            while (true)
            {
                var didSomething = false;
                lock (_sqliteGlobalLock)
                {
                    try
                    {
                        Action<SQLiteDb> action;
                        if (_queue.TryDequeue(out action))
                        {
                            didSomething = true;
                            action(_db);
                        }
                    }
                    catch (Exception e)
                    {
                        debug_log "{TODO} we just swallowed an error: " + e.Message;
                    }

                    foreach (var query in _queries.Keys)
                    {
                        var cacheData = _queries[query];
                        if (!cacheData.Dirty) continue;
                        if (!_expressions.ContainsKey(query)) continue;
                        didSomething = true;
                        var recipients = _expressions[query];
                        if (recipients.Count == 0) continue;
                        try
                        {
                            var i = 0;
                            foreach (var recip in recipients)
                            {
                                var res = new QueryResult(_db.Query(query, recip.QueryParams));
                                UpdateManager.PostAction(new OnUI(recip, res).Run);
                                i++;
                            }
                        }
                        catch (Exception e)
                        {
                            debug_log "{TODO} we just swallowed an error from a select: " + e.Message;
                        }
                        cacheData.Dirty = false;
                    }
                }
                if (!didSomething)
                {
                    _hasTasks.WaitOne();
                }
            }
        }

        public void Invoke(Action<SQLiteDb> action)
        {
            _queue.Enqueue(action);
            _hasTasks.Set();
        }

        public void Nudge()
        {
            _hasTasks.Set();
        }
    }
}
