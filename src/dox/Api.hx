package dox;

import haxe.rtti.CType;
using Lambda;
using StringTools;

/**
	The Api class is the general interface to the Dox system which can be
	accessed in templates from the global `api` instance.
**/
@:keep
class Api {

	/**
		The Dox configuration, see `Config` for details.
	**/
	public var config:Config;

	/**
		This instance of `Infos` contains various information which is collected
		by the Dox processor.
	**/
	public var infos:Infos;

	/**
		The current page name. For types this is the type name, for packages it
		is `"package "` followed by the package name.
	**/
	public var currentPageName:String;

	public function new(cfg:Config, infos:Infos) {
		this.config = cfg;
		this.infos = infos;
	}

	/**
		Checks if `name` is a known platform name.

		Platform names correspond to the filenames of the consumed .xml files.
		For instance, flash.xml defines target "flash".
	**/
	public function isPlatform(name:String):Bool
	{
		return config.platforms.has(name);
	}

	/**
		Returns the name of `tree`, which is the unqualified name of the
		package of type represented by `tree`.
	**/
	public function getTreeName(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(name,_,_): name;
			case TClassdecl(t): getPathName(t.path);
			case TEnumdecl(t): getPathName(t.path);
			case TTypedecl(t): getPathName(t.path);
			case TAbstractdecl(t): getPathName(t.path);
		}
	}

	/**
		Returns the full dot-path of `tree`.
	**/
	public function getTreePath(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(_,path,_): path;
			case TClassdecl(t): t.path;
			case TEnumdecl(t): t.path;
			case TTypedecl(t): t.path;
			case TAbstractdecl(t): t.path;
		}
	}

	/**
		Returns the package of `tree`, which is the dot-path without the type
		name for types and the package itself for packages.
	**/
	public function getTreePack(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(_,pack,_): pack;
			case TClassdecl(t): getPathPack(t.path);
			case TEnumdecl(t): getPathPack(t.path);
			case TTypedecl(t): getPathPack(t.path);
			case TAbstractdecl(t): getPathPack(t.path);
		}
	}

	/**
		Returns the URL of `tree`, following the conventions of Dox.

		For packages, the returned value is the slash-path of the package
		followed by "/index.html".

		For types, `pathToUrl` is called with the type path.
	**/
	public function getTreeUrl(tree:TypeTree):String {
		return switch(tree) {
			case TPackage(_, full, _): config.rootPath + full.split(".").join("/") + "/index.html";
			case TClassdecl(t): pathToUrl(t.path);
			case TEnumdecl(t): pathToUrl(t.path);
			case TTypedecl(t): pathToUrl(t.path);
			case TAbstractdecl(t): pathToUrl(t.path);
		}
	}

	/**
		Returns the short description of `tree`.

		@todo: Document this properly.
	**/
	public function getTreeShortDesc(tree:TypeTree):String {
		var infos:TypeInfos = switch(tree) {
			case TPackage(_, full, _): null;
			case TClassdecl(t): t;
			case TEnumdecl(t): t;
			case TTypedecl(t): t;
			case TAbstractdecl(t): t;
		}
		return getShortDesc(infos);
	}

	/**
		Returns the short description of `infos`.

		@todo: Document this properly.
	**/
	public function getShortDesc(infos:TypeInfos):String {
		return infos == null ? "" : infos.doc.substr(0, infos.doc.indexOf('</p>') + 4);
	}

	/**
		Returns the first sentence of the documentation belonging to `infos`.
	**/
	public function getSentenceDesc(infos:TypeInfos):String {
		if (infos == null) {
			return "";
		}
		var stripped = ~/<.+?>/.replace(infos.doc, "").replace("\n", " ");
		var sentence = ~/^(.*?[.?!]+)/;
		return sentence.match(stripped) ? sentence.matched(1) : "";
	}

	/**
		Turns a dot-path into a slash-path and appends ".html".
	**/
	public function pathToUrl(path:Path):String {
		return config.rootPath + path.split(".").join("/") + ".html";
	}

	/**
		Checks if `path` corresponds to a known type.
	**/
	public function isKnownType(path:Path):Bool {
		return infos.typeMap.exists(path);
	}

	/**
		Resolves a type by its dot-path `path`.
	**/
	public function resolveType(path:Path):Null<TypeInfos> {
		return infos.typeMap.get(path);
	}

	/**
		Returns the dot-path of type `ctype`.

		If `ctype` does not have a real path, `null` is returned.
	**/
	public function getTypePath(ctype:CType):Null<String> {
		return switch (ctype) {
			case CClass(path,_): path;
			case CEnum(path, _): path;
			case CTypedef(path, _): path;
			case CAbstract(path, _): path;
			case _: null;
		}
	}

	/**
		Returns the last part of dot-path `path`.
	**/
	public function getPathName(path:Path):String {
		return path.split(".").pop();
	}

	/**
		Returns the package part of dot-path `path`.

		If `path` does not have a package, the empty string `""` is returned.
	**/
	public function getPathPack(path:Path):String {
		var parts = path.split(".");
		parts.pop();
		return parts.length == 0 ? "" : parts.join(".") + ".";
	}

	/**
		Traces `e` for debug purposes.
	**/
	public function debug(e:Dynamic):Void {
		trace(Std.string(e));
	}

	/**
		Checks if `field` is an abstract implementation field.

		Abstract implementation fields are abstract fields which are not static
		in the original definition.
	**/
	public function isAbstractImplementationField(field:ClassField):Bool {
		return field.meta.exists(function(m) return m.name == ":impl");
	}

	/**
		Returns the CSS class string corresponding to `platforms`. If
		`platforms is empty, `null` is returned.
	**/
	public function getPlatformClassString(platforms:List<String>):String {
		if (platforms.isEmpty()) return null;
		return "platform " + platforms.map(function(p){ return "platform-"+p; }).join(" ");
	}

	/**
		Checks if `key` was defined from command line argument `-D key value`.
	**/
	public function isDefined(key:String):Bool {
		return config.defines.exists(key);
	}

	/**
		Returns the value of `key` as defined by command line argument
		`-D key value`. If no value is defined, null is returned.
	**/
	public function getValue(key:String):Null<String> {
		return config.defines[key];
	}

	/**
		Returns the path to the source code of `type`. This method assumes that
		`source-path` was defined from command line (`-D source-path url`) and
		then appends the path of `type` to it.
	**/
	public function getSourceLink(type:TypeInfos) {
		var module = type.module != null ? type.module : type.path;
		return haxe.io.Path.join([getValue("source-path"), module.replace(".", "/") + ".hx"]);
	}
}
