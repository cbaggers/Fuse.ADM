using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

class Table : DB.SQLElement
{
    public string Name { get; set; }

    RootableList<Column> _elements = new RootableList<Column>();

    [UXContent]
    public IList<Column> Elements
    {
        get
        {
            return _elements;
        }
    }

    public Description Describe()
    {
        var len = Elements.Count;
        var cols = new List<Column.Description>();
        for (var i = 0; i < len; i++)
        {
            cols.Add(Elements[i].Describe());
        }
        return new Description { Name=Name, Columns=cols };
    }

    public struct Description
    {
        public string Name;
        public List<Column.Description> Columns;
    }
}

class Column : Behavior
{
    public string Name { get; set; }

    string _type = "TEXT";
    public string Type
    {
        get
        {
            return _type;
        }
        set
        {
            _type = value.ToUpper();
        }
    }

    public Description Describe()
    {
        return new Description { Name=Name, Type=Type };
    }

    public struct Description
    {
        public string Name { get; set; }
        public string Type { get; set; }
    }
}
