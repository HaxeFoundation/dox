package xray;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
using Lambda;
using xray.Tools;

class Inspector
{
	var sources:Map<String, String>; // file -> source

	public function new()
	{
		sources = new Map();
	}

	public function process(types:Array<Type>)
	{
		types.iter(processType);
	}

	function processType(type:Type)
	{
		if (type == null) return;

		switch (type)
		{
			case TType(t, _): processDefType(t.get());
			case TMono(t): processType(t.get());
			case TLazy(f): processType(f());
			case TInst(t, _): processClassType(t.get());
			case TFun(args, ret): processFun(args, ret);
			case TEnum(t, _): processEnumType(t.get());
			case TDynamic(t): processType(t);
			case TAnonymous(t): processAnonType(t.get());
			case TAbstract(t, _): processAbstractType(t.get());
		}
	}

	function processBaseType(type:BaseType)
	{
		var id = type.pack.concat([type.name]).join(".");
		var pos = getPos(type.pos);
	}

	function processDefType(type:DefType)
	{
		return;
		processBaseType(type);
		processType(type.type);
	}

	function processClassType(type:ClassType)
	{
		if (type.name != "Http") return;
		processBaseType(type);
		processTypedExpr(type.init);
		if (type.constructor != null) processClassField(type.constructor.get());
		type.statics.get().iter(processClassField);
		type.fields.get().iter(processClassField);
	}

	function processEnumType(type:EnumType)
	{
		return;
		processBaseType(type);
	}

	function processAbstractType(type:AbstractType)
	{
		return;
		processBaseType(type);
	}

	function processAnonType(type:AnonType)
	{
		return;
		type.fields.iter(processClassField);
	}

	function processClassField(field:ClassField)
	{
		var id = field.name;
		if (id != "new") return;
		var pos = getPos(field.pos);
		processTypedExpr(field.expr());
	}

	function processFun(args:Array<{ t : Type, opt : Bool, name : String }>, ret:Type)
	{

	}

	function processTypedExpr(expr:TypedExpr)
	{
		if (expr == null) return;
		processExpr(Context.getTypedExpr(expr));
	}

	function processExpr(expr:Expr)
	{
		trace(getPosSource(expr.pos));
		try
		{
			var type = Context.typeof(expr);
			trace(type);
		}
		catch (e:Dynamic) {}

		// Sys.println(getPos(expr.pos));
		haxe.macro.ExprTools.iter(expr, processExpr);
	}

	function getPos(pos:Position):String
	{
		var info = Context.getPosInfos(pos);
		return info.min + ":" + info.max;
	}

	function getPosSource(pos:Position):String
	{
		var infos = Context.getPosInfos(pos);
		var source = getSource(infos.file);
		return source.substring(infos.min, infos.max);
	}


	function getSource(file:String):String
	{
		if (sources.exists(file)) return sources.get(file);
		var source = sys.io.File.getContent(file);
		sources.set(file, source);
		return source;
	}
}
