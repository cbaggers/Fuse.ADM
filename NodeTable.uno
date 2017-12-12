using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class Table : DB.SQLElement
{
    RootableList<Column> _elements;

    [UXContent]
    public IList<Column> Elements
    {
        get
        {
            if (_elements == null)
            {
                _elements = new RootableList<Column>();
                if (IsRootingCompleted)
                    _elements.Subscribe(OnColumnAdded, OnColumnRemoved);
            }
            return _elements;
        }
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
