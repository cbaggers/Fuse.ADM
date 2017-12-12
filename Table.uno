using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class Table : DB.SQLElement
{
    RootableList<Column> _elements = new RootableList<Column>();

    [UXContent]
    public IList<Column> Elements
    {
        get
        {
            debug_log "Here we are!";
            return _elements;
        }
    }

    protected override void OnRooted()
    {
        debug_log "hi " + _elements.Count;
        base.OnRooted();
        _elements.RootSubscribe(OnColumnAdded, OnColumnRemoved);
    }

    protected override void OnUnrooted()
    {
        _elements.RootUnsubscribe();
        base.OnUnrooted();
    }

    void OnColumnAdded(Column elem)
    {
        debug_log "row added";
        UpdateTable();
    }

    void OnColumnRemoved(Column elem)
    {
        debug_log "row removed";
        UpdateTable();
    }

    void UpdateTable()
    {
    }
}

class Column : Behavior
{
    // public string Name { get; set; }
}
