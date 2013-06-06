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
		templo.Template.fromFile(api.config.templatePath + "macros.mtt");
		templo.Template.fromFile(api.config.templatePath + "main.mtt");
		templo.Template.fromFile(api.config.templatePath + "class_field.mtt");
		templo.Template.fromFile(api.config.templatePath + "enum_field.mtt");
		tplNav = templo.Template.fromFile(api.config.templatePath + "nav.mtt");
		tplPackage = templo.Template.fromFile(api.config.templatePath + "package.mtt");
		tplClass = templo.Template.fromFile(api.config.templatePath + "class.mtt");
		tplEnum = templo.Template.fromFile(api.config.templatePath + "enum.mtt");
		tplTypedef = templo.Template.fromFile(api.config.templatePath + "typedef.mtt");
		tplAbstract = templo.Template.fromFile(api.config.templatePath + "abstract.mtt");
	}
	
	public function generate(root:TypeRoot) {
		root.iter(generateTree);
	}
	
	public function generateNavigation(root:TypeRoot) {
		var s = tplNav.execute({
			api: api,
			root: root
		});
		sys.io.File.saveContent(api.config.outputPath + "nav.js", ~/[\r\n\t]/g.replace(s, ""));
	}
	
	function generateTree(tree:TypeTree) {
		switch(tree) {
			case TPackage(name, full, subs):
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
				var s = tplClass.execute({
					api: api,
					"type": c,
				});
				write(c.path, s);
				api.infos.numGeneratedTypes++;
			case TEnumdecl(e):
				var s = tplEnum.execute({
					api: api,
					"type": e,
				});
				write(e.path, s);
				api.infos.numGeneratedTypes++;
			case TTypedecl(t):
				var s = tplTypedef.execute({
					api: api,
					"type": t,
				});
				write(t.path, s);
				api.infos.numGeneratedTypes++;
			case TAbstractdecl(a):
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
		path = api.config.outputPath + path.split('.').join('/') + '.html';

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