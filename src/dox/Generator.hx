package dox;

import haxe.macro.Type;
import xray.Data;
using haxe.macro.Tools;
using Lambda;
using xray.TypeTools;

typedef Definition = {platforms:Array<String>, def:Type};

class Generator
{
	public static function main()
	{
		RefData;
		MetaData;
		haxe.macro.ClassKind;

		var all = [];
		var definitions = new Map<String, Bool>();

		for (platform in ["cpp", "flash", "neko", "php", "js"])
		{
			var data = sys.io.File.getContent('bin/$platform.txt');
			var unserializer = new xray.Unserializer(data);
			var types = unserializer.getTypes();

			for (type in types)
			{
				var key = type.getName();
				if (definitions.exists(key)) continue;
				definitions.set(key, true);
				all.push(type);
			}
		}

		generate(all);
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

		Sys.println("Types: " + types.length);
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
