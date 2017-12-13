using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;
using Fuse.Scripting;

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
        // this is a bad idea, happens too frequently
        // SQLiteInstance.DeleteTable(table.Describe());
    }

    void OnSelectRemoved(Select query)
    {
        SQLiteInstance.UnRegisterSelect(query.SQL);
    }
}

[UXGlobalModule]
class DBJS : NativeModule
{
    static readonly DBJS _instance;

    public DBJS()
    {
        if(_instance != null) return;
        Uno.UX.Resource.SetGlobalKey(_instance = this, "DB");

        AddMember(new NativeFunction("insert", (NativeCallback)Insert));
        AddMember(new NativeFunction("update", (NativeCallback)Update));
        AddMember(new NativeFunction("delete", (NativeCallback)Delete));
    }

    public object Insert(Context c, object[] args)
    {
        Dispatch("INSERT", args);
        return null;
    }

    public object Update(Context c, object[] args)
    {
        Dispatch("UPDATE", args);
        return null;
    }

    public object Delete(Context c, object[] args)
    {
        Dispatch("DELETE", args);
        return null;
    }

    void Dispatch(string kind, object[] args)
    {
        assert (args.Length>0);
        var sql = kind + " " + (string)args[0];
        var queryParams = new List<string>();
        for (var i = 1; i<args.Length; i++)
        {
            queryParams.Add(Marshal.ToType<string>(args[i]));
        }
        SQLiteInstance.ExecuteMutating(sql, queryParams);
    }
}
