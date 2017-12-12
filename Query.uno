using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class Query : DB.SQLElement
{
    public string SQL { get; set; }

    protected override void OnRooted()
    {
        debug_log "Query OnRooted";
        base.OnRooted();
        SQLiteInstance.RegisterQuery(Name, SQL);
    }
}
