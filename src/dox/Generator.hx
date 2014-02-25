package dox;

import haxe.rtti.CType;
using Lambda;
using StringTools;

class Generator {

	var api:Api;
	
	var tplNav:templo.Template;
	var tplPackage:templo.Template;
	var tplClass:templo.Template;
	var tplEnum:templo.Template;
	var tplTypedef:templo.Template;
	var tplAbstract:templo.Template;
	
	public function new(api:Api, config:Config) {
		this.api = api;
		config.loadTemplate("macros.mtt");
		config.loadTemplate("main.mtt");
		config.loadTemplate("class_field.mtt");
		config.loadTemplate("enum_field.mtt");
		config.loadTemplate("related_types.mtt");
		tplNav = config.loadTemplate("nav.mtt");
		tplPackage = config.loadTemplate("package.mtt");
		tplClass = config.loadTemplate("class.mtt");
		tplEnum = config.loadTemplate("enum.mtt");
		tplTypedef = config.loadTemplate("typedef.mtt");
		tplAbstract = config.loadTemplate("abstract.mtt");
	}
	
	public function generate(root:TypeRoot) {
		root.iter(generateTree);
	}
	
	public function generateNavigation(root:TypeRoot) {
		api.config.rootPath = "::rootPath::";
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
				api.config.setRootPath(full == '' ? full : full + ".pack");
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
				api.config.setRootPath(c.path);
				var s = tplClass.execute({
					api: api,
					"type": c,
					"subClasses": api.infos.subClasses.get(c.path),
					"implementors": api.infos.implementors.get(c.path)
				});
				write(c.path, s);
				api.infos.numGeneratedTypes++;
			case TEnumdecl(e):
				api.currentPageName = api.getPathName(e.path);
				api.currentFullName = e.path;
				api.config.setRootPath(e.path);
				var s = tplEnum.execute({
					api: api,
					"type": e,
				});
				write(e.path, s);
				api.infos.numGeneratedTypes++;
			case TTypedecl(t):
				api.currentPageName = api.getPathName(t.path);
				api.currentFullName = t.path;
				api.config.setRootPath(t.path);
				var s = tplTypedef.execute({
					api: api,
					"type": t,
				});
				write(t.path, s);
				api.infos.numGeneratedTypes++;
			case TAbstractdecl(a):
				api.currentPageName = api.getPathName(a.path);
				api.currentFullName = a.path;
				api.config.setRootPath(a.path);
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