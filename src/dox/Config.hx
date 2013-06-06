package dox;

class Config{
	public var rootPath(default, set):String;
	public var outputPath(default, set):String;
	public var xmlPath(default, set):String;
	public var platforms:Array<String>;
	public var templateDir:String;
	public var resourcePaths:Array<String>;
	
	function set_rootPath(v) {
		return rootPath = haxe.io.Path.addTrailingSlash(StringTools.replace(v, "\\", "/"));
	}
	
	function set_outputPath(v) {
		return outputPath = haxe.io.Path.addTrailingSlash(v);
	}
	
	function set_xmlPath(v) {
		return xmlPath = haxe.io.Path.addTrailingSlash(v);
	}
	
	public function new() {
		platforms = [];
		resourcePaths = [];
	}
}