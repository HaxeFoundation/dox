package dox;

import haxe.macro.Expr;
import haxe.macro.Context;
using Lambda;

class TemplateMacro
{
	public static function build()
	{
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();

		var allArgs = [];
		var filters = new Map<String, Bool>();

		for (field in fields)
		{
			filters.set(field.name, true);
		}

		for (file in sys.FileSystem.readDirectory("template"))
		{
			var args = [];
			var content = sys.io.File.getContent("template/" + file);
			var name = file.split(".")[0];
			filters.set(name, true);

			var e = interpolate(content, args);

			var argExprs = [];
			// trace(args);
			for (arg in args)
			{
				argExprs.push({
					name:arg,
					opt:false,
					type:null,
					value:null
				});
			}
			allArgs.push(argExprs);

			var kind = FFun({
				params:[],
				args:argExprs,
				ret:null,
				expr:macro return $e
			});

			fields.push({
				pos:pos,
				name:name,
				kind:kind,
				doc:null,
				access:[AStatic, APublic]
			});
		}

		for (argExprs in allArgs)
		{
			var len = argExprs.length;
			for (i in 0...len)
			{
				var x = len - (i + 1);
				if (filters.exists(argExprs[x].name))
				{
					argExprs.splice(x, 1);
				}
			}
			// trace(argExprs);
		}

		return fields;
	}

	static function interpolate(s:String, args:Array<String>)
	{
		var pos = Context.currentPos();
		var result = null;
		var ereg = ~/\$((\{.+?\})|[\w\d]+)/mis;

		while (ereg.match(s))
		{
			var left = ereg.matchedLeft();

			if (result == null)
			{
				if (left.length > 0) result = Context.makeExpr(left, pos);
				else result = Context.makeExpr("", pos);
			}
			else
			{
				var expr = Context.makeExpr(left, pos);
				result = {expr:EBinop(OpAdd, result, expr), pos:pos};	
			}

			var code = ereg.matched(1);
			var expr = Context.parse(code, pos);
			for (arg in getArgs(expr)) if (!args.has(arg)) args.push(arg);
			result = {expr:EBinop(OpAdd, result, expr), pos:pos};

			s = ereg.matchedRight();
		}

		if (result == null)
		{
			return Context.makeExpr(s, pos);
		}
		else if (s.length > 0)
		{
			var expr = Context.makeExpr(s, pos);
			result = {expr:EBinop(OpAdd, result, expr), pos:pos};
		}

		return result;
	}

	static function getArgs(expr:Expr, ?args:Map<String,Bool>, ?ignore:Map<String,Bool>):Array<String>
	{
		if (args == null) args = new Map<String, Bool>();
		if (ignore == null) ignore = new Map<String, Bool>();

		switch (expr.expr)
		{
			case EVars(vars): for (v in vars) ignore.set(v.name, true);
			case EConst(CIdent(i)): if (!ignore.exists(i)) args.set(i, true);
			default:	
				haxe.macro.ExprTools.iter(expr, getArgs.bind(_, args, ignore));
			// default:
		}

		return [for (key in args.keys()) key];
	}
}
