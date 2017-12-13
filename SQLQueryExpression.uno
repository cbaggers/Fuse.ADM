using Uno;
using Uno.UX;
using Uno.Text;
using Uno.Threading;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

using Fuse;
using Fuse.Reactive;

// fucking hate this, howeve VarArgFunction.Subscription is protected..gah
public interface IQuerySubscription : IDisposable
{
    Select Query { get; }
    string[] QueryParams { get; }
    void DispatchQueryResult(QueryResult data);
}

[UXFunction("query")]
public class SQLQueryExpression : SimpleVarArgFunction
{
    public override IDisposable Subscribe(IContext context, IListener listener)
    {
        return new QuerySubscription(this, context, listener);
    }

    sealed class QuerySubscription: Subscription, IQuerySubscription
    {
        public string[] QueryParams { get; private set; }
        public Select Query { get; private set; }

        IListener _listener;
        SimpleVarArgFunction _func;

        public QuerySubscription(SimpleVarArgFunction func, IContext context, IListener listener)
            : base(func, context)
        {
            QueryParams = new string[0];
            _func = func;
            _listener = listener;
            Init();
        }

        protected override void OnNewArguments(Argument[] args)
        {
            SQLiteInstance.UnRegisterQueryExpression(this);

            Query = args[0].Value as Select;
            if (Query!=null)
            {
                SQLiteInstance.RegisterQueryExpression(this);
            }

            var queryParams = new List<string>();
            if (args.Length > 1)
            {
                for (var i = 1; i<args.Length; i++)
                {
                    queryParams.Add(args[i].HasValue ? args[i].Value.ToString() : "null");
                }
            }
            QueryParams = queryParams.ToArray();
        }

        public void DispatchQueryResult(QueryResult data)
        {
            _listener.OnNewData(_func, data);
        }

        public override void Dispose()
        {
            _listener = null;
            _func = null;
            SQLiteInstance.UnRegisterQueryExpression(this);
            base.Dispose();
        }
    }
}
