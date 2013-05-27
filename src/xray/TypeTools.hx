package xray;

import haxe.macro.Type;

class TypeTools
{
	public static function toBaseType(type:Type):Null<BaseType>
	{
		if (type == null) return null;
		return switch (type)
		{
			case TType(t, _): t.get();
			case TInst(t, _): t.get();
			case TEnum(t, _): t.get();
			case TAbstract(t, _): t.get();
			case TLazy(f): toBaseType(f());
			case _: null;
		}
	}

	public static function isBaseType(type:Type):Bool
	{
		return toBaseType(type) != null;
	}

	public static function isPublic(type:Type):Bool
	{
		return !isPrivate(type);
	}

	public static function isPrivate(type:Type):Bool
	{
		var base = toBaseType(type);
		return base == null ? false : base.isPrivate;
	}

	public static function getPath(type:Type):Array<String>
	{
		var base = toBaseType(type);
		if (base == null) return null;
		return base.pack.concat([base.name]);
	}

	public static function getName(type:Type):String
	{
		var path = getPath(type);
		if (path == null) return null;

		return path.join(".");
	}
}
