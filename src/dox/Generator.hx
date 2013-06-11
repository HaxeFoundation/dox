package dox;

import haxe.rtti.CType;
using Lambda;

#if hxtemplo

class Generator {

	var api:Api;
	
	var tplNav:templo.Template;
	var tplPackage:templo.Template;
	var tplClass:templo.Template;
	var tplEnum:templo.Template;
	var tplTypedef:templo.Template;
	var tplAbstract:templo.Template;
	
	public function new(api:Api) {
		this.api = api;
		loadTemplate("macros.mtt");
		loadTemplate("main.mtt");
		loadTemplate("class_field.mtt");
		loadTemplate("enum_field.mtt");
		tplNav = loadTemplate("nav.mtt");
		tplPackage = loadTemplate("package.mtt");
		tplClass = loadTemplate("class.mtt");
		tplEnum = loadTemplate("enum.mtt");
		tplTypedef = loadTemplate("typedef.mtt");
		tplAbstract = loadTemplate("abstract.mtt");
	}
	
	function loadTemplate(name:String) {
		for (tp in api.config.templatePaths) {
			if (sys.FileSystem.exists(tp + "/" +name)) return templo.Template.fromFile(tp + "/" + name);
		}
		throw "Could not resolve template: " +name;
	}
	
	public function generate(root:TypeRoot) {
		root.iter(generateTree);
	}
	
	public function generateNavigation(root:TypeRoot) {
		var s = tplNav.execute({
			api: api,
			root: root
		});
		sys.io.File.saveContent(api.config.outputPath + "/nav.js", ~/[\r\n\t]/g.replace(s, ""));
	}
	
	function generateTree(tree:TypeTree) {
		switch(tree) {
			case TPackage(name, full, subs):
				if (name.charAt(0) == "_") return;
				api.currentPageName = "package " + name;
				api.currentFullName = "package " + full;
				var s = tplPackage.execute({
					api: api,
					name: name,
					full: full,
					subs: subs,
				});
				write(full == '' ? 'index' : full + '.index', s);
				api.infos.numGeneratedPackages++;
				subs.iter(generateTree);
			case TClassdecl(c):
				api.currentPageName = api.getPathName(c.path);
				api.currentFullName = c.path;
				var s = tplClass.execute({
					api: api,
					"type": c,
				});
				write(c.path, s);
				api.infos.numGeneratedTypes++;
			case TEnumdecl(e):
				api.currentPageName = api.getPathName(e.path);
				api.currentFullName = e.path;
				var s = tplEnum.execute({
					api: api,
					"type": e,
				});
				write(e.path, s);
				api.infos.numGeneratedTypes++;
			case TTypedecl(t):
				api.currentPageName = api.getPathName(t.path);
				api.currentFullName = t.path;
				var s = tplTypedef.execute({
					api: api,
					"type": t,
				});
				write(t.path, s);
				api.infos.numGeneratedTypes++;
			case TAbstractdecl(a):
				api.currentPageName = api.getPathName(a.path);
				api.currentFullName = a.path;
				var s = tplAbstract.execute({
					api: api,
					"type": a,
				});
				write(a.path, s);
				api.infos.numGeneratedTypes++;
		}
	}
	
	function write(path:String, content:String)
	{
		path = api.config.outputPath + "/" + path.split('.').join('/') + '.html';

		var parts = path.split("/");
		var current = [];
		while (parts.length > 1)
		{
			current.push(parts.shift());
			var dir = current.join("/");
			if (sys.FileSystem.exists(dir)) continue;
			sys.FileSystem.createDirectory(dir);
		}
		sys.io.File.saveContent(path, content);
	}
}

#else
typedef Generator = dox.Printer;
#end