package dox;
import haxe.rtti.CType;

class Infos {
	
	public var typeMap:Map<String, TypeInfos>;
	public var subClasses:Map<String, Array<TypeInfos>>;
	public var implementors:Map<String, Array<TypeInfos>>;
	public var numGeneratedTypes(default, set):Int;
	public var numGeneratedPackages:Int;
	
	var numProcessedTypes:Int;
	
	function set_numGeneratedTypes(v) {
		if (v & 16 == 0) Sys.print(".");
		return numGeneratedTypes = v;
	}
	
	public function new() {
		typeMap = new Map();
		subClasses = new Map();
		implementors = new Map();
		numGeneratedPackages = 0;
		numProcessedTypes = 0;
		Reflect.setField(this, "numGeneratedTypes", 0);
	}
	
	public function addType(path:String, typeInfos:TypeInfos) {
		typeMap.set(path, typeInfos);
		numProcessedTypes++;
		if (numProcessedTypes & 16 == 0) Sys.print(".");
	}
}