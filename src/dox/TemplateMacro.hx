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

		for (file in sys.FileSystem.readDirectory("template"))
		{
			var args = [];
			var content = sys.io.File.getContent("template/" + file);
			var name = file.split(".")[0];
			var e = interpolate(content, args);

			var argExprs = [];
			for (arg in args)
			{
				argExprs.push({
					name:arg,
					opt:false,
					type:null,
					value:null
				});
			}

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

		return fields;
	}

	static function interpolate(s:String, args:Array<String>)
	{
		var pos = Context.currentPos();
		var result = null;
		var ereg = ~/\$\{?(\w+)\}?/;

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
			if (!args.has(code)) args.push(code);
			var expr = Context.parse(code, pos);
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
}