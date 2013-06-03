package dox;

import haxe.macro.Type;
import xray.Data;
using haxe.macro.Tools;
using Lambda;
using xray.TypeTools;

typedef Definition = {platforms:Array<String>, type:Type};

class Generator
{
	static function main()
	{
		trace(Template.page("../../", "some navigation", "some body. oh yeah."));
		return;
		RefData;
		MetaData;
		haxe.macro.ClassKind;

		var all = [];
		var platforms = new Map<String, Array<String>>();

		for (platform in ["cpp", "flash", "neko", "php", "js", "cs", "java"])
		{
			var data = sys.io.File.getContent('bin/$platform.txt');
			var unserializer = new xray.Unserializer(data);
			var types = unserializer.getTypes();

			for (type in types)
			{
				var key = type.getName();
				if (platforms.exists(key))
				{
					platforms.get(key).push(platform);
					continue;
				}
				platforms.set(key, [platform]);
				all.push(type);
			}
		}

		generate(all, platforms);
	}

	static function generate(types:Array<Type>, platforms:Map<String, Array<String>>)
	{
		// only public types
		types = types.filter(TypeTools.isPublic);

		// only base types
		types = types.filter(TypeTools.isBaseType);

		// respect @:noDoc
		types = types.filter(function(t) return !t.toBaseType().meta.has(":noDoc"));
		
		Sys.println("Generating code model");
		var model = new Model(types);
		var printer = new Printer(model);
		
		for (type in types)
		{
			// print type
			var path = type.getPath();
			var name = path.join(".");
			Sys.println('Generating $name');
			printer.printType(type, platforms.get(name));

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
