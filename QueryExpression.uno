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
    protected override void OnNewArguments(Argument[] args, IListener listener)
    {
        SQLiteInstance.RegisterQueryExpression((string)args[0].Value, this);
    }
}
