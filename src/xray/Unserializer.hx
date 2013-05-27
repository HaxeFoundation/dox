package xray;

import xray.Data;

class Unserializer extends haxe.Unserializer
{
	var refs:Array<RefData>;
	var types:Map<String, Dynamic>;

	public function new(buf:String)
	{
		super(buf);
		refs = [];
		types = new Map<String, Dynamic>();
	}

	override public function unserialize()
	{
		var v:Dynamic = super.unserialize();

		if (Std.is(v, RefData)) refs.push(v);
		if (Reflect.hasField(v, "pack") && Reflect.hasField(v, "name"))
		{
			var id = v.pack.concat([v.name]).join(".");
			types.set(id, v);
		}

		return v;
	}

	public function updateRefs()
	{
		for (ref in refs)
		{
			if (Std.is(ref._ref, String))
			{
				if (types.exists(ref._ref))
				{
					ref._ref = types.get(ref._ref);
				}
				else
				{
					trace(ref._ref);
				}
			}
		}
	}
}