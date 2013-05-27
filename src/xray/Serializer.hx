package xray;

import haxe.macro.Type;
import xray.Data;
import haxe.macro.Expr;

class Serializer extends haxe.Serializer
{
	var ignores:Map<String, Bool>;
	var refs:Map<String, Bool>;

	public function new()
	{
		super();

		ignores = new Map();
		refs = new Map();

		for (field in ["__t", "__string", "exclude", "init", "expr"])
			ignores.set(field, true);
	}
	var lastField:String;
	override function serializeFields(v)
	{
		for (f in Reflect.fields(v))
		{
			if (ignores.exists(f)) continue;
			
			var val:Dynamic = Reflect.field(v,f);
			if (f == "pos" && !Reflect.hasField(val, "file"))
				val = haxe.macro.Context.getPosInfos(val);
			if (f == "meta")
				val = new MetaData(val.has(":impl"));
			/*
			if (f == "type" && val != null)
			{
				var type:Type = cast val;
				val = switch (type)
				{
					// case TType(_,_): null;
					// case TMono(_): null;
					// case TLazy(_): null;
					// case TInst(_,_): null;
					// case TFun(_,_): null;
					// case TEnum(_,_): null;
					// case TDynamic(_): null;
					case TAnonymous(a):
						var t = a.get();
						for (field in t.fields)
						{
							if (field.name == "meta")
							{
								field.type = switch (field.type)
								{
									case TType(t, params):
										var c = t.get();
										if (c.pack[1] == "macro")
										{
											c.type = null;
											TType(cast new RefData(c), params);
										}
										else TType(t, params);
									case t: t;
								}
								Sys.println(field.type);
							}
							field.type = switch (field.name)
							{
								case
"constructs",
"binops",
"from",
// "meta",
"module",
"params",
"to",
"type",
"unops",
"kind"
									: null;
								case _: field.type;
							}
							
							// if (field.name == "name") field.type = null;
							// if (field.name == "opt") field.type = null;
							// if (field.name == "type") field.type = null;
							// if (field.name == "value") field.type = null;

							// if (field.name != "value") field.type = null;
						}
						Type.TAnonymous(new RefData(t));
					// case TAbstract(_,_): null;
						
					case t: t;
				}
			}
			*/
			serializeString(f);
			serialize(val);
		}
		buf.add("g");
	}

	override function serialize(v:Dynamic)
	{
		if (Reflect.hasField(v, "get")) v = getRef(v);
		if (Std.is(v, ComplexType)) return;
		super.serialize(v);
	}

	function getRef(v:Dynamic):Dynamic
	{
		v = v.get();

		if (Reflect.hasField(v, "type")) Reflect.deleteField(v, "type");

		if (Reflect.hasField(v, "pack") && Reflect.hasField(v, "name"))
		{
			var key = v.pack.concat([v.name]).join(".");
			// trace(key);
			if (refs.exists(key)) v = key;
			else refs.set(key, true);
		}

		return new RefData(v);
	}
}
