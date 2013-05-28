package xray;

// import haxe.macro.Type;
import xray.Data;
import haxe.macro.Expr;
import haxe.macro.Context;
using Lambda;

class Serializer extends haxe.Serializer
{
	var ignores:Map<String, Bool>;
	var types:Map<String, Dynamic>;

	public function new()
	{
		super();

		// useCache = true;
		useEnumIndex = true;
		ignores = new Map();
		types = new Map<String, Dynamic>();

		for (field in ["$", "__t", "__string", "exclude", "init", "expr"])
			ignores.set(field, true);
	}

	override function serializeFields(v)
	{
		for (f in Reflect.fields(v))
		{
			if (ignores.exists(f)) continue;
			
			var val:Dynamic = Reflect.field(v,f);
			serializeString(f);
			serialize(val);
		}
		buf.add("g");
	}
}
