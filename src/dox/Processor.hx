package dox;

import haxe.rtti.CType;
using Lambda;

class Processor {
	
	var config:Config;
	public var infos:Infos;
	
	var markdownHandler:MarkdownHandler;
	
	public function new(cfg:Config) {
		config = cfg;
		infos = new Infos();
		markdownHandler = new MarkdownHandler(cfg);
	}
	
	public function process(root:TypeRoot) {
		root = filter(root);
		sort(root);
		return processRoot(root);
	}
	
	function filter(root:TypeRoot) {
		var newRoot = [];
		function filter(root, tree) {
			return switch(tree) {
				case TPackage(name, full, subs):
					var acc = [];
					subs.iter(filter.bind(acc));
					if (!isFiltered(full)) root.push(TPackage(name, full, acc));
				case TClassdecl(t):
					t.fields = filterFields(t.fields);
					t.statics = filterFields(t.statics);
					if (!isFiltered(t.path)) root.push(tree);
				case TEnumdecl(t): if (!isFiltered(t.path)) root.push(tree);
				case TTypedecl(t): if (!isFiltered(t.path)) root.push(tree);
				case TAbstractdecl(t):
					if (t.impl != null) {
						t.impl.fields = filterFields(t.impl.fields);
						t.impl.statics = filterFields(t.impl.statics);
					}
					if (!isFiltered(t.path)) root.push(tree);
			}
		}
		root.iter(filter.bind(newRoot));
		return newRoot;
	}
	
	function filterFields(fields:List<ClassField>) {
		return fields.filter(function(cf) {
			return cf.isPublic || cf.meta.exists(function(m) return m.name == ":doc");
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
	
	function processRoot(root:TypeRoot)
	{
		var rootTypes = [];
		var rootPack = TPackage('top level', '', rootTypes);
		var newRoot = [rootPack];

		for (tree in root) switch (tree)
		{
			case TPackage(_,_,_): newRoot.push(tree);
			default: rootTypes.push(tree);
		}

		newRoot.iter(processTree);
		return newRoot;
	}

	function processTree(tree:TypeTree)
	{
		switch (tree)
		{
			case TPackage(_, full, subs):
				subs.iter(processTree);

			case TEnumdecl(t):
				infos.typeMap.set(t.path, t);
				t.doc = processDoc(t.doc);
				t.constructors.iter(processEnumField);

			case TTypedecl(t):
				infos.typeMap.set(t.path, t);
				t.doc = processDoc(t.doc);

			case TClassdecl(t):
				infos.typeMap.set(t.path, t);
				t.doc = processDoc(t.doc);
				t.fields.iter(processClassField);
				t.statics.iter(processClassField);
				if (t.isInterface) infos.implementors.set(t.path, []);
				if (t.superClass != null)
				{
					if (!infos.subClasses.exists(t.superClass.path)) infos.subClasses.set(t.superClass.path, [t.path]);
					else infos.subClasses.get(t.superClass.path).push(t.path);
				}
				for (i in t.interfaces)
				{
					if (!infos.implementors.exists(i.path)) infos.implementors.set(i.path, [t.path]);
					else infos.implementors.get(i.path).push(t.path);
				}

			case TAbstractdecl(t):
				infos.typeMap.set(t.path, t);
				if (t.impl != null)
				{
					t.impl.fields.iter(processClassField);
					t.impl.statics.iter(processClassField);
				}
				t.doc = processDoc(t.doc);
		}
	}

	function processClassField(field:ClassField)
	{
		field.doc = processDoc(field.doc);
	}

	function processEnumField(field:EnumField)
	{
		field.doc = processDoc(field.doc);
	}
	
	function processDoc(doc:String) {
		if (doc == null || doc == '') return '<p></p>';
		
		var ereg = ~/^([\t ]+).+/m;
		while (ereg.match(doc))
		{
			var tabs = new EReg("^" + ereg.matched(1), "gm");
			doc = tabs.replace(doc, "");
		}
		if (doc.charAt(doc.length - 1) == "*") doc = doc.substr(0, doc.length - 1);
		doc = StringTools.trim(doc);

		return markdownHandler.markdownToHtml(doc);
	}
	
	function isFiltered(path:Path) {
		for (filter in config.pathFilters) {
			if (filter.r.match(path)) return !filter.isIncludeFilter;
		}
		return !config.pathFilters.isEmpty();
	}
}