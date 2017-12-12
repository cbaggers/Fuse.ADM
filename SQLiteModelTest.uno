using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class DB : Behavior
{
    RootableList<IDBElement> _elements;

    [UXContent]
    public IList<IDBElement> Elements
    {
        get
        {
            if (_elements == null)
            {
                _elements = new RootableList<IDBElement>();
                if (IsRootingCompleted)
                    _elements.Subscribe(OnElementAdded, OnElementRemoved);
            }
            return _elements;
        }
    }

    void OnElementAdded(IDBElement elem)
    {
        if (elem is Table)
        {
            OnTable((Table)elem);
        }
        else
        {
            OnQuery((Query)elem);
        }
    }

    void OnElementRemoved(IDBElement elem)
    {
        if (elem is Table)
        {
            OnTableRemoved((Table)elem);
        }
        else
        {
            OnQueryRemoved((Query)elem);
        }
    }

    void OnTable(Table table)
    {
    }

    void OnQuery(Query table)
    {
    }

    void OnTableRemoved(Table table)
    {
    }

    void OnQueryRemoved(Query table)
    {
    }
}

abstract class IDBElement : Behavior {}

class Table : IDBElement
{
    RootableList<Row> _elements;

    [UXContent]
    public IList<Row> Elements
    {
        get
        {
            if (_elements == null)
            {
                _elements = new RootableList<Row>();
                if (IsRootingCompleted)
                    _elements.Subscribe(OnRowAdded, OnRowRemoved);
            }
            return _elements;
        }
    }

    void OnRowAdded(Row elem)
    {
    }

    void OnRowRemoved(Row elem)
    {
    }
}

class Query : IDBElement
{
    public string SQL { get; set; }
}

class Row : Behavior
{
}


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
        return new object(); // todo, obviously
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
}

[UXFunction("query")]
public class SQLQueryExpression : SimpleVarArgFunction
{
    protected override void OnNewArguments(Argument[] args, IListener listener)
    {
        SQLiteInstance.RegisterQueryExpression((string)args[0].Value, this);
    }
}
