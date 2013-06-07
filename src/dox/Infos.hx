package dox;
import haxe.rtti.CType;

class Infos {
	
	public var typeMap:Map<String, TypeInfos>;
	public var subClasses:Map<String, Array<String>>;
	public var implementors:Map<String, Array<String>>;
	public var numGeneratedTypes(default, set):Int;
	public var numGeneratedPackages:Int;
	
	function set_numGeneratedTypes(v) {
		if (v & 16 == 0) Sys.print(".");
		return numGeneratedTypes = v;
	}
	
	public function new() {
		typeMap = new Map();
		subClasses = new Map();
		implementors = new Map();
		numGeneratedPackages = 0;
		Reflect.setField(this, "numGeneratedTypes", 0);
	}
	
}