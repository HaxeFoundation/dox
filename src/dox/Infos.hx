package dox;

import haxe.rtti.CType;

using Lambda;

/**
	Infos is a collection of information collected by Dox during processing.

	An instance can be accessed as `api.infos` in templates.
**/
class Infos {
	/**
		A map of dot-paths to their corresponding `TypeInfos` objects.
	**/
	public var typeMap:Map<String, TypeInfos>;

	/**
		A map of dot-path classes to their sub classes.
	**/
	public var subClasses:Map<String, Array<TypeInfos>>;

	/**
		A map of dot-path interfaces to their implementors.
	**/
	public var implementors:Map<String, Array<TypeInfos>>;

	/**
		The number of generated types.
	**/
	public var numGeneratedTypes(default, set):Int;

	/**
		The number of generated packages.
	**/
	public var numGeneratedPackages:Int;

	var packages:Map<String, Map<String, String>>;
	var names:Map<String, String>;
	var numProcessedTypes:Int;

	function set_numGeneratedTypes(v) {
		if (v & 16 == 0)
			Sys.print(".");
		return numGeneratedTypes = v;
	}

	public function new() {
		typeMap = new Map();
		subClasses = new Map();
		implementors = new Map();
		packages = new Map();
		names = new Map();
		numGeneratedPackages = 0;
		numProcessedTypes = 0;
		Reflect.setField(this, "numGeneratedTypes", 0);
	}

	/**
		Checks if `meta` contains a `@:dox` metadata.

		If `parameterName` is not null, also checks if `@:dox` has an argument
		equal to `parameterName`.
	**/
	static public function hasDoxMetadata(meta:MetaData, ?parameterName:String):Bool {
		return meta.exists(function(m) return m.name == ":dox" && parameterName == null || m.params.has(parameterName));
	}

	function resolveType(path:String, type:String) {
		// direct match
		if (typeMap.exists(type))
			return type;

		// same package
		var parts = path.split('.');
		parts.pop();
		var pack = parts.join('.');
		if (packages.exists(pack)) {
			var types = packages.get(pack);
			if (types.exists(type))
				return types.get(type);
		}

		// last ditch attempt, by name (first match wins)
		if (names.exists(type)) {
			return names.get(type);
		}

		return null;
	}

	@:allow(dox.Processor)
	function addType(path:String, typeInfos:TypeInfos) {
		var parts = path.split('.');
		var name = parts.pop();
		var pack = parts.join('.');

		if (packages.exists(pack))
			packages.get(pack).set(name, path);
		else
			packages.set(pack, [name => path]);

		if (!names.exists(name))
			names.set(name, path);

		typeMap.set(path, typeInfos);
		numProcessedTypes++;
		if (numProcessedTypes & 16 == 0)
			Sys.print(".");
	}
}
