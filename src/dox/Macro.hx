package dox;

import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Type;
using haxe.macro.Tools;
using Lambda;
using xray.TypeTools;

class Macro
{
	public static function include(pack:String)
	{
		var rec = true;
		var ignore:Array<String> = [];
		var classPaths:Array<String> = null;

		var skip = if( ignore == null ) {
			function(c) return false;
		} else {
			function(c) return Lambda.has(ignore, c);
		}
		if( classPaths == null ) {
			classPaths = Context.getClassPath();
			// do not force inclusion when using completion
			if( Context.defined("display") )
				return;
			// normalize class path
			for( i in 0...classPaths.length ) {
				var cp = StringTools.replace(classPaths[i], "\\", "/");
				if(StringTools.endsWith(cp, "/"))
					cp = cp.substr(0, -1);
				if( cp == "" )
					cp = ".";
				classPaths[i] = cp;
			}
		}
		var prefix = pack == '' ? '' : pack + '.';
		for( cp in classPaths ) {
			var path = pack == '' ? cp : cp + "/" + pack.split(".").join("/");
			if (path.indexOf("_") > -1) continue;
			if( !sys.FileSystem.exists(path) || !sys.FileSystem.isDirectory(path) )
				continue;
			for( file in sys.FileSystem.readDirectory(path) ) {
				if (file == "ExampleJSGenerator.hx") continue;
				if (file == "SocketWrapper.hx") continue;
				if (file == "SyncSocketConnection.hx") continue;
				if( StringTools.endsWith(file, ".hx") && file.indexOf("_") == -1) {
					var cl = prefix + file.substr(0, file.length - 3);
					if( skip(cl) )
						continue;
					Context.getModule(cl);
				} else if( rec && sys.FileSystem.isDirectory(path + "/" + file) && !skip(prefix + file) )
					include(prefix + file);
			}
		}
	}

	public static function init(packs:Array<String>)
	{
		for (pack in packs) include(pack);
		Context.onGenerate(generate);
	}

	static function generate(types:Array<Type>)
	{
		// only public types
		types = types.filter(TypeTools.isPublic);

		// only base types
		types = types.filter(TypeTools.isBaseType);

		Sys.println("Generating code model");
		var model = new Model(types);
		var printer = new Printer(model);
		
		for (type in types)
		{
			// print type
			var path = type.getPath();
			var name = path.join(".");
			Sys.println('Generating $name');
			printer.printType(type);

			// write page
			var file = "pages/" + path.join("/") + ".html";
			var output = printer.getHtml();
			write(file, output);
		}

		for (pack in model.packages.keys())
		{
			// print type
			var path = pack == "" ? [] : pack.split(".");
			var name = path.join(".");
			Sys.println('Generating $name');
			printer.printPack(pack);

			// write page
			var file = "pages/" + path.join("/") + "/index.html";
			var output = printer.getHtml();
			write(file, output);
		}
	}

	static function write(path:String, content:String)
	{
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
