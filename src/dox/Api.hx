package dox;

import sys.io.File;
import haxe.Json;
import haxe.rtti.CType;

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
	public var currentPageName:Null<String>;

	/**
		The current page relative url.
	**/
	public var currentPageUrl:Null<String>;

	/**
		Expose Std for theme.
	**/
	public var std = Std;

	/**
		Expose Lambda for theme.
	**/
	public var lambda = Lambda;

	/**
		Information about compiler metadata by name.
	**/
	public var metas:Map<String, Dynamic>;

	public function new(cfg:Config, infos:Infos) {
		this.config = cfg;
		this.infos = infos;
		var metaJson = File.getContent(haxe.io.Path.join([cfg.doxPath, "resources/meta.json"]));
		var metas:Array<{metadata:String}> = Json.parse(metaJson);
		this.metas = [for (meta in metas) meta.metadata => meta];
	}

	/**
		Checks if `name` is a known platform name.

		Platform names correspond to the filenames of the consumed .xml files.
		For instance, flash.xml defines target "flash".
	**/
	public function isPlatform(name:String):Bool {
		return config.platforms.has(name);
	}

	/**
		Returns the name of `tree`, which is the unqualified name of the
		package of type represented by `tree`.
	**/
	public function getTreeName(tree:TypeTree):String {
		return switch (tree) {
			case TPackage(name, _, _): name;
			case TClassdecl(t): getPathName(t.path);
			case TEnumdecl(t): getPathName(t.path);
			case TTypedecl(t): getPathName(t.path);
			case TAbstractdecl(t): getPathName(t.path);
		}
	}

	/**
		Returns the type of `tree`.
	**/
	public function getTreeType(tree:TypeTree):String {
		return switch (tree) {
			case TPackage(_, _, _): "package";
			case TClassdecl(_): "class";
			case TEnumdecl(_): "enum";
			case TTypedecl(_): "type";
			case TAbstractdecl(_): "abstract";
		}
	}

	/**
		Returns the full dot-path of `tree`.
	**/
	public function getTreePath(tree:TypeTree):String {
		return switch (tree) {
			case TPackage(_, path, _): path;
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
		return switch (tree) {
			case TPackage(_, pack, _): pack;
			case TClassdecl(t): getPathPack(t.path);
			case TEnumdecl(t): getPathPack(t.path);
			case TTypedecl(t): getPathPack(t.path);
			case TAbstractdecl(t): getPathPack(t.path);
		}
	}

	/**
		Returns the URL of `tree`, following the conventions of Dox.

		For packages, the returned value is the slash-path of the package
		followed by `"/index.html"`.

		For types, `pathToUrl` is called with the type path.
	**/
	public function getTreeUrl(tree:TypeTree):String {
		return switch (tree) {
			case TPackage(_, full, _): packageToUrl(full);
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
		var infos:TypeInfos = switch (tree) {
			case TPackage(_, _, _): null;
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
		return (infos == null || infos.doc == null) ? "" : infos.doc.substr(0, infos.doc.indexOf('</p>') + 4);
	}

	/**
		Returns the first sentence of the documentation belonging to `infos` as well as its dot path.
	**/
	public function getSentenceDesc(infos:TypeInfos):String {
		var path = infos.path;
		if (infos == null || infos.doc == null) {
			return path;
		}
		var stripped = ~/<.+?>/g.replace(infos.doc, "").replace("\n", " ");
		var sentence = ~/^(.*?[.?!]+)/;
		return sentence.match(stripped) ? path + " - " + sentence.matched(1) : path;
	}

	public function getMetaDesc(meta:String):String {
		if (!metas.exists(meta)) {
			return "";
		}
		var doc = metas[meta].doc;
		return if (doc == null) "" else doc;
	}

	/**
		Turns a dot-path into a slash-path and appends ".html".
	**/
	public function pathToUrl(path:Path):String {
		return config.rootPath + sanitizePath(path).split(".").join("/") + ".html";
	}

	/**
		Turns a package-path into a slash-path and appends "/index.html".
	**/
	public function packageToUrl(full:String):String {
		if (full == config.toplevelPackage) {
			return config.rootPath + "index.html";
		}
		return config.rootPath + full.split(".").join("/") + "/index.html";
	}

	/**
		Checks if `t` corresponds to a core type.
	**/
	public function isCoreType(t:TypeInfos):Bool {
		return t.meta.exists(m -> m.name == ":coreType");
	}

	/**
		Checks if `t` corresponds to an enum abstract.
	**/
	public function isEnumAbstract(t:TypeInfos):Bool {
		return t.meta.exists(m -> m.name == ":enum");
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
			case CClass(path, _): path;
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
		var name = path.split(".").pop();
		return name == null ? "" : name;
	}

	/**
		Returns the package part of dot-path `path`.

		If `path` does not have a package, the empty string `""` is returned.
	**/
	public function getPathPack(path:Path):String {
		var parts = path.split(".");
		parts.pop();
		return parts.length == 0 ? "" : parts.join(".");
	}

	/**
		Traces `e` for debug purposes.
	**/
	public function debug(e:Dynamic):Void {
		trace(Std.string(e));
	}

	/**
		Traces `e` as pretty-printed Json for debug purposes.
	**/
	public function debugJson(e:Dynamic) {
		trace(Json.stringify(e, null, "  "));
	}

	/**
		Checks if `field` is an abstract implementation field.

		Abstract implementation fields are abstract fields which are not static
		in the original definition.
	**/
	public function isAbstractImplementationField(field:ClassField):Bool {
		return field.meta.exists(m -> m.name == ":impl");
	}

	/**
		Returns the CSS class string corresponding to `platforms`. If
		`platforms` is empty, `null` is returned.
	**/
	public function getPlatformClassString(platforms:List<String>):Null<String> {
		if (platforms.isEmpty())
			return null;
		return "platform " + platforms.map(p -> "platform-" + p).join(" ");
	}

	/**
		Checks if `key` was defined from command line argument `-D key value`.
	**/
	public function isDefined(key:String):Bool {
		return config.defines.exists(key);
	}

	/**
		Returns the value of `key` as defined by command line argument
		`-D key value`. If no value is defined, `null` is returned.
	**/
	public function getValue(key:String):Null<String> {
		return config.defines[key];
	}

	/**
		Returns the path to the source code of `type`. This method assumes that
		`source-path` was defined from command line (`-D source-path url`) and
		then appends the path of `type` to it.
	**/
	public function getSourceLink(type:TypeInfos):Null<String> {
		var sourcePath = getValue("source-path");
		if (sourcePath == null) {
			return null;
		}
		var module = type.module != null ? type.module : type.path;
		return haxe.io.Path.join([sourcePath, module.replace(".", "/") + ".hx"]);
	}

	/**
		Whether the "View Source" button should be shown.
	**/
	public function hasSourceLink(type:TypeInfos):Bool {
		return isDefined("source-path") && type.file != null && type.file.endsWith(".hx");
	}

	/**
		Returns additional field information which is not available on the
		`ClassField` type. See `FieldInfo` for more information.
	**/
	public function getFieldInfo(cf:ClassField):FieldInfo {
		var modifiers = {
			isInline: false,
			isDynamic: false,
			isOptional: false,
			isFinal: false
		}
		var isMethod = false;
		var get = "default";
		var set = "default";
		switch (cf.set) {
			case RNo:
				set = "null";
			case RCall(_):
				set = "set";
			case RMethod:
				isMethod = true;
			case RDynamic:
				set = "dynamic";
				isMethod = true;
				modifiers.isDynamic = true;
			default:
		}
		switch (cf.get) {
			case RNo:
				get = "null";
			case RCall(_):
				get = "get";
			case RDynamic:
				get = "dynamic";
			case RInline:
				modifiers.isInline = true;
			default:
		}
		modifiers.isOptional = cf.meta.exists(m -> m.name == ":optional");
		modifiers.isFinal = cf.isFinal;
		function varOrProperty() {
			return if (get == "default" && set == "default") {
				Variable;
			} else {
				Property(get, set);
			}
		}
		var kind = if (isMethod || modifiers.isInline) {
			switch (cf.type) {
				case CFunction(args, ret):
					Method(args, ret);
				default:
					varOrProperty();
			}
		} else {
			varOrProperty();
		}
		return {
			kind: kind,
			modifiers: modifiers
		}
	}

	/**
		Checks whether `cf` is a method using `getFieldInfo()`.
	**/
	public function isMethod(cf:ClassField) {
		return getFieldInfo(cf).kind.match(Method(_, _));
	}

	/**
		Returns an array of all member fields of `c` respecting the inheritance chain.
	**/
	public function getAllFields(c:Classdef):Array<MemberField> {
		var allFields = [];
		var fieldMap = new Map();
		function loop(c:Classdef) {
			for (cf in c.fields) {
				if (!fieldMap.exists(cf.name) || cf.overloads != null) {
					allFields.push({field: cf, definedBy: c});
					fieldMap[cf.name] = true;
				}
			}
			if (c.superClass != null) {
				var cSuper:Classdef = cast infos.typeMap[c.superClass.path];
				if (cSuper != null) { // class is not part of documentation
					loop(cSuper);
				}
			}
		}
		loop(c);
		if (!config.keepFieldOrder) {
			allFields.sort((f1, f2) -> Reflect.compare(f1.field.name, f2.field.name));
		}
		return allFields;
	}

	/**
		Returns inherited fields/methods of `c`. Sorted by field-name ordered by type in a map.
	**/
	public function getInheritedFields(c:Classdef):InheritedFields {
		var oc = c;

		var inheritedFields:InheritedFields = {
			methods: new Map<Classdef, Array<ClassField>>(),
			fields: new Map<Classdef, Array<ClassField>>(),
			types: [],
		}

		var allFields = [];
		var fieldMap = new Map();
		function loop(c:Classdef) {
			for (cf in c.fields) {
				if (!fieldMap.exists(cf.name) || cf.overloads != null) {
					if (c != oc)
						allFields.push({field: cf, definedBy: c});
					fieldMap[cf.name] = true;
				}
			}
			if (c.superClass != null) {
				var cSuper:Classdef = cast infos.typeMap[c.superClass.path];
				if (cSuper != null) { // class is not part of documentation
					inheritedFields.types.push(cSuper);
					inheritedFields.methods.set(cSuper, []);
					inheritedFields.fields.set(cSuper, []);
					loop(cSuper);
				}
			}
		}
		loop(c);

		function addFieldTo(f, map) {
			var fields = map.exists(f.definedBy) ? map.get(f.definedBy) : [];
			fields.push(f.field);
			map.set(f.definedBy, fields);
		}
		for (f in allFields) {
			if (isMethod(f.field))
				addFieldTo(f, inheritedFields.methods);
			else
				addFieldTo(f, inheritedFields.fields);
		}

		if (!config.keepFieldOrder) {
			for (fields in inheritedFields.methods) {
				fields.sort((f1, f2) -> Reflect.compare(f1.name, f2.name));
			}
			for (fields in inheritedFields.fields) {
				fields.sort((f1, f2) -> Reflect.compare(f1.name, f2.name));
			}
		}

		return inheritedFields;
	}

	private function sanitizePath(path:String) {
		return ~/Index$/.replace(path, "$$Index");
	}
}

/**
	Additional information on class fields
**/
typedef FieldInfo = {
	/**
		The kind of the field. See `FieldKind`.
	**/
	var kind:FieldKind;

	/**
		The field modifiers. See `FieldModifiers`.
	**/
	var modifiers:FieldModifiers;
}

/**
	Describes the kind of a class field.
**/
enum FieldKind {
	/**
		Field is a variable. Properties with `default, default` access are
		also considered variables.
	**/
	Variable;

	/**
		Field is a property. The arguments `get` and `set` correspond to the
		accessor.
	**/
	Property(get:String, set:String);

	/**
		Field is a method with arguments `args` and return type `ret`.
	**/
	Method(args:Array<FunctionArgument>, ret:CType);
}

/**
	The modifiers of a field.
**/
typedef FieldModifiers = {
	isInline:Bool,
	isDynamic:Bool,
	isOptional:Bool,
	isFinal:Bool
}

typedef MemberField = {
	field:ClassField,
	definedBy:Classdef
}

typedef InheritedFields = {
	methods:Map<Classdef, Array<ClassField>>,
	fields:Map<Classdef, Array<ClassField>>,
	// defines order of the types since keys in maps arent ordered
	types:Array<Classdef>,
}
