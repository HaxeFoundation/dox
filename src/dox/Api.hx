package dox;

import haxe.rtti.CType;
using Lambda;

@:keep class Api {
	public var config:Config;
	public var infos:Infos;
	
	public var currentPageName:String;
	public var currentFullName:String;
	
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

	public function getTreePath(tree:TypeTree) {
		return switch(tree) {
			case TPackage(_,path,_): path;
			case TClassdecl(t): t.path;
			case TEnumdecl(t): t.path;
			case TTypedecl(t): t.path;
			case TAbstractdecl(t): t.path;
		}
	}

	public function getTreePack(tree:TypeTree) {
		return switch(tree) {
			case TPackage(_,pack,_): pack;
			case TClassdecl(t): getPathPack(t.path);
			case TEnumdecl(t): getPathPack(t.path);
			case TTypedecl(t): getPathPack(t.path);
			case TAbstractdecl(t): getPathPack(t.path);
		}
	}
	
	public function getTreeUrl(tree:TypeTree) {
		return switch(tree) {
			case TPackage(_, full, _): config.rootPath + "/" + full.split(".").join("/") + "/index.html";
			case TClassdecl(t): pathToUrl(t.path);
			case TEnumdecl(t): pathToUrl(t.path);
			case TTypedecl(t): pathToUrl(t.path);
			case TAbstractdecl(t): pathToUrl(t.path);
		}
	}
	
	public function getTreeShortDesc(tree:TypeTree) {
		var infos:TypeInfos = switch(tree) {
			case TPackage(_, full, _): null;
			case TClassdecl(t): t;
			case TEnumdecl(t): t;
			case TTypedecl(t): t;
			case TAbstractdecl(t): t;
		}
		return getShortDesc(infos);
	}
	
	public function getShortDesc(infos:TypeInfos) {
		return infos == null ? "" : infos.doc.substr(0, infos.doc.indexOf('</p>') + 4);
	}
	
	public function pathToUrl(path:Path) {
		return config.rootPath + "/" + path.split(".").join("/") + ".html";
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

	public function getPathPack(path:Path) {
		var parts = path.split(".");
		parts.pop();
		return parts.length == 0 ? "" : parts.join(".") + ".";
	}
	
	public function debug(e:Dynamic) {
		trace(Std.string(e));
	}
	
	public function isAbstractImplementationField(field:ClassField) {
		return field.meta.exists(function(m) return m.name == ":impl");
	}
	
	public function getPlatformClassString(platforms:List<String>) {
		if (platforms.isEmpty()) return null;
		return "platform " + platforms.map(function(p){ return "platform-"+p; }).join(" ");
	}
}