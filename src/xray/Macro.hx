package xray;

import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Type;
import haxe.macro.Expr;
import sys.FileSystem;
using Lambda;
using StringTools;
using xray.TypeTools;
import xray.Data;

class Macro
{
	static var platform = getPlatform();

	public static function build()
	{
		Sys.println(platform);
		
		var classPaths = Context.getClassPath();
		classPaths = classPaths.filter(FileSystem.exists);
		classPaths = classPaths.map(normalizePath);
		for (path in classPaths) includePath(path);

		Context.onGenerate(generate);
	}

	static function getPlatform()
	{
		var platforms = ["js", "flash8", "flash", "cpp", "cs", "java", "neko", "php"];
		for (platform in platforms)
			if (Context.defined(platform)) return platform;
		throw "Unknown platform";
	}

	static function normalizePath(path:String)
	{
		path = path.split("\\").join("/");
		if (StringTools.endsWith(path, "/"))
			path = path.substr(0, -1);
		if (path == "")
			path = ".";
		return path;
	}

	static function includePath(path:String, ?pack:String="")
	{
		if (path == "src") return;
		if (path == ".") return;
		if (path.endsWith("_std")) return;
		
		for (file in FileSystem.readDirectory(path))
		{
			if (file == "web") continue;
			if (file == "SocketWrapper.hx") continue;
			if (file == "SyncSocketConnection.hx") continue;
			if (file == "ExampleJSGenerator.hx") continue;

			if (file.charAt(0) == "_" || file.charAt(0) == "." || file.indexOf("-") > -1) continue;
			var entry = path + "/" + file;

			if (FileSystem.isDirectory(entry))
			{
				if (path == "/usr/lib/haxe/std" && file != platform && file != "haxe") continue;
				includePath(entry, (pack == "" ? file : pack + "." + file));
			}
			else
			{
				if (!file.endsWith(".hx")) continue;

				var module = file.substr(0, -3);
				module = (pack == "" ? module : pack + "." + module);
				Context.getModule(module);
			}
		}
	}

	static function generate(types:Array<Type>)
	{
		var processor = new Processor();
		var model = processor.process(types);

		var serializer = new Serializer();
		serializer.serialize(model);

		sys.io.File.saveContent("bin/" + platform + ".txt",  serializer.toString());
	}
}
