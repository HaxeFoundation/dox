package xray;

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

class PathData
{
	public var _id:String;

	public function new(_id:String)
	{
		this._id = _id;
	}
}
