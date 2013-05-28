package xray;

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import xray.Data;
using Lambda;

class Processor
{
	public var cache:Map<String, Dynamic>;

	public function new()
	{
		cache = new Map<String, Dynamic>();
	}

	public function process(types:Array<Type>)
	{
		return {types:types.map(processType), cache:cache};
	}

	function processType(type:Type):Type
	{
		if (type == null) return null;

		return switch (type)
		{
			case TType(t, params):

				t = RefData.of(processDefType(t.get()));
				params = params.map(processType);
				TType(t, params);

			case TInst(t, params):
				t = RefData.of(processClassType(t.get()));
				params = params.map(processType);
				TInst(t, params);

			case TEnum(t, params):
				t = RefData.of(processEnumType(t.get()));
				params = params.map(processType);
				TEnum(t, params);

			case TAbstract(t, params):
				t = RefData.of(processAbstractType(t.get()));
				params = params.map(processType);
				TAbstract(t, params);

			case TFun(args, ret):
				args = args.map(processArg);
				ret = processType(ret);
				TFun(args, ret);

			case TDynamic(t):
				t = processType(t);
				TDynamic(t);

			case TAnonymous(a):
				a = RefData.of(processAnonType(a.get()));
				TAnonymous(a);

			case TMono(t):
				t = RefData.of(processType(t.get()));
				TMono(t);

			case type:
				throw "Unhandled " + type;
				type;
		}
	}

	function getBaseType(type:BaseType):Dynamic
	{
		var key = type.module + ":" + type.pack.concat([type.name]).join(".");
		if (cache.exists(key)) return new PathData(key);
		cache.set(key, type);
		
		// untyped type._cached = key;
		type.pos = processPos(type.pos);
		type.params = type.params.map(processParam);
		type.meta = processMeta(type.meta);

		return null;
	}

	function processDefType(type:DefType)
	{
		var cached = getBaseType(type);
		if (cached != null) return cached;

		type.type = processType(type.type);

		return getBaseType(type);
	}

	function processClassType(type:ClassType)
	{
		var cached = getBaseType(type);
		if (cached != null) return cached;

		// relations
		type.superClass = processClassRef(type.superClass);
		type.interfaces = type.interfaces.map(processClassRef);

		// fields
		type.fields = RefData.of(type.fields.get().map(processClassField));
		type.statics = RefData.of(type.statics.get().map(processClassField));
		if (type.constructor != null)
			type.constructor = RefData.of(processClassField(type.constructor.get()));

		type.kind = switch (type.kind)
		{
			case KTypeParameter(constraints):
				constraints = constraints.map(processType);
				KTypeParameter(constraints);

			case KGenericInstance(cl, params):
				cl = RefData.of(processClassType(cl.get()));
				params = params.map(processType);
				KGenericInstance(cl, params);
			
			case KExtension(cl, params):
				cl = RefData.of(processClassType(cl.get()));
				params = params.map(processType);
				KExtension(cl, params);

			case KAbstractImpl(a):
				a = RefData.of(processAbstractType(a.get()));
				KAbstractImpl(a);

			case kind: kind;
		}

		return getBaseType(type);
	}

	function processEnumType(type:EnumType)
	{
		var cached = getBaseType(type);
		if (cached != null) return cached;

		for (field in type.constructs)
		{
			field.type = processType(field.type);
			field.pos = processPos(field.pos);
			field.params = field.params.map(processParam);
			field.meta = processMeta(field.meta);
		}

		return getBaseType(type);
	}

	function processAbstractType(type:AbstractType)
	{
		var cached = getBaseType(type);
		if (cached != null) return cached;

		type.type = processType(type.type);
		if (type.impl != null)
			type.impl = RefData.of(processClassType(type.impl.get()));

		type.binops.iter(processAbstractOp);
		type.unops.iter(processAbstractOp);
		type.from.iter(processAbstractField);
		type.to.iter(processAbstractField);
		type.array = type.array.map(processClassField);

		return getBaseType(type);
	}

	function processAbstractOp(field:{field:ClassField}):Void
	{
		field.field = processClassField(field.field);
	}

	function processAbstractField(field:{t:Type, field:Null<ClassField>}):Void
	{
		field.t = processType(field.t);
		field.field = processClassField(field.field);
	}

	function processAnonType(type:AnonType)
	{
		type.fields = type.fields.map(processClassField);
		return type;
	}

	function processClassRef(ref:{t:Ref<ClassType>, params:Array<Type>})
	{
		if (ref == null) return null;
		ref.t = RefData.of(processClassType(ref.t.get()));
		ref.params = ref.params.map(processType);
		return ref;
	}

	function processParam(param:{t:Type, name:String})
	{
		param.t = processType(param.t);
		return param;
	}

	function processClassField(field:ClassField)
	{
		if (field == null) return null;
		field.type = processType(field.type);
		field.params = field.params.map(processParam);
		field.meta = processMeta(field.meta);
		field.pos = processPos(field.pos);
		return field;
	}

	function processArg(arg:{t:Type, opt:Bool, name:String})
	{
		arg.t = processType(arg.t);
		return arg;
	}

	function processPos(pos:Position):Position
	{
		return cast Context.getPosInfos(pos);
	}

	function processMeta(meta:MetaAccess):MetaAccess
	{
		return cast new MetaData(meta.has(":impl"));
	}
}
