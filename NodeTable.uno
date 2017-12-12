using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

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
        debug_log "row added";
        UpdateTable();
    }

    void OnRowRemoved(Row elem)
    {
        debug_log "row removed";
        UpdateTable();
    }

    void UpdateTable()
    {
    }
}

class Row : Behavior
{
    public string Name { get; set; }
}
