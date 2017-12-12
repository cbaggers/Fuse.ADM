using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class DB : Behavior
{
    abstract class IDBElement : Behavior {}

    RootableList<IDBElement> _elements;

    [UXContent]
    public IList<IDBElement> Elements
    {
        get
        {
            if (_elements == null)
            {
                _elements = new RootableList<IDBElement>();
                if (IsRootingCompleted)
                    _elements.Subscribe(OnElementAdded, OnElementRemoved);
            }
            return _elements;
        }
    }

    void OnElementAdded(IDBElement elem)
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

    void OnElementRemoved(IDBElement elem)
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
