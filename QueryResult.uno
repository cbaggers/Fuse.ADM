using Uno;
using Uno.UX;
using Uno.Text;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

public class QueryResult: IArray
{
    List<QueryResultRow> _items;

    public QueryResult()
    {
        _items = new List<QueryResultRow>();
    }

    public QueryResult(List<QueryResultRow> data)
    {
        _items = data;
    }

    public QueryResult(List<Dictionary<string, string>> data)
    {
        List<QueryResultRow> rows = new List<QueryResultRow>();
        if (data != null)
        {
            foreach (var row in data)
            {
                rows.Add(new QueryResultRow(row));
            }
        }
        _items = rows;
    }

    object IArray.this[int index] { get { return _items[index]; } }

    int IArray.Length { get { return _items.Count; } }

    public override string ToString()
    {
        var sb = new StringBuilder();
        sb.Append("(");
        for (var i = 0; i < _items.Count; i++)
        {
            if (i > 0) sb.Append(", ");
            sb.Append(_items[i].ToString());
        }
        sb.Append(")");
        return sb.ToString();
    }

    public QueryResult Cast(Dictionary<string, Func<string,object>> casts)
    {
        var castLen = casts.Count;
        var newRows = new List<QueryResultRow>();
        var i = 0;
        foreach (var row in _items)
        {
            newRows.Add(row.Cast(casts));
        }
        return new QueryResult(newRows);
    }

    public static readonly QueryResult NULL = new QueryResult();
}

public class QueryResultRow : IObject
{
    Dictionary<string, object> _data;

    public QueryResultRow(Dictionary<string, object> data)
    {
        _data = data;
    }

    public QueryResultRow(Dictionary<string, string> data)
    {
        var newVals = new Dictionary<string, object>();
        foreach (var key in data.Keys)
        {
            newVals[key] = data[key];
        }
        _data = newVals;
    }

    bool IObject.ContainsKey(string key) { return _data.ContainsKey(key); }
    object IObject.this[string key] { get { return _data[key]; } }
    string[] IObject.Keys { get { return _data.Keys.ToArray(); } }

    public QueryResultRow Cast(Dictionary<string, Func<string,object>> casts)
    {
        var newVals = new Dictionary<string, object>();

        foreach (var key in _data.Keys)
        {
            var val = _data[key];
            if (val is string && casts.ContainsKey(key))
            {
                newVals[key] = casts[key]((string)val);
            }
            else
            {
                newVals[key] = val;
            }
        }
        return new QueryResultRow(newVals);
    }
}
