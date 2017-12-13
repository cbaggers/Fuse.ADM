using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

public class Select : DB.SQLElement
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
    internal Dictionary<string, Func<string,object>> Casts = new Dictionary<string, Func<string,object>>();

    string _as;
    public string As
    {
        get
        {
            return _as;
        }
        set
        {
            _as = value;
            var casts = new Dictionary<string, Func<string,object>>();
            var split = value.Split(',');
            foreach (var part in split)
            {
                var pair = part.Split(':');
                var key = pair[0].Trim();
                var typ = pair[1].Trim().ToUpper();
                if (typ == "INT")
                {
                    casts[key] = ToInt;
                }
                else if (typ == "BOOL")
                {
                    casts[key] = ToBool;
                }
            }
            Casts = casts;
        }
    }

    object ToInt(string x)
    {
        return int.Parse(x);
    }

    object ToBool(string x)
    {
        return x.ToUpper() == "TRUE";
    }
}
