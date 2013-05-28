package xray;

import xray.Data;
import haxe.macro.Type;

class Unserializer extends haxe.Unserializer
{
	var paths:Array<{o:Dynamic, k:String, v:PathData}>;

	public function new(buf:String)
	{
		super(buf);
		paths = [];
	}

	public function getTypes():Array<Type>
	{
		var model = unserialize();
		var cache:Map<String, Dynamic> = model.cache;

		for (path in paths)
		{
			Reflect.setField(path.o, path.k, cache.get(path.v._key));
		}

		return model.types;
	}

	override function unserializeObject(o)
	{
		while( true ) {
			if( pos >= length )
				throw "Invalid object";
			if( get(pos) == "g".code )
				break;
			var k = unserialize();
			if( !Std.is(k,String) )
				throw "Invalid object key";
			var v = unserialize();

			if (Std.is(v, PathData))
			{
				paths.push({o:o,k:k,v:v});
			}

			Reflect.setField(o,k,v);
		}
		pos++;
	}
}