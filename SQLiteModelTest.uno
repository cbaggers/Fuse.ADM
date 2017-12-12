using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Reactive;

class Test
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
