package dox;

import haxe.rtti.CType;
using Lambda;

class GeneratorXml
{
	public static var baseurl = "/dox/pages2";

	static var buf:StringBuf;
	static var nav:StringBuf;

	static function main()
	{
		var parser = new haxe.rtti.XmlParser();
		
		for (platform in ['cpp', 'cs', 'flash8', 'flash9', 'js', 'neko', 'php']) // api difference in java?
		{
			Sys.println('Loading $platform');
			var data = sys.io.File.getContent('xml/$platform.xml');
			parser.process(Xml.parse(data).firstElement(), platform);
		}

		nav = new StringBuf();
		parser.root.iter(printNavigation.bind(_, null));
		parser.root.iter(printTree);
	}

	/**
		Generates the navigation from the type tree, called recursively on each 
		package and type.
	**/
	static function printNavigation(tree:TypeTree, ?pack:String)
	{
		var path:String;

		switch (tree)
		{
			case TPackage(name, full, subs):
				if (pack != null)
				{
					var href = full.split('.').join('/');
					nav.add('<li class="expando"><div>');
					nav.add('<a href="#" onclick="toggleCollapsed(this)"><img src="$baseurl/triangle-closed.png"></a>');
					nav.add('<a href="$baseurl/$href">$name</a>');
					nav.add('</div>');
				}

				nav.add('<ul>');
				subs.iter(printNavigation.bind(_, full));
				nav.add('</ul>');

				if (pack != null) nav.add('</li>');

			case TEnumdecl(t): path = t.path;
			case TTypedecl(t): path = t.path;
			case TClassdecl(t): path = t.path;
			case TAbstractdecl(t): path = t.path;
		}

		if (path != null)
		{
			var parts = path.split(".");
			var href = parts.join('/') + ".html";
			var name = parts.pop();
			nav.add('<li><div><a href="$baseurl/$href">$name</a></div></li>');
		}
	}

	/**
		Generates documentation for part of the type tree: either a package 
		summary page or type page.
	**/
	static function printTree(tree:TypeTree)
	{
		var path:String;
		buf = new StringBuf();

		switch (tree)
		{
			case TPackage(name, full, subs):
				path = full;
				generatePackage(name, full, subs);
				subs.iter(printTree);
			case TTypedecl(t):
				path = t.path;
				generateType(t);
			case TEnumdecl(t):
				path = t.path;
				generateEnum(t);
			case TClassdecl(t):
				path = t.path;
				generateClass(t);
			case TAbstractdecl(t):
				path = t.path;
				generateAbstract(t);
		}

		write(path);
	}

	static function generatePackage(name:String, full:String, subs:Array<TypeTree>)
	{

	}

	// public function printPack(pack:String)
	// {
	// 	buf = new StringBuf();

	// 	if (pack == "") buf.add('<h1>top level<h1>');
	// 	else buf.add('<h1><span class="directive">package</span> $pack</h1>');
		
	// 	var interfaces:Array<BaseType> = [];
	// 	var classes:Array<BaseType> = [];
	// 	var enums:Array<BaseType> = [];
	// 	var typedefs:Array<BaseType> = [];
	// 	var abstracts:Array<BaseType> = [];
	// 	var types = model.packages.get(pack);

	// 	for (type in types)
	// 	{
	// 		switch (type)
	// 		{
	// 			case TInst(t,_):
	// 				var ref = t.get();
	// 				if (ref.isInterface) interfaces.push(ref);
	// 				else classes.push(ref);
	// 			case TEnum(t,_):
	// 				enums.push(t.get());
	// 			case TType(t,_):
	// 				typedefs.push(t.get());
	// 			case TAbstract(t,_):
	// 				abstracts.push(t.get());
	// 			case _:
	// 		}
	// 	}

	// 	printPackTypes(interfaces, "Interfaces");
	// 	printPackTypes(classes, "Classes");
	// 	printPackTypes(typedefs, "Type Definitions");
	// 	printPackTypes(enums, "Enums");
	// 	printPackTypes(abstracts, "Abstracts");
	// }

	// function printPackTypes(types:Array<BaseType>, title:String)
	// {
	// 	if (types.length == 0) return;

	// 	buf.add('<h2>$title</h2>');
	// 	buf.add('<table class="table table-condensed"><tbody>');
	// 	for (type in types)
	// 	{
	// 		var link = baseTypeLink(type);
	// 		var desc = model.getDescription(type);
	// 		buf.add('<tr><td width="200">$link</td><td>$desc</td></tr>');
	// 	}
	// 	buf.add('</tbody></table>');
	// }

	static function generateType(type:Typedef)
	{
		var kind = 'typedef';
		var link = typeParamsLink(type.path, type.params);

		buf.add('<h1><code><span class="directive">$kind</span> $link</code></h1>\n');
		printPlatforms(type.platforms);
		printModule(type.path, type.module);
		printDoc(type.doc);

		switch (type.type)
		{
			case CAnonymous(fields):
				printClassFields(fields, "Instance Fields");
			case _:
		}
	}

	static function generateEnum(type:Enumdef)
	{
		var kind = 'enum';
		var link = typeParamsLink(type.path, type.params);

		buf.add('<h1><code><span class="directive">$kind</span> $link</code></h1>\n');
		printPlatforms(type.platforms);
		printModule(type.path, type.module);
		printDoc(type.doc);

		if (type.constructors.array().length > 0)
		{
			buf.add('<h2>Constructs:</h2>\n');
			for (field in type.constructors) printEnumField(field);
		}
	}

	static function printEnumField(field:EnumField)
	{
		var name = field.name;
		
		if (field.args == null)
		{
			buf.add('<h3><code><a name="$name" href="#$name"><span class="type">$name</span></a></code></h3>\n');
		}
		else
		{
			var argLinks = field.args.map(argLink).join(", ");
			if (argLinks.length > 0) argLinks = '($argLinks)';
			buf.add('<h3><code><a name="$name" href="#$name"><span class="type">$name</span></a>$argLinks</code></h3>\n');
		}

		printDoc(field.doc);
	}

	static function generateClass(type:Classdef)
	{
		var kind = type.isInterface ? 'interface' : 'class';
		var link = typeParamsLink(type.path, type.params);
		var api = "";

		if (type.superClass != null)
		{
			var link = pathParamsLink(type.superClass);
			api += ' <span class="keyword">extends</span> $link';
		}

		for (type in type.interfaces)
		{
			var link = pathParamsLink(type);
			api += ' <span class="keyword">implements</span> $link';
		}

		buf.add('<h1><code><span class="directive">$kind</span> $link$api</code></h1>\n');
		printPlatforms(type.platforms);
		printModule(type.path, type.module);

		// printRelatedTypes(model.getDirectSubclasses(type), "Direct Subclasses");
		// printRelatedTypes(model.getIndirectSubclasses(type), "Indirect Subclasses");
		// printRelatedTypes(model.getDirectImplementors(type), "Direct Implementors");

		printDoc(type.doc);

		printClassFields(type.statics, "Class Fields");
		printClassFields(type.fields, "Instance Fields");
	}

	static function printClassFields(fields:List<ClassField>, title:String)
	{
		var fields = fields.filter(function(field){ return field.isPublic; });
		if (fields.length == 0) return;
		
		buf.add('<h2>$title</h2>\n');
		for (field in fields) printClassField(field);
	}

	static function printClassField(field:ClassField)
	{
		var name = field.name;
		
		switch (field.type)
		{
			case CFunction(args, ret):
				// if (field.meta.has(":impl")) args.shift();
				var argLinks = args.map(argLink).join(", ");
				var retLink = typeLink(ret);
				var paramLinks = paramsLink(field.params);
				buf.add('<a name="$name"></a><h3><code><span class="keyword">function</span> <a name="$name" href="#$name"><span class="identifier">$name</span></a>$paramLinks($argLinks):$retLink;</code></h3>\n');

			case _:
				var link = typeLink(field.type);
				var readonly = field.get == RInline || field.set == RNo;
				var access = readonly ? '<span class="comment"> // readonly</span>' : '';
				buf.add('<h3><code><span class="keyword">var</span> <a name="$name" href="#$name"><span class="identifier">$name</span></a>:$link;$access</code></h3>\n');
		}
		
		printDoc(field.doc);
	}

	static function generateAbstract(type:Abstractdef)
	{
		var kind = 'abstract';
		var link = typeParamsLink(type.path, type.params);

		buf.add('<h1><code><span class="directive">$kind</span> $link</code></h1>\n');
		printPlatforms(type.platforms);
		printModule(type.path, type.module);
		printDoc(type.doc);
		
		// if (type.impl != null)
		// {
		// 	var impl = type.impl.get();
		// 	var fields = [];
		// 	var statics = [];
		// 	for (field in impl.statics.get())
		// 	{
		// 		if (field.meta.has(":impl")) {
		// 			if (field.name == "_new") field.name = "new";
		// 			fields.push(field);
		// 		}
		// 		else statics.push(field);
		// 	}
		// 	printClassFields(statics, "Class Fields");
		// 	printClassFields(fields, "Instance Fields");
		// }
	}

	static function printModule(path:String, module:String)
	{
		if (module == null || module == 'StdTypes' || module == path) return;
		buf.add('<div><code class="dark"><span class="directive">import</span> <span class="type">$module</span>;</code></div>\n');
	}

	static function printPlatforms(platforms:List<String>)
	{
		var platforms = platforms.array();

		if (platforms.length > 1)
		{
			buf.add('<div><code class="dark"><span class="macro">#if (${platforms.join(" || ")})</span></code></div>\n');
		}
		else
		{
			buf.add('<div><code class="dark"><span class="macro">#if ${platforms.join("")}</span></code></div>\n');
		}
	}

	static function printDoc(doc:String)
	{
		if (doc == null) return;
		buf.add('<div class="doc">$doc</div>\n');
	}

	static function typeLink(type:CType)
	{
		return switch (type)
		{
			case CFunction(args, ret): 
				args.map(argType).concat([ret]).map(typeLink).join(" -> ");
			case CDynamic(_):
				'<a href="$baseurl/Dynamic.html"><span class="type">Dynamic</span></a>';
			case CAnonymous(fields):
				"{ "+fields.map(fieldLink).join(", ")+" }";
			case CClass(path, params):
				pathLink(path);
			case CAbstract(path, params):
				pathLink(path);
			case _:
				StringTools.htmlEscape(Std.string(type));
		}

		// don't link type params
		// switch (type)
		// {
		// 	case TInst(t,_):
		// 		var ref = t.get();
		// 		switch (ref.kind)
		// 		{
		// 			case KTypeParameter(_):
		// 				return '<span class="type">${base.name}</span>';
		// 			default:
		// 		}
		// 	default:
		// }

		// var link = baseTypeLink(base);

		// switch (type)
		// {
		// 	case TType(_, params), TInst(_, params), TEnum(_, params), TAbstract(_, params):
		// 		link += paramsLink(params);
		// 	case _:
		// }

		// return link;
	}

	static function argType(arg:{t:CType, opt:Bool, name:String})
	{
		return arg.t;
	}

	static function fieldLink(field:ClassField):String
	{
		return field.name + ":" + typeLink(field.type);
	}

	static function argLink(arg:{t:CType, opt:Bool, name:String})
	{
		var opt = arg.opt ? '?' : '';
		var name = arg.name;
		var link = typeLink(arg.t);
		return '$opt<span class="identifier">$name</span>:$link';
	}

	static function paramsLink(params:Array<String>):String
	{
		if (params == null || params.length == 0) return "";
		return "&lt;" + params.join(", ") + "&gt;";
	}

	static function typeParamsLink(path:String, params:TypeParams)
	{
		var path = pathLink(path);
		if (params == null || params.length == 0) return path;

		var paramLinks = params.map(pathLink);
		return path + "&lt;" + paramLinks.join(", ") + "&gt;";
	}

	static function pathParamsLink(params:PathParams)
	{
		var path = pathLink(params.path);
		if (params.params == null || params.params.length == 0) return path;

		var paramLinks = params.params.map(typeLink);
		return path + "&lt;" + paramLinks.join(", ") + "&gt;";
	}

	/**
		Convers a type path into an anchor link.
	**/
	static function pathLink(path:String):String
	{
		var href = pathHref(path);
		var name = path.split(".").pop();
		return '<a href="$href"><span class="type">$name</span></a>';
	}

	/**
		Converts a type path into a url.
	**/
	static function pathHref(path:String)
	{
		return baseurl + "/" + path.split(".").join("/") + ".html";
	}

	/**
		Write the page to path.
	**/
	static function write(path:String)
	{
		path = 'pages2/' + path.split('.').join('/') + '.html';

		var html = Template.page(baseurl, nav.toString(), buf.toString());
		var parts = path.split("/");
		var current = [];
		while (parts.length > 1)
		{
			current.push(parts.shift());
			var dir = current.join("/");
			if (sys.FileSystem.exists(dir)) continue;
			sys.FileSystem.createDirectory(dir);
		}
		sys.io.File.saveContent(path, html);
		Sys.println('Generated $path');
	}

	/*
	function printRelatedTypes(types:Array<ClassType>, title:String)
	{
		if (types.length == 0) return;
		
		var table = "<table class='table table-condensed'><tbody>";
		for (type in types)
		{
			var link = baseTypeLink(type);
			var desc = model.getDescription(type);
			table += '<tr><td width="200">$link</td><td>$desc</td></tr>';
		}
		table += "</tbody></table>";

		buf.add('<table class="related-types toggle" style="margin-top:16px;"><tbody>');
		buf.add('<tr><td colspan="2">$title</td></tr>');

		var links = types.map(baseTypeLink).join(", ");
		buf.add('<tr>');
		buf.add('<td width="12" style="vertical-align:top;"><a href="#" onclick="toggleInherited(this)"><img style="padding-top:4px;" src="$baseurl/triangle-closed.png"></a></td>');
		buf.add('<td class="toggle-hide">$links</td>');
		buf.add('<td class="toggle-show">$table</td>');
		buf.add('</tr>');
		
		buf.add("</tbody></table>");
	}
	*/
}