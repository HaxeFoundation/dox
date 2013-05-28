package xray;

import haxe.macro.Type;
import xray.Data;
import haxe.macro.Expr;
import haxe.macro.Context;
using Lambda;

class Serializer extends haxe.Serializer
{
	var ignores:Map<String, Bool>;
	var refs:Map<String, Bool>;

	public function new()
	{
		super();

		processed = [];
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
			if (f == "type") val = processType(val, 0);

			serializeString(f);
			serialize(val);
		}
		buf.add("g");
	}

	override function serialize(v:Dynamic)
	{
		if (Reflect.hasField(v, "get")) v = getRef(v);
		super.serialize(v);
	}

	function getRef(v:Dynamic):Dynamic
	{
		v = v.get();

		if (Reflect.hasField(v, "pack") && Reflect.hasField(v, "name"))
		{
			var key = v.pack.concat([v.name]).join(".");
			// trace(key);
			if (refs.exists(key)) v = key;
			else refs.set(key, true);
		}

		return new RefData(v);
	}




	static var processed:Array<Dynamic>;

	static function processType(type:Type, depth:Int)
	{
		if (type == null) return null;

		var ref = {
			superClass:null,
			statics:[],
			pos:Context.currentPos(),
			params:[],
			pack:["foo","bar"],
			name:"Baz",
			module:"foo.bar.Baz",
			meta:new MetaData(false),
			kind:KNormal,
			isPrivate:false,
			isInterface:false,
			isExtern:false,
			interfaces:[],
			init:null,
			fields:[],
			exclude:null,
			doc:null,
			constructor:null
		};
		return TInst(cast RefData.of(ref), []);
		if (depth > 2)
		{
			// trace("can't go deeper!");
			return null;
		}

		return switch (type)
		{
			case TType(t, params):
				var ref = t.get();
				ref.type = processType(ref.type, depth+1);
				for (i in 0...params.length)
					params[i] = processType(params[i], depth+1);
				for (param in ref.params)
					param.t = processType(param.t, depth+1);
				TType(RefData.of(ref), params);
				// null;

			case TInst(t, params):
				// var ref = t.get();
				type;
				// null;

			case TEnum(t, params):
				var ref = t.get();
				for (i in 0...params.length)
					params[i] = processType(params[i], depth+1);
				for (param in ref.params)
						param.t = processType(param.t, depth+1);
				var c = ref.constructs;
				for (construct in ref.constructs)
				{
					if (processed.has(construct.type)) continue;
					construct.type = processType(construct.type, depth+1);
					processed.push(construct.type);

					for (param in construct.params)
						param.t = processType(param.t, depth+1);
				}
				TEnum(RefData.of(ref), params);
				null;

			case TAbstract(t, params):
				var ref = t.get();
				ref.type = processType(ref.type, depth+1);
				ref.impl = null;
				ref.binops = [];
				ref.unops = [];
				ref.from = [];
				ref.to = [];
				ref.array = [];
				for (i in 0...params.length)
					params[i] = processType(params[i], depth+1);
				TAbstract(RefData.of(ref), params);

			case TAnonymous(t):
				var ref = t.get();
				for (field in ref.fields)
				{
					field.type = processType(field.type, depth+1);
					for (param in field.params)
						param.t = processType(param.t, depth+1);
				}
				Type.TAnonymous(RefData.of(ref));
				null;

			case TFun(args, ret):
				for (arg in args) arg.t = processType(arg.t, depth+1);
				ret = processType(ret, depth+1);
				TFun(args, ret);

			case TDynamic(t):
				null;

			case TMono(t):
				null;

			case TLazy(t):
				null;
		}
	}
}
