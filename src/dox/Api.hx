package dox;

import haxe.rtti.CType;

class Api {
	public var config:Config;
	public var infos:Infos;
	
	public function new(cfg:Config, infos:Infos) {
		this.config = cfg;
		this.infos = infos;
	}
	
	public function getTreeName(tree:TypeTree) {
		return switch(tree) {
			case TPackage(name,_,_): name;
			case TClassdecl(t): getPathName(t.path);
			case TEnumdecl(t): getPathName(t.path);
			case TTypedecl(t): getPathName(t.path);
			case TAbstractdecl(t): getPathName(t.path);
		}
	}
	
	public function getTreeUrl(tree:TypeTree) {
		return switch(tree) {
			case TPackage(_, full, _): config.rootPath + full.split(".").join("/") + "/index.html";
			case TClassdecl(t): pathToUrl(t.path);
			case TEnumdecl(t): pathToUrl(t.path);
			case TTypedecl(t): pathToUrl(t.path);
			case TAbstractdecl(t): pathToUrl(t.path);
		}
	}
	
	public function pathToUrl(path:Path) {
		return config.rootPath + path.split(".").join("/") + ".html";
	}
	
	public function isKnownType(path:Path) {
		return infos.typeMap.exists(path);
	}
	
	public function getTypePath(ctype:CType) {
		return switch (ctype) {
			case CClass(path,_): path;
			case CEnum(path, _): path;
			case CTypedef(path, _): path;
			case CAbstract(path, _): path;
			case _: null;
		}
	}
	
	public function getPathName(path:Path) {
		return path.split(".").pop();
	}
	
	public function debug(e:Dynamic) {
		trace(Std.string(e));
	}
}