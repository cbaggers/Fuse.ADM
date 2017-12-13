using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class DB : Behavior
{
    public abstract class SQLElement {}

    public string File { get; set; }

    RootableList<SQLElement> _elements = new RootableList<SQLElement>();

    protected override void OnRooted()
    {
        base.OnRooted();
        debug_log "DB rooted";
        SQLiteInstance.Initialize(File);
        _elements.RootSubscribe(OnElementAdded, OnElementRemoved);
    }

    protected override void OnUnrooted()
    {
        base.OnUnrooted();
        _elements.RootUnsubscribe();
    }

    [UXContent]
    public IList<SQLElement> Elements
    {
        get
        {
            return _elements;
        }
    }

    void OnElementAdded(SQLElement elem)
    {
        debug_log "sup " + elem;
        if (elem is Table)
        {
            OnTable((Table)elem);
        }
        else
        {
            OnSelect((Select)elem);
        }
    }

    void OnElementRemoved(SQLElement elem)
    {
        if (elem is Table)
        {
            OnTableRemoved((Table)elem);
        }
        else
        {
            OnSelectRemoved((Select)elem);
        }
    }

    void OnTable(Table table)
    {
        SQLiteInstance.RegisterTable(table.Describe());
    }

    void OnSelect(Select query)
    {
        SQLiteInstance.RegisterSelect(query.SQL);
    }

    void OnTableRemoved(Table table)
    {
    }

    void OnSelectRemoved(Select table)
    {
    }
}
