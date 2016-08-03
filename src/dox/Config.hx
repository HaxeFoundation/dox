package dox;

@:keep
class Config {
	public var theme:Theme;
	public var rootPath:String;
	public var toplevelPackage:String;
	public var useMarkdown:Bool;
	public var date:Date;

	public var outputPath(default, set):String;
	public var xmlPath(default, set):String;
	public var pathFilters(default, null):haxe.ds.GenericStack<Filter>;

	public var platforms:Array<String>;
	public var resourcePaths:Array<String>;
	public var templatePaths(default, null):haxe.ds.GenericStack<String>;

	public var defines:Map<String, String>;
	public var pageTitle:String;

	function set_outputPath(v) {
		return outputPath = haxe.io.Path.removeTrailingSlashes(v);
	}

	function set_xmlPath(v) {
		return xmlPath = haxe.io.Path.removeTrailingSlashes(v);
	}

	public function new() {
		platforms = [];
		resourcePaths = [];
		toplevelPackage = "";
		useMarkdown = true;
		defines = new Map();
		pathFilters = new haxe.ds.GenericStack<Filter>();
		templatePaths = new haxe.ds.GenericStack<String>();
		date = Date.now();
	}

	public function addFilter(pattern:String, isIncludeFilter:Bool) {
		pathFilters.add(new Filter(pattern, isIncludeFilter));
	}

	public function addTemplatePath(path:String) {
		templatePaths.add(haxe.io.Path.removeTrailingSlashes(path));
	}

	public function loadTemplate(name:String) {
		for (tp in templatePaths) {
			if (sys.FileSystem.exists(tp + "/" +name)) return templo.Template.fromFile(tp + "/" + name);
		}
		throw "Could not resolve template: " +name;
	}

	public function setRootPath(path:String) {
		var depth = path.split(".").length - 1;
		rootPath = "";
		for (i in 0...depth) {
			rootPath += "../";
		}
		if (rootPath == "") rootPath = "./";
	}

	public function getHeaderIncludes() {
		var buf = new StringBuf();
		for (inc in theme.headerIncludes) {
			var path = new haxe.io.Path(inc);
			var s = switch(path.ext) {
				case 'css': '<link href="$rootPath${path.file}.css" rel="stylesheet" />';
				case 'js': '<script type="text/javascript" src="$rootPath${path.file}.js"></script>';
				case 'ico': '<link rel="icon" href="$rootPath${path.file}.ico" type="image/x-icon"></link>';
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

	public function new(pattern: String, isIncludeFilter:Bool) {
		r = new EReg(pattern, "");
		this.isIncludeFilter = isIncludeFilter;
	}
}
