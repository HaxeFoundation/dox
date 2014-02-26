package dox;
import haxe.rtti.CType;

class Infos {
	
	public var typeMap:Map<String, TypeInfos>;
	public var subClasses:Map<String, Array<TypeInfos>>;
	public var implementors:Map<String, Array<TypeInfos>>;
	public var numGeneratedTypes(default, set):Int;
	public var numGeneratedPackages:Int;
	
	var packages:Map<String, Map<String, String>>;
	var names:Map<String, String>;

	var numProcessedTypes:Int;
	
	function set_numGeneratedTypes(v) {
		if (v & 16 == 0) Sys.print(".");
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
	
	public function resolveType(path:String, type:String)
	{
		// direct match
		if (typeMap.exists(type)) return type;

		// same package
		var parts = path.split('.');
		parts.pop();
		var pack = parts.join('.');
		if (packages.exists(pack))
		{
			var types = packages.get(pack);
			if (types.exists(type)) return types.get(type);
		}

		// last ditch attempt, by name (first match wins)
		if (names.exists(type))
		{
			return names.get(type);
		}

		return null;
	}

	public function addType(path:String, typeInfos:TypeInfos) {
		var parts = path.split('.');
		var name = parts.pop();
		var pack = parts.join('.');
		
		if (packages.exists(pack)) packages.get(pack).set(name, path);
		else packages.set(pack, [name => path]);

		if (!names.exists(name)) names.set(name, path);

		typeMap.set(path, typeInfos);
		numProcessedTypes++;
		if (numProcessedTypes & 16 == 0) Sys.print(".");
	}
}
