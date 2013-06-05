package dox;

import haxe.rtti.CType;
using Lambda;

class Generator {

	var config:Config;

	var api:Api;
	var tplPackage:templo.Template;
	var tplClass:templo.Template;
	
	public function new(cfg:Config) {
		config = cfg;
		api = new Api(cfg);
		templo.Template.fromFile("templates/macros.mtt");
		templo.Template.fromFile("templates/main.mtt");
		templo.Template.fromFile("templates/class_field.mtt");
		tplPackage = templo.Template.fromFile("templates/package.mtt");
		tplClass = templo.Template.fromFile("templates/class.mtt");
	}
	
	public function generate(root:TypeRoot) {
		root.iter(generateTree);
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
			case _:
		}
	}
	
	function write(path:String, content:String)
	{
		path = config.rootPath + path.split('.').join('/') + '.html';

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