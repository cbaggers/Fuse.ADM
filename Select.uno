using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class Select : DB.SQLElement
{
    string _sql;
    public string SQL
    {
        get
        {
            return _sql;
        }
        set
        {
            _sql = "SELECT " + value;
        }
    }
}
