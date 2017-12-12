using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

[UXFunction("query")]
public class SQLQueryExpression : SimpleVarArgFunction
{
    IListener _listener;

    protected override void OnNewArguments(Argument[] args, IListener listener)
    {
        var queryElem = args[0].Value as Query;

        if (queryElem!=null)
        {
            SQLiteInstance.RegisterQueryExpression(queryElem.Name, this);
        }

        _listener = listener;
    }

    public void UpdateResult(List<IObject> values)
    {
        _listener.OnNewData(this, values);
    }
}
