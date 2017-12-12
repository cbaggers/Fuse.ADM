using Uno;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;

class Test
{

}


class SQLiteInstance
{
    static object _sqliteGlobalLock = new object();
    static object _instance;

    public void EnsureInitialized()
    {
        if (_instance!=null) return;

        lock (_sqliteGlobalLock)
        {
            if (_instance!=null) return;
            _instance = MakeInstance();
        }
    }

    object MakeInstance()
    {
        return new object(); // todo, obviously
    }
}
