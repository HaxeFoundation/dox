package dox;

import haxe.ds.GenericStack;
import templo.Template;
import sys.FileSystem;

@:keep
class Config {
	public var theme:Null<Theme>;
	public var rootPath:String;
	public var toplevelPackage:String;
	public var useMarkdown:Bool;
	public var includePrivate:Bool;
	public var date:Date;
	public var outputPath(default, set):String = "pages";
	public var xmlPath(default, set):String = "xml";
	public var pathFilters(default, null):GenericStack<Filter>;
	public var platforms:Array<String>;
	public var resourcePaths:Array<String>;
	public var templatePaths(default, null):GenericStack<String>;
	public var defines:Map<String, String>;
	public var pageTitle:Null<String>;

	function set_outputPath(v) {
		return outputPath = Path.removeTrailingSlashes(v);
	}

	function set_xmlPath(v) {
		return xmlPath = Path.removeTrailingSlashes(v);
	}

	public function new() {
		rootPath = "";
		platforms = [];
		resourcePaths = [];
		toplevelPackage = "";
		useMarkdown = true;
		includePrivate = false;
		defines = new Map();
		pathFilters = new GenericStack<Filter>();
		templatePaths = new GenericStack<String>();
		date = Date.now();
	}

	public function addFilter(pattern:String, isIncludeFilter:Bool) {
		pathFilters.add(new Filter(pattern, isIncludeFilter));
	}

	public function addTemplatePath(path:String) {
		templatePaths.add(Path.removeTrailingSlashes(path));
	}

	public function loadTemplates(path:String) {
		addTemplatePath(path);
		if (!FileSystem.exists(path)) {
			return;
		}
		for (file in FileSystem.readDirectory(path)) {
			var path = new Path(file);
			if (path.ext == "mtt") {
				loadTemplate(file);
			}
		}
	}

	public function loadTemplate(name:String) {
		for (tp in templatePaths) {
			if (FileSystem.exists(tp + "/" + name))
				return Template.fromFile(tp + "/" + name);
		}
		throw "Could not resolve template: " + name;
	}

	public function loadTheme(owd:String, path:String) {
		if (path.indexOf("/") == -1 && path.indexOf("\\") == -1) {
			path = Path.normalize(Path.join([owd, "themes", path]));
		}
		var configPath = Path.join([path, "config.json"]);
		var themeConfig = try sys.io.File.getContent(configPath) catch (e:Dynamic) {
			throw 'Could not load $configPath';
		}
		var theme:Theme = haxe.Json.parse(themeConfig);
		if (theme.parentTheme != null) {
			loadTheme(owd, theme.parentTheme);
		}
		var resourcesPath = Path.join([path, "resources"]);
		if (FileSystem.exists(resourcesPath))
			resourcePaths.push(resourcesPath);

		loadTemplates(Path.join([path, "templates"]));
		this.theme = theme;
	}

	public function setRootPath(path:String) {
		var depth = path.split(".").length - 1;
		rootPath = "";
		for (_ in 0...depth) {
			rootPath += "../";
		}
		if (rootPath == "")
			rootPath = "./";
	}

	public function getHeaderIncludes() {
		var buf = new StringBuf();
		var headerIncludes = [];
		if (theme != null && theme.headerIncludes != null) {
			headerIncludes = theme.headerIncludes;
		}
		for (include in headerIncludes) {
			var path = new Path(include);
			var s = switch (path.ext) {
				case 'css': '<link href="$rootPath${path.file}.css" rel="stylesheet" />';
				case 'js': '<script src="$rootPath${path.file}.js"></script>';
				case 'ico': '<link rel="icon" href="$rootPath${path.file}.ico" type="image/x-icon" />';
				case s: throw 'Unknown header include extension: $s';
			}
			buf.add(s);
		}
		return buf.toString();
	}
}

private class Filter {
	public var r(default, null):EReg;
	public var isIncludeFilter(default, null):Bool;

	public function new(pattern:String, isIncludeFilter:Bool) {
		r = new EReg(pattern, "");
		this.isIncludeFilter = isIncludeFilter;
	}
}
