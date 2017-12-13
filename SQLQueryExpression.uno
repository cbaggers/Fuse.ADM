using Uno;
using Uno.UX;
using Uno.Text;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

[UXFunction("query")]
public class SQLQueryExpression : SimpleVarArgFunction
{
    IListener _listener;
    public readonly object ParamLock = new object();
    public string[] QueryParams = new string[0];

    protected override void OnNewArguments(Argument[] args, IListener listener)
    {
        lock (ParamLock)
        {
            var queryParams = new List<string>();

            if (args.Length > 1)
            {
                for (var i = 1; i<args.Length; i++)
                {
                    queryParams.Add(args[i].HasValue ? args[i].Value.ToString() : "null");
                }
            }
            QueryParams = queryParams.ToArray();
        }

        var queryElem = args[0].Value as Select;
        if (queryElem!=null)
        {
            SQLiteInstance.RegisterQueryExpression(queryElem, this);
        }

        _listener = listener;
    }

    public void DispatchQueryResult(QueryResult data)
    {
        _listener.OnNewData(this, data);
    }
}
