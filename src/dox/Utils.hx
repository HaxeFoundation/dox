package dox;

import haxe.rtti.CType.Path;
using StringTools;

class Utils {
	public static function urlEscape(path:Path):String {
		var toEscape = "index";
		if (path.toLowerCase().endsWith(toEscape))
			return path.substr(0, path.length - toEscape.length) + "$index";
		return path;
	}
}