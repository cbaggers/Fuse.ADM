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
        var cols = new List<Column.Description>(Elements.Count);
        for (var i = 0; i < cols.Count; i++)
        {
            cols[i] = Elements[i].Describe();
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
    public string Type { get; set; }

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
