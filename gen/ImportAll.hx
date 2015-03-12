import haxe.macro.Context;

// stolen from haxe/doc/ImportAll.hx
class ImportAll {

	public static function run( ?pack ) {
		if( pack == null ) {
			pack = "";
			haxe.macro.Compiler.define("doc_gen");
		}
		if (Context.defined("interp")) {
			haxe.macro.Compiler.define("macro");
		}
		switch( pack ) {
		case "php":
			if( !Context.defined("php") ) return;
		case "neko":
			if( !Context.defined("neko") ) return;
		case "js":
			if( !Context.defined("js") ) return;
		case "cpp":
			if( !Context.defined("cpp") ) return;
		case "flash8":
			return; // TODO: remove this when flash8 is removed from std library
		case "flash":
			if( !Context.defined("flash9") ) return;
		case "mt","mtwin":
			return;
		case "sys":
			if( !Context.defined("neko") && !Context.defined("php") && !Context.defined("cpp") ) return;
		case "java":
			if( !Context.defined("java") ) return;
		case "cs":
			if( !Context.defined("cs") ) return;
		case "python":
			if( !Context.defined("python") ) return;
		case "tools", "build-tool": return;
		}
		for( p in Context.getClassPath() ) {
			if( p == "/" )
				continue;
			// skip if we have a classpath to haxe
			if( pack.length == 0 && sys.FileSystem.exists(p+"std") )
				continue;
			var p = p + pack.split(".").join("/");
			if( StringTools.endsWith(p,"/") )
				p = p.substr(0,-1);
			if( !sys.FileSystem.exists(p) || !sys.FileSystem.isDirectory(p) )
				continue;
			for( file in sys.FileSystem.readDirectory(p) ) {
				if( file == ".svn" || file == "_std" || file == "src")
					continue;
				var full = (pack == "") ? file : pack + "." + file;
				if( StringTools.endsWith(file, ".hx") ) {
					var cl = full.substr(0, full.length - 3);
					switch( cl ) {
					case "ImportAll", "neko.db.MacroManager": continue;
					case "haxe.TimerQueue": if( Context.defined("neko") || Context.defined("php") || Context.defined("cpp") ) continue;
					case "Sys": if( !(Context.defined("neko") || Context.defined("php") || Context.defined("cpp")) ) continue;
					case "haxe.web.Request": if( !(Context.defined("neko") || Context.defined("php") || Context.defined("js")) ) continue;
					case "haxe.macro.ExampleJSGenerator","haxe.macro.Context", "haxe.macro.Compiler": if( !Context.defined("neko") ) continue;
					case "haxe.remoting.SocketWrapper": if( !Context.defined("flash") ) continue;
					case "haxe.remoting.SyncSocketConnection": if( !(Context.defined("neko") || Context.defined("php") || Context.defined("cpp")) ) continue;
					case "neko.vm.Ui" | "sys.db.Sqlite" | "sys.db.Mysql": if ( Context.defined("interp") ) continue;
					case "sys.db.Sqlite" | "sys.db.Mysql" | "cs.db.AdoNet": if ( Context.defined("cs") ) continue;
					case "haxe.PythonSyntax" | "haxe.PythonInternal": continue; // temp hack (https://github.com/HaxeFoundation/haxe/issues/3321)
					}
					Context.getModule(cl);
				} else if( sys.FileSystem.isDirectory(p + "/" + file) )
					run(full);
			}
		}
	}

}
