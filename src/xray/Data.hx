package xray;

class RefData
{
	public var _ref:Dynamic;

	public function new(t:Dynamic)
	{
		_ref = t;
	}

	public function get()
	{
		return _ref;
	}

	public function toString()
	{
		return null;
	}
}

class MetaData
{
	var impl:Bool;

	public function new(impl:Bool)
	{
		this.impl = impl;
	}

	public function has(name:String):Bool
	{
		return impl && name == ":impl";
	}
}