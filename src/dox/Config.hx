package dox;

@:keep
class Config{
	public var rootPath(default, set):String;
	public var outputPath(default, set):String;
	public var xmlPath(default, set):String;
	public var pathFilters(default, null):haxe.ds.GenericStack<Filter>;
	
	public var platforms:Array<String>;
	public var resourcePaths:Array<String>;
	public var templatePaths(default, null):haxe.ds.GenericStack<String>;
	
	public var pageTitle:String;
	
	function set_rootPath(v) {
		return rootPath = haxe.io.Path.removeTrailingSlashes(StringTools.replace(v, "\\", "/"));
	}
	
	function set_outputPath(v) {
		return outputPath = haxe.io.Path.removeTrailingSlashes(v);
	}
	
	function set_xmlPath(v) {
		return xmlPath = haxe.io.Path.removeTrailingSlashes(v);
	}
	
	public function new() {
		platforms = [];
		resourcePaths = [];
		pathFilters = new haxe.ds.GenericStack<Filter>();
		templatePaths = new haxe.ds.GenericStack<String>();
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
}

private class Filter {
	public var r(default, null):EReg;
	public var isIncludeFilter(default, null):Bool;
	
	public function new(pattern: String, isIncludeFilter:Bool) {
		r = new EReg(pattern, "");
		this.isIncludeFilter = isIncludeFilter;
	}
}