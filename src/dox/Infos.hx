package dox;
import haxe.rtti.CType;

class Infos {
	
	public var typeMap:Map<String, TypeInfos>;
	public var subClasses:Map<String, Array<String>>;
	public var implementors:Map<String, Array<String>>;
	
	public function new() {
		typeMap = new Map();
		subClasses = new Map();
		implementors = new Map();
	}
	
}