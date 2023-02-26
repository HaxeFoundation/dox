package dox;

import haxe.Serializer;
import haxe.rtti.CType;

@:allow(dox.test)
class Processor {
	public var infos:Infos;

	var tplDoc:templo.Template;
	var config:Config;
	var markdownHandler:MarkdownHandler;
	var javadocHandler:JavadocHandler;

	public function new(cfg:Config) {
		config = cfg;
		infos = new Infos();
		tplDoc = config.loadTemplate("doc.mtt");
		markdownHandler = new MarkdownHandler(cfg, infos);
		javadocHandler = new JavadocHandler(cfg, infos, markdownHandler);
	}

	public function process(root:TypeRoot) {
		root = filter(root);
		sort(root);
		return processRoot(root);
	}

	function filter(root:TypeRoot) {
		var newRoot = [];
		if (config.toplevelPackage != "") {
			var found = false;
			function filter(toplevelFilter:String, tree) {
				switch (tree) {
					case TPackage(name, _, subs):
						var split = toplevelFilter.split(".");
						if (split[0] != name) {
							return;
						}
						split.shift();
						if (split.length == 0) {
							root = subs;
							found = true;
							return;
						}
						subs.iter(filter.bind(split.join(".")));
					case _:
				}
			}
			root.iter(filter.bind(config.toplevelPackage));
			if (!found) {
				throw 'Could not find toplevel package ${config.toplevelPackage}';
			}
		}
		function filter(parent:Array<TypeTree>, tree:TypeTree):Void {
			return switch (tree) {
				case TPackage(name, full, subs):
					var acc = [];
					subs.iter(filter.bind(acc));
					if (acc.length > 0 && !isPathFiltered(full)) {
						parent.push(TPackage(name, full, acc));
					}
				case TClassdecl(t):
					t.fields = filterFields(t.fields);
					t.statics = filterFields(t.statics);
					if (!isTypeFiltered(t)) {
						parent.push(tree);
						infos.addType(t.path, t);
					}
				case TEnumdecl(t):
					if (!isTypeFiltered(t)) {
						t.constructors = filterEnumFields(t.constructors);
						parent.push(tree);
						infos.addType(t.path, t);
					}
				case TTypedecl(t):
					if (!isTypeFiltered(t)) {
						switch (t.type) {
							case CAnonymous(fields):
								t.type = CAnonymous(filterFields(fields));
							default:
						}
						parent.push(tree);
						infos.addType(t.path, t);
					}
				case TAbstractdecl(t):
					if (t.impl != null) {
						populateFieldsOfAbstract(t, root);
					}
					if (!isTypeFiltered(t)) {
						parent.push(tree);
						infos.addType(t.path, t);
					}
			}
		}
		root.iter(filter.bind(newRoot));
		return newRoot;
	}

	function populateFieldsOfAbstract(theAbstract:Abstractdef, root:TypeRoot) {
		if (hasDoxMetadata(theAbstract.impl.meta, "is-populated")) {
			return; // nothing to do
		}

		var statics = new Array<ClassField>();
		var fields = new Array<ClassField>();

	 	// collect direct members
		for (cf in theAbstract.impl.statics) {
			switch (cf.type) {
				// handling functions
				case CFunction(args, _):
					if (cf.name == "_new") { // constructor
						cf.name = "new";
						// the Haxe compiler automatically adds a ":noCompletion"
						// so we remove the first auto-generated occurrence
						var noCompletionMeta = cf.meta.find(m ->  m.name == ":noCompletion");
						if (noCompletionMeta != null) cf.meta.remove(noCompletionMeta);
						fields.push(cf);
					} else if (args.length == 0 || args[0].name != "this") {
						statics.push(cf);
					} else
						fields.push(cf);
				// handling variables (declared with get and/or set accessor)
				case CAbstract(name, params):
					var isStatic = true;
					switch(cf.get) {
						case RCall("accessor"):
							final accessor = theAbstract.impl.statics.find(f -> f.name == "get_" + cf.name);
							if (accessor != null) {
								switch (accessor.type) {
									case CFunction(args, _):
										if (args.length > 0 && args[0].name == "this")
											isStatic = false;
									case _:
								}
							}
						case _:
							switch(cf.set) {
								case RCall("accessor"):
									final accessor = theAbstract.impl.statics.find(f -> f.name == "set_" + cf.name);
									if (accessor != null) { 
										switch (accessor.type) {
											case CFunction(args, _):
												if (args.length > 0 && args[0].name == "this")
													isStatic = false;
											case _:
										}
									}
								case _:
							}
					}
					if (isStatic)
						statics.push(cf);
					else {
						fields.push(cf);
						}
				case _:
					statics.push(cf);
			}
		}

		// collect forwarded static fields
		final forwardStaticsMeta = findMeta(theAbstract.meta, ":forwardStatics");
		if (forwardStaticsMeta != null) {
			switch (theAbstract.athis) {
				case CClass(name, params):
					switch (findInTrees(name, root)) {
						case TClassdecl(realType):
							if (forwardStaticsMeta.params == null || forwardStaticsMeta.params.length == 0) {
								statics = statics.concat(realType.statics);
							} else {
								for (classStatic in realType.statics) {
									if (forwardStaticsMeta.params.contains(classStatic.name))
										statics.push(classStatic);
								}
							}
						case _:
					}
				case CAbstract(name, _):
					switch (findInTrees(name, root)) {
						case TAbstractdecl(realType):
							populateFieldsOfAbstract(realType, root);
							if (forwardStaticsMeta.params == null || forwardStaticsMeta.params.length == 0) {
								statics = statics.concat(realType.impl.statics);
							} else {
								for (classStatic in realType.impl.statics) {
									if (forwardStaticsMeta.params.contains(classStatic.name))
										statics.push(classStatic);
								}
							}
						case _:
					}
				case _:
			}
		}

		// collect forwarded instance fields
		final forwardMeta = findMeta(theAbstract.meta, ":forward");
		if (forwardMeta != null) {
			switch (theAbstract.athis) {
				case CClass(name, _):
					switch (findInTrees(name, root)) {
						case TClassdecl(realType):
							if (forwardMeta.params == null || forwardMeta.params.length == 0) {
								fields = fields.concat(realType.fields);
							} else {
								for (classField in realType.fields) {
									if (forwardMeta.params.contains(classField.name))
										fields.push(classField);
								}
							}
						case _:
					}
				case CAbstract(name, _):
					switch (findInTrees(name, root)) {
						case TAbstractdecl(realType):
							populateFieldsOfAbstract(realType, root);
							if (forwardMeta.params == null || forwardMeta.params.length == 0) {
								fields = fields.concat(realType.impl.fields);
							} else {
								for (classField in realType.impl.fields) {
									if (forwardMeta.params.contains(classField.name))
										fields.push(classField);
								}
							}
						case _:
					}
				case _:
			}
		}
		theAbstract.impl.statics = filterFields(statics);
		theAbstract.impl.fields = filterFields(fields);
		setMetaParam(theAbstract.impl.meta, ":dox", "is-populated");
	}

	function filterFields(fields:Array<ClassField>) {
		return fields.filter(function(cf) {
			if (cf.overloads != null) {
				cf.overloads = filterFields(cf.overloads);
			}
			var hide = hasHideMetadata(cf.meta);
			var show = hasShowMetadata(cf.meta);
			return ((cf.isPublic || config.includePrivate) && !hide) || show;
		});
	}

	function filterEnumFields(fields:Array<EnumField>) {
		return fields.filter(ef -> !hasHideMetadata(ef.meta) || hasShowMetadata(ef.meta));
	}

	/** Searches for a TClassdecl or TAbstractdecl in the given trees */
	static function findInTrees(path:String, trees:Array<TypeTree>):Null<TypeTree> {
		for (tree in trees) {
			final result = findInTree(path, tree);
			if (result != null) return result;
		}
		return null;
	}

	/** Searches for a TClassdecl or TAbstractdecl in the given tree */
	static function findInTree(path:String, tree:TypeTree):Null<TypeTree> {
		switch (tree) {
			case TPackage(_, full, subs):
				return findInTrees(path, subs);
			case TClassdecl(t):
				if (t.path == path) return tree;
			case TAbstractdecl(t):
				if (t.path == path) return tree;
			case _: return null;
		}
		return null;
	}

	function sort(root:TypeRoot) {
		function getName(t:TypeTree) {
			return switch (t) {
				case TEnumdecl(t): t.path;
				case TTypedecl(t): t.path;
				case TClassdecl(t): t.path;
				case TAbstractdecl(t): t.path;
				case TPackage(n, _, _): n;
			}
		}

		function compare(t1, t2) {
			return switch [t1, t2] {
				case [TPackage(n1, _, _), TPackage(n2, _, _)]: n1 < n2 ? -1 : 1;
				case [TPackage(_), _]: -1;
				case [_, TPackage(_)]: 1;
				case [t1, t2]:
					getName(t1) < getName(t2) ? -1 : 1;
			}
		}

		function compareFields(cf1, cf2)
			return switch [cf1.type, cf2.type] {
				case [CFunction(_), CFunction(_)]:
					cf1.name == "new" ? -1 : cf2.name == "new" ? 1 : cf1.name < cf2.name ? -1 : 1;
				case [CFunction(_), _]: 1;
				case [_, CFunction(_)]: -1;
				case [_, _]:
					cf1.name < cf2.name ? -1 : 1;
			}

		inline function sortFields(fields:Array<ClassField>) {
			if (!config.keepFieldOrder) {
				fields.sort(compareFields);
			}
		}

		function sort(t:TypeTree) {
			switch (t) {
				case TPackage(_, _, subs):
					subs.sort(compare);
					subs.iter(sort);
				case TClassdecl(c) | TAbstractdecl({impl: c}) if (c != null):
					sortFields(c.fields);
					sortFields(c.statics);
				case TTypedecl(t):
					switch (t.type) {
						case CAnonymous(fields):
							sortFields(fields);
							t.type = CAnonymous(fields);
						default:
					}
				case _:
			}
		}
		root.sort(compare);
		root.iter(sort);
	}

	function processRoot(root:TypeRoot):TypeRoot {
		var newRoot = [
			TPackage(config.toplevelPackage == '' ? 'top level' : config.toplevelPackage, '', root)
		];
		newRoot.iter(processTree);
		return newRoot;
	}

	function makeFilePathRelative(t:TypeInfos) {
		if (t.file != null && t.file.endsWith(".hx")) {
			var path = t.module == null ? t.path : t.module;
			t.file = path.replace(".", "/") + ".hx";
		}
	}

	function processTree(tree:TypeTree) {
		switch (tree) {
			case TPackage(_, full, subs):
				config.setRootPath(full + ".pack");
				subs.iter(processTree);

			case TEnumdecl(t):
				config.setRootPath(t.path);
				t.doc = processDoc(t.path, t.doc);
				t.constructors.iter(processEnumField.bind(t.path));
				makeFilePathRelative(t);

			case TTypedecl(t):
				config.setRootPath(t.path);
				t.doc = processDoc(t.path, t.doc);

				var mergedTypes = new Map<String, CType>();
				for (platform => typeA in t.types) {
					var found = false;
					for (platforms => typeB in mergedTypes) {
						if (Serializer.run(typeA) == Serializer.run(typeB)) {
							mergedTypes.remove(platforms);
							mergedTypes[platforms + ", " + platform] = typeB;
							found = true;
							break;
						}
					}
					if (!found) {
						mergedTypes[platform] = typeA;
					}
				}
				t.types = mergedTypes;

				function processFields(type:CType) {
					switch (t.type) {
						case CAnonymous(fields):
							fields.iter(processClassField.bind(t.path));
						default:
					}
				}
				processFields(t.type);
				t.types.iter(processFields);

				makeFilePathRelative(t);

			case TClassdecl(t):
				config.setRootPath(t.path);
				t.doc = processDoc(t.path, t.doc);
				t.fields.iter(processClassField.bind(t.path));
				t.statics.iter(processClassField.bind(t.path));
				if (t.superClass != null) {
					var subClasses = infos.subClasses[t.superClass.path];
					if (subClasses == null)
						infos.subClasses[t.superClass.path] = [t];
					else
						subClasses.push(t);
				}
				for (i in t.interfaces) {
					var implementors = infos.implementors[i.path];
					if (implementors == null)
						infos.implementors[i.path] = [t];
					else
						implementors.push(t);
				}
				makeFilePathRelative(t);

			case TAbstractdecl(t):
				config.setRootPath(t.path);
				if (t.impl != null) {
					t.impl.fields.iter(processClassField.bind(t.path));
					t.impl.statics.iter(processClassField.bind(t.path));
				}
				t.doc = processDoc(t.path, t.doc);
				makeFilePathRelative(t);
		}
	}

	function processClassField(path:String, field:ClassField) {
		field.doc = processDoc(path, field.doc);
		removeEnumAbstractCast(field);
	}

	function removeEnumAbstractCast(field:ClassField) {
		// remove `cast` from the expression of enum abstract values (#146)
		if (field.type.match(CAbstract(_, _)) && hasMeta(field.meta, ":impl") && hasMeta(field.meta, ":enum") && field.get == RInline && field.set == RNo
			&& field.expr != null && field.expr.startsWith("cast ")) {
			field.expr = field.expr.substr("cast ".length);
		}
	}

	function processEnumField(path:String, field:EnumField) {
		field.doc = processDoc(path, field.doc);
	}

	function trimDoc(doc:String) {
		// trim leading asterixes
		while (doc.charAt(0) == '*')
			doc = doc.substr(1);

		// trim trailing asterixes
		while (doc.charAt(doc.length - 1) == '*')
			doc = doc.substr(0, doc.length - 1);

		// trim additional whitespace
		doc = doc.trim();

		// detect doc comment style/indent
		var ereg = ~/^([ \t]+(\* )?)[^\s\*]/m;
		var matched = ereg.match(doc);

		if (matched) {
			var string = ereg.matched(1);

			// escape asterix and allow one optional space after it
			string = string.split('* ').join('\\* ?');

			var indent = new EReg("^" + string, "gm");
			doc = indent.replace(doc, "");
		}

		return doc;
	}

	function processDoc(path:String, doc:Null<String>) {
		if (doc == null)
			return '<p></p>';
		doc = trimDoc(doc);
		var info = javadocHandler.parse(path, doc);
		return tplDoc.execute({info: info});
	}

	function isTypeFiltered(type:{path:Path, meta:MetaData, isPrivate:Bool}) {
		if (hasShowMetadata(type.meta))
			return false;
		if (hasHideMetadata(type.meta))
			return true;
		if (type.isPrivate)
			return !config.includePrivate;
		return isPathFiltered(type.path);
	}

	function isPathFiltered(path:Path) {
		var hasInclusionFilter = false;
		for (filter in config.pathFilters) {
			if (filter.isIncludeFilter)
				hasInclusionFilter = true;
			if (filter.r.match(path))
				return !filter.isIncludeFilter;
		}
		return hasInclusionFilter;
	}

	function findMeta(meta:MetaData, name:String):Null<{name:String, params:Array<String>}> {
		return meta.find(meta -> meta.name == name);
	}

	function hasMeta(meta:MetaData, name:String) {
		return meta.exists(meta -> meta.name == name);
	}

	function hasDoxMetadata(meta:MetaData, ?parameterName:String):Bool {
		return meta.exists(m -> m.name == ":dox" && parameterName == null || m.params.has(parameterName));
	}

	function hasShowMetadata(meta:MetaData):Bool {
		return hasDoxMetadata(meta, "show");
	}

	function hasHideMetadata(meta:MetaData):Bool {
		return hasDoxMetadata(meta, "hide") || hasMeta(meta, ":compilerGenerated") || hasMeta(meta, ":noCompletion");
	}

	function setMetaParam(meta:MetaData, name:String, param:String) {
		var doxMeta = findMeta(meta, name);
		if (doxMeta == null)
			meta.push({name: name, params: [param]});
		else if (!doxMeta.params.contains(param))
			doxMeta.params.push(param);
	}
}
