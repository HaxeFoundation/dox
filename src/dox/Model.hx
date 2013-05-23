package dox;

import haxe.macro.Type;
using dox.TypeTools;

class Model
{
	var typeMap:Map<String, BaseType>;
	var classTypes:Array<ClassType>;
	var directSubclasses:Map<String, Array<ClassType>>;
	var indrectSubclasses:Map<String, Array<ClassType>>;
	var directImplementors:Map<String, Array<ClassType>>;
	var indrectImplementors:Map<String, Array<ClassType>>;
	var docs:Map<String, String>;
	public var packages:Map<String, Array<Type>>;

	public function new(types:Array<Type>)
	{
		typeMap = new Map();
		classTypes = [];
		directSubclasses = new Map();
		indrectSubclasses = new Map();
		directImplementors = new Map();
		indrectImplementors = new Map();
		docs = new Map();
		packages = new Map();

		for (type in types)
		{
			var base = type.toBaseType();
			if (base == null) continue;

			if (base.isPrivate) continue;

			typeMap.set(getClassTypeID(base), base);
			
			var pack = base.pack.join(".");
			if (!packages.exists(pack))
				packages.set(pack, []);
			packages.get(pack).push(type);

			switch (type)
			{
				case TInst(t, _): classTypes.push(t.get());
				case _:
			}
		}

		for (type in types)
		{
			var base = type.toBaseType();
			if (base == null) continue;
			if (base.isPrivate) continue;

			var id = getClassTypeID(base);
			if (base.doc != null) docs.set(id, parseDoc(base.doc));
		}

		for (type in classTypes)
		{
			for (inter in type.interfaces)
			{
				var id = getClassTypeID(inter.t.get());
				if (!directImplementors.exists(id))
					directImplementors.set(id, []);
				directImplementors.get(id).push(type);
			}

			if (type.superClass == null) continue;
			var sup = type.superClass.t.get();
			
			// direct subclass of
			var id = getClassTypeID(sup);
			if (!directSubclasses.exists(id))
				directSubclasses.set(id, []);
			directSubclasses.get(id).push(type);

			if (sup.superClass == null) continue;
			var sup = sup.superClass.t.get();

			// indirect subclasses of
			while (sup != null)
			{
				var id = getClassTypeID(sup);
				if (!indrectSubclasses.exists(id))
					indrectSubclasses.set(id, []);
				indrectSubclasses.get(id).push(type);

				if (sup.superClass == null) break;
				sup = sup.superClass.t.get();
			}
		}
	}

	public function getSubClasses(type:ClassType):Array<ClassType>
	{
		return getIndirectSubclasses(type).concat(getDirectSubclasses(type));
	}

	public function getDirectSubclasses(type:ClassType):Array<ClassType>
	{
		var id = getClassTypeID(type);
		if (!directSubclasses.exists(id)) return [];
		return directSubclasses.get(id);
	}

	public function getIndirectSubclasses(type:ClassType):Array<ClassType>
	{
		var id = getClassTypeID(type);
		if (!indrectSubclasses.exists(id)) return [];
		return indrectSubclasses.get(id);
	}

	public function getDirectImplementors(type:ClassType):Array<ClassType>
	{
		var id = getClassTypeID(type);
		if (!directImplementors.exists(id)) return [];
		return directImplementors.get(id);
	}

	public function getDoc(type:BaseType)
	{
		var id = getClassTypeID(type);
		if (!docs.exists(id)) return "<p></p>";
		return docs.get(id);
	}

	public function getDescription(type:BaseType)
	{
		var doc = getDoc(type);
		return doc.substring(0, doc.indexOf("</p>") + 4);
	}

	public function parseDoc(doc:String):String
	{
		if (doc == null) return "<p></p>";
		var orig = doc;
		var ereg = ~/^([\t ]+).+/m;
		if (ereg.match(doc))
		{
			var tabs = new EReg("^" + ereg.matched(1), "gm");
			doc = tabs.replace(doc, "");
		}
		if (doc.charAt(doc.length - 1) == "*") doc = doc.substr(0, doc.length - 1);

		doc = StringTools.trim(doc);

		return markup(doc);
	}

	public function markup(source:String):String
	{
		var process = new sys.io.Process("neko", ["markdown.n", source]);		
		var doc = process.stdout.readAll().toString();
		if (process.exitCode() != 0)
		{
			var error = process.stderr.readAll().toString();
			return '<pre>$error</pre>';
		}		
		process.close();

		doc = ~/href="(.+?)"/ig.map(doc, redirectLinks);
		doc = ~/\[([a-z\.0-9]+)\]/ig.map(doc, replaceLinks);

		return doc;
	}

	public function markupFile(path:String):String
	{
		return path;
		// var process = new sys.io.Process("haxelib", ["run", "markdown", "-f", path]);
		// if (process.exitCode() != 0)
		// {
		// 	var error = process.stderr.readAll().toString();
		// 	return '<pre>$error</pre>';
		// }

		// var doc = process.stdout.readAll().toString();
		// doc = ~/href="(.+?)"/ig.map(doc, redirectLinks);
		// doc = ~/\[([a-z\.]+)\]/ig.map(doc, replaceLinks);

		// return doc;
	}

	function redirectLinks(ereg:EReg):String
	{
		var href = ereg.matched(1);
		if (href.indexOf(".md") == -1) return ereg.matched(0);
		href = href.split(".md").join(".html");
		return 'href="$href"';
	}

	function replaceLinks(ereg:EReg):String
	{
		var id = ereg.matched(1);
		var href = resolveId(id);
		if (href == null) return '<code>$id</code>';
		else return '<code><a href="$href">$id</a></code>';
	}

	public function getClassTypeID(type:BaseType):String
	{
		return getPathString(type.pack, type.name);
	}
	
	function getPathString(pack:Array<String>, name:String, sep:String = "."):String
	{
		return (pack.length == 0 ? "" : pack.join(sep) + sep) + name;
	}
	
	function getTypePath(base:BaseType):String
	{
		return Printer.baseurl + "/" + getPathString(base.pack, base.name, "/") + ".html";
	}
	
	function resolveId(id:String)
	{
		if (typeMap.exists(id)) return getTypePath(typeMap.get(id));
		var parts = id.split(".");
		if (parts.length == 1) return null;
		var methodName = parts.pop();
		var id = parts.join(".");
		if (typeMap.exists(id)) return getTypePath(typeMap.get(id)) + "#" + methodName;
		return null;
	}
}