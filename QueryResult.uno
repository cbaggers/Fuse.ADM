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

    public QueryResult(List<QueryResultRow> data)
    {
        _items = data;
    }

    public QueryResult(List<Dictionary<string, string>> data)
    {
        List<QueryResultRow> rows = new List<QueryResultRow>();
        foreach (var row in data)
        {
            rows.Add(new QueryResultRow(row));
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
}

public class QueryResultRow : IObject
{
    Dictionary<string, string> _data;

    public QueryResultRow(Dictionary<string, string> data)
    {
        _data = data;
    }

    bool IObject.ContainsKey(string key) { return _data.ContainsKey(key); }
    object IObject.this[string key] { get { return _data[key]; } }
    string[] IObject.Keys { get { return _data.Keys.ToArray(); } }
}
