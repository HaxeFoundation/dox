package dox;

class Config{
	public var rootPath(default, set):String;
	public var platforms:Array<String>;
	public var templateDir:String;
	
	function set_rootPath(v) {
		return rootPath = StringTools.replace(v, "\\", "/");
	}
	
	public function new() { }
}