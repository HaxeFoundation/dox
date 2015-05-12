package dox;

import haxe.rtti.CType;
using Lambda;
using StringTools;

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
			function filter(toplevelFilter, tree) {
				switch (tree) {
					case TPackage(name, full, subs):
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
		function filter(root, tree):Void {
			return switch(tree) {
				case TPackage(name, full, subs):
					var acc = [];
					subs.iter(filter.bind(acc));
					if (acc.length > 0 || !isPathFiltered(full)) root.push(TPackage(name, full, acc));
				case TClassdecl(t):
					t.fields = filterFields(t.fields);
					t.statics = filterFields(t.statics);
					if (!isTypeFiltered(t))
					{
						root.push(tree);
						infos.addType(t.path, t);
					}
				case TEnumdecl(t):
					if (!isTypeFiltered(t))
					{
						t.constructors = filterEnumFields(t.constructors);
						root.push(tree);
						infos.addType(t.path, t);
					}
				case TTypedecl(t):
					if (!isTypeFiltered(t))
					{
						switch (t.type)
						{
							case CAnonymous(fields): t.type = CAnonymous(filterFields(fields));
							default:
						}
						root.push(tree);
						infos.addType(t.path, t);
					}
				case TAbstractdecl(t):
					if (t.impl != null) {
						var fields = new List<ClassField>();
						var statics = new List<ClassField>();
						t.impl.statics.iter(function(cf) {
							if (cf.meta.exists(function(m) return m.name == ":impl")) {
								if (cf.name == "_new") cf.name = "new";
								else switch(cf.type) {
									case CFunction(args,_): args.pop();
									case _:
								}
								fields.push(cf);
							} else {
								statics.push(cf);
							}
						});
						t.impl.fields = filterFields(fields);
						t.impl.statics = filterFields(statics);
					}
					if (!isTypeFiltered(t))
					{
						root.push(tree);
						infos.addType(t.path, t);
					}
			}
		}
		root.iter(filter.bind(newRoot));
		return newRoot;
	}

	function filterFields(fields:List<ClassField>) {
		return fields.filter(function(cf) {
			return cf.isPublic && !Infos.hasDoxMetadata(cf.meta, "hide") || Infos.hasDoxMetadata(cf.meta, "show");
		});
	}

	function filterEnumFields(fields:List<EnumField>) {
		return fields.filter(function(cf) {
			return !Infos.hasDoxMetadata(cf.meta, "hide") || Infos.hasDoxMetadata(cf.meta, "show");
		});
	}

	function sort(root:TypeRoot) {
		function getName(t:TypeTree) {
			return switch(t) {
				case TEnumdecl(t): t.path;
				case TTypedecl(t): t.path;
				case TClassdecl(t): t.path;
				case TAbstractdecl(t): t.path;
				case TPackage(n,_,_): n;
			}
		}

		function compare(t1,t2) {
			return switch [t1, t2] {
				case [TPackage(n1,_,_),TPackage(n2,_,_)]: n1 < n2 ? -1 : 1;
				case [TPackage(_),_]: -1;
				case [_,TPackage(_)]: 1;
				case [t1,t2]:
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

		function sortFields(fields:List<ClassField>) {
			var a = fields.array();
			a.sort(compareFields);
			return a.list();
		}

		function sort(t:TypeTree) {
			switch(t) {
				case TPackage(_, _, subs):
					subs.sort(compare);
					subs.iter(sort);
				case TClassdecl(c) | TAbstractdecl({impl: c}) if (c != null):
					c.fields = sortFields(c.fields);
					c.statics = sortFields(c.statics);
				case _:
			}
		}
		root.sort(compare);
		root.iter(sort);
	}

	function processRoot(root:TypeRoot):TypeRoot
	{
		var newRoot = [TPackage('top level', '', root)];
		newRoot.iter(processTree);
		return newRoot;
	}

	function makeFilePathRelative(t:TypeInfos) {
		var path = t.module == null ? t.path : t.module;
		t.file = path.replace(".", "/") + ".hx";
	}

	function processTree(tree:TypeTree)
	{
		switch (tree)
		{
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
				switch (t.type)
				{
					case CAnonymous(fields): fields.iter(processClassField.bind(t.path));
					default:
				}
				makeFilePathRelative(t);
			case TClassdecl(t):
				config.setRootPath(t.path);
				t.doc = processDoc(t.path, t.doc);
				t.fields.iter(processClassField.bind(t.path));
				t.statics.iter(processClassField.bind(t.path));
				if (t.superClass != null) {
					if (!infos.subClasses.exists(t.superClass.path)) infos.subClasses.set(t.superClass.path, [t]);
					else infos.subClasses.get(t.superClass.path).push(t);
				}
				for (i in t.interfaces) {
					if (!infos.implementors.exists(i.path)) infos.implementors.set(i.path, [t]);
					else infos.implementors.get(i.path).push(t);
				}
				makeFilePathRelative(t);
			case TAbstractdecl(t):
				config.setRootPath(t.path);
				if (t.impl != null)
				{
					t.impl.fields.iter(processClassField.bind(t.path));
					t.impl.statics.iter(processClassField.bind(t.path));
				}
				t.doc = processDoc(t.path, t.doc);
				makeFilePathRelative(t);
		}
	}

	function processClassField(path:String, field:ClassField)
	{
		field.doc = processDoc(path, field.doc);
	}

	function processEnumField(path:String, field:EnumField)
	{
		field.doc = processDoc(path, field.doc);
	}

	function trimDoc(doc:String)
	{
		if (doc == null) return '';

		// trim leading asterixes
		while (doc.charAt(0) == '*') doc = doc.substr(1);

		// trim trailing asterixes
		while (doc.charAt(doc.length - 1) == '*') doc = doc.substr(0, doc.length - 1);

		// replace leading whitespace from each line with tabs
		var arr = doc.split('\n');
		var flagCode = false;
		var ereg = ~/^( *)/;
		var minSpaces = 10;
		for (idx in 0...arr.length)
		{
			if (arr[idx].indexOf('```') >= 0)
				flagCode = !flagCode;
			if (arr[idx].indexOf('<pre>') >= 0)
				flagCode = true;
			if (arr[idx].indexOf('</pre>') >= 0)
				flagCode = false;

			if (!flagCode && arr[idx].charAt(0) == ' ')
			{
				ereg.match(arr[idx]);
				var cnt = ereg.matched(0).length;
				var tmp = new StringBuf();
				if (cnt < minSpaces)
					minSpaces = cnt;
				var max = (minSpaces > 2 ? Std.int(cnt / 2) : cnt);
				for (i in 0...max)
					tmp.add('\t');
				arr[idx] = tmp.toString() + StringTools.trim(arr[idx]);
			}
		}
		doc = arr.join('\n');

		// detect doc comment style/indent
		var ereg = ~/^( \* |\t\* |\t \* |\t\t| +\* )/m;
		var matched = ereg.match(doc);

		// special case for single tab indent because my regex isn't clever enough
		if (!matched)
		{
			ereg = ~/^(\t)/m;
			matched = ereg.match(doc);
		}

		if (matched)
		{
			var string = ereg.matched(1);

			// escape asterixes
			string = string.split('*').join('\\*');

			// make trailing space optional
			if (string.charAt(string.length - 1) == ' ')
				string = string.substr(0, string.length - 1) + ' ?';

			var indent = new EReg("^" + string, "gm");
			doc = indent.replace(doc, "");
		}

		// trim additional whitespace
		doc = StringTools.trim(doc);

		return doc;
	}

	function processDoc(path:String, doc:String)
	{
		doc = trimDoc(doc);
		if (doc == '') return '<p></p>';
		var info = javadocHandler.parse(path, doc);
		return tplDoc.execute({ info:info });
	}

	function isTypeFiltered(type:{path:Path, meta:MetaData, isPrivate:Bool})
	{
		if (Infos.hasDoxMetadata(type.meta, "show")) return false;
		if (Infos.hasDoxMetadata(type.meta, "hide")) return true;
		if (type.isPrivate) return true;
		return isPathFiltered(type.path);
	}

	function isPathFiltered(path:Path) {

		var hasInclusionFilter = false;
		for (filter in config.pathFilters) {
			if (filter.isIncludeFilter) hasInclusionFilter = true;
			if (filter.r.match(path)) return !filter.isIncludeFilter;
		}
		return hasInclusionFilter;
	}
}
