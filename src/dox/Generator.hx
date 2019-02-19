package dox;

import haxe.rtti.CType;
import templo.Template;

class Generator {
	var api:Api;
	var writer:Writer;
	var tplNav:Template;
	var tplPackage:Template;
	var tplClass:Template;
	var tplEnum:Template;
	var tplTypedef:Template;
	var tplAbstract:Template;
	var tplError:Template;

	public function new(api:Api, writer:Writer) {
		this.api = api;
		this.writer = writer;
		var config = api.config;
		tplNav = config.loadTemplate("nav.mtt");
		tplPackage = config.loadTemplate("package.mtt");
		tplClass = config.loadTemplate("class.mtt");
		tplEnum = config.loadTemplate("enum.mtt");
		tplTypedef = config.loadTemplate("typedef.mtt");
		tplAbstract = config.loadTemplate("abstract.mtt");
		tplError = config.loadTemplate("404.mtt");
	}

	public function generate(root:TypeRoot) {
		root.iter(generateTree);
	}

	public function generateNavigation(root:TypeRoot) {
		api.config.rootPath = "::rootPath::";
		var s = tplNav.execute({
			api: api,
			root: switch (root) {
				case [TPackage(_, '', subs)]: subs;
				default: throw "root should be [top level package]";
			}
		});
		writer.saveContent("nav.js", ~/[\r\n\t]/g.replace(s, ""));
	}

	public function generateErrorPage(root:TypeRoot) {
		var full = 'File not found';
		var name = 'File not found';
		api.config.setRootPath('');
		api.currentPageName = full == "" ? name : full;
		var s = tplError.execute({
			api: api,
			name: name,
			full: full,
			root: switch (root) {
				case [TPackage(_, '', subs)]: subs;
				default: throw "root should be [top level package]";
			}
		});
		writer.saveContent("404.html", ~/[\r\n\t]/g.replace(s, ""));
	}

	@:access(dox.Api.sanitizePath)
	function generateTree(tree:TypeTree) {
		switch (tree) {
			case TPackage(name, full, subs):
				if (name.charAt(0) == "_")
					return;
				api.currentPageName = full == "" ? name : full;
				api.config.setRootPath(full == '' ? full : full + ".pack");
				api.currentPageUrl = fileUrl(full == '' ? 'index' : full + '.index');
				var s = tplPackage.execute({
					api: api,
					name: name,
					full: full,
					subs: subs,
				});
				write(api.currentPageUrl, s);
				api.infos.numGeneratedPackages++;
				subs.iter(generateTree);
			case TClassdecl(c):
				api.currentPageName = c.path;
				api.config.setRootPath(c.path);
				api.currentPageUrl = fileUrl(api.sanitizePath(c.path));
				var s = tplClass.execute({
					api: api,
					"type": c,
					"subClasses": api.infos.subClasses.get(c.path),
					"implementors": api.infos.implementors.get(c.path)
				});
				write(api.currentPageUrl, s);
				api.infos.numGeneratedTypes++;
			case TEnumdecl(e):
				api.currentPageName = e.path;
				api.config.setRootPath(e.path);
				api.currentPageUrl = fileUrl(api.sanitizePath(e.path));
				var s = tplEnum.execute({
					api: api,
					"type": e,
				});
				write(api.currentPageUrl, s);
				api.infos.numGeneratedTypes++;
			case TTypedecl(t):
				api.currentPageName = t.path;
				api.config.setRootPath(t.path);
				api.currentPageUrl = fileUrl(api.sanitizePath(t.path));
				var s = tplTypedef.execute({
					api: api,
					"type": t,
				});
				write(api.currentPageUrl, s);
				api.infos.numGeneratedTypes++;
			case TAbstractdecl(a):
				api.currentPageName = a.path;
				api.config.setRootPath(a.path);
				api.currentPageUrl = fileUrl(api.sanitizePath(a.path));
				var s = tplAbstract.execute({
					api: api,
					"type": a,
				});
				write(api.currentPageUrl, s);
				api.infos.numGeneratedTypes++;
		}
	}

	function fileUrl(path:String) {
		return path.replace(".", "/").replace("<", "_").replace(">", "_") + '.html';
	}

	function write(fileUrl:String, content:String) {
		writer.saveContent(fileUrl, content);
	}
}
