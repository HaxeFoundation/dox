package dox;

import haxe.rtti.CType;
using Lambda;

class Generator {

	var api:Api;
	
	var tplNav:templo.Template;
	var tplPackage:templo.Template;
	var tplClass:templo.Template;
	var tplEnum:templo.Template;
	
	public function new(api:Api) {
		this.api = api;
		templo.Template.fromFile("templates/macros.mtt");
		templo.Template.fromFile("templates/main.mtt");
		templo.Template.fromFile("templates/class_field.mtt");
		templo.Template.fromFile("templates/enum_field.mtt");
		tplNav = templo.Template.fromFile("templates/nav.mtt");
		tplPackage = templo.Template.fromFile("templates/package.mtt");
		tplClass = templo.Template.fromFile("templates/class.mtt");
		tplEnum = templo.Template.fromFile("templates/enum.mtt");
	}
	
	public function generate(root:TypeRoot) {
		root.iter(generateTree);
	}
	
	public function generateNavigation(root:TypeRoot) {
		var s = tplNav.execute({
			api: api,
			root: root
		});
		sys.io.File.saveContent(api.config.rootPath + "nav.js", s);
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
				subs.iter(generateTree);
			case TClassdecl(c):
				var s = tplClass.execute({
					api: api,
					"class": c,
				});
				write(c.path, s);
			case TEnumdecl(e):
				var s = tplEnum.execute({
					api: api,
					"enum": e,
				});
				write(e.path, s);
			case _:
		}
	}
	
	function write(path:String, content:String)
	{
		path = api.config.rootPath + path.split('.').join('/') + '.html';

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