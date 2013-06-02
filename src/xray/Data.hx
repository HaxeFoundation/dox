package xray;

using haxe.macro.Tools;
import haxe.macro.Context;
import haxe.macro.Expr;
using Lambda;

class RefData<T>
{
	public static function of<T>(ref:T):RefData<T>
	{
		return new RefData(ref);
	}

	public var _ref:T;

	public function new(ref:T)
	{
		_ref = ref;
	}

	public function get():T
	{
		return _ref;
	}

	public function toString():String
	{
		return null;
	}
}

class MetaData
{
	var _meta:Array<{name: String, params:Array<String>, pos: Position}>;
	
	public function new(meta:Metadata)
	{
		_meta = meta.map(function(m) return { name: new String(untyped m.name.__s), params: m.params.map(function(e) return e.toString()), pos: null});
	}

	public function has(name:String):Bool
	{
		return _meta.exists(function(m) return m.name == name);
	}
	
	public function get():Metadata
	{
		return throw "niy";
	}
	
	public function add(name:String, params:Array<Expr>, pos:Position) {
		throw "niy";
	}
	
	public function remove(name:String) {
		throw "niy";
	}
}

class PathData
{
	public var _key:String;

	public function new(key:String)
	{
		_key = key;
	}
}
