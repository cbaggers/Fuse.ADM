using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class DB : Behavior
{
    public abstract class SQLElement : Behavior {}

    public string File { get; set; }

    RootableList<SQLElement> _elements;

    protected override void OnRooted()
    {
        base.OnRooted();
        SQLiteInstance.Initialize(File);
    }

    [UXContent]
    public IList<SQLElement> Elements
    {
        get
        {
            if (_elements == null)
            {
                _elements = new RootableList<SQLElement>();
                if (IsRootingCompleted)
                    _elements.Subscribe(OnElementAdded, OnElementRemoved);
            }
            return _elements;
        }
    }

    void OnElementAdded(SQLElement elem)
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

    void OnElementRemoved(SQLElement elem)
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
