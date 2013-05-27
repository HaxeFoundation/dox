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

		var data = sys.io.File.getContent("model.txt");
		var unserializer = new xray.Unserializer(data);
		var model:Map<String, Definition> = unserializer.unserialize();
		unserializer.updateRefs();

		var types = [];

		for (key in model.keys())
		{
			var def = model.get(key);
			types.push(def.def);
		}

		generate(types);
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
