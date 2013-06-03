package dox;

import haxe.rtti.CType;
using Lambda;

class GeneratorXml
{
	public static var baseurl = "/pages";

	static var buf:StringBuf;
	static var nav:StringBuf;

	static function main()
	{
		var parser = new haxe.rtti.XmlParser();
		
		for (platform in ['cpp', 'cs', 'flash8', 'flash9', 'js', 'neko', 'php']) // api difference in java?
		{
			// Sys.println('Parsing $platform');
			var data = sys.io.File.getContent('bin/$platform.xml');
			parser.process(Xml.parse(data).firstElement(), platform);
		}

		var root = process(parser.root);

		nav = new StringBuf();
		nav.add('<ul>');
		root.iter(printNavigationTree);
		nav.add('</ul>');

		root.iter(printTree);
	}

	static function process(root:TypeRoot)
	{
		// Sys.println("Processing types");
		
		var rootTypes = [];
		var rootPack = TPackage('top level', '', rootTypes);
		var newRoot = [rootPack];

		for (tree in root) switch (tree)
		{
			case TPackage(_,_,_): newRoot.push(tree);
			default: rootTypes.push(tree);
		}

		newRoot.iter(processTree);
		return newRoot;
	}

	static function processTree(tree:TypeTree)
	{
		switch (tree)
		{
			case TPackage(_, _, subs):
				subs.iter(processTree);
			case TEnumdecl(t):
				t.doc = processDoc(t.doc);
				t.constructors.iter(processEnumField);
			case TTypedecl(t):
				t.doc = processDoc(t.doc);
			case TClassdecl(t):
				t.doc = processDoc(t.doc);
				t.fields.iter(processClassField);
				t.statics.iter(processClassField);
			case TAbstractdecl(t):
				t.doc = processDoc(t.doc);
		}
	}

	static function processClassField(field:ClassField)
	{
		field.doc = processDoc(field.doc);
	}

	static function processEnumField(field:EnumField)
	{
		field.doc = processDoc(field.doc);
	}

	static function processDoc(doc:String)
	{
		if (doc == null || doc == '') return '<p></p>';
		
		var ereg = ~/^([\t ]+).+/m;
		if (ereg.match(doc))
		{
			var tabs = new EReg("^" + ereg.matched(1), "gm");
			doc = tabs.replace(doc, "");
		}
		if (doc.charAt(doc.length - 1) == "*") doc = doc.substr(0, doc.length - 1);
		doc = StringTools.trim(doc);

		return Markdown.markdownToHtml(doc);
	}

	/**
		Generates the navigation from the type tree, called recursively on each 
		package and type.
	**/
	static function printNavigationTree(tree:TypeTree)
	{
		var type:{path:String, isPrivate:Bool} = null;

		switch (tree)
		{
			case TPackage(name, full, subs):
				if (name.charAt(0) == '_') return;

				var href = full.split('.').join('/');
				nav.add('<li class="expando"><div>');
				nav.add('<a href="#" onclick="toggleCollapsed(this)"><img src="$baseurl/triangle-closed.png"></a>');
				nav.add('<a href="$baseurl/$href">$name</a>');
				nav.add('</div>');

				nav.add('<ul>');
				subs.iter(printNavigationTree);
				nav.add('</ul>');
				nav.add('</li>');

			case TEnumdecl(t): type = t;
			case TTypedecl(t): type = t;
			case TClassdecl(t): type = t;
			case TAbstractdecl(t): type = t;
		}

		if (type == null || type.isPrivate) return;
		
		var parts = type.path.split(".");
		var href = parts.join('/') + ".html";
		var name = parts.pop();
		nav.add('<li><div><a href="$baseurl/$href">$name</a></div></li>');
	}

	/**
		Generates documentation for part of the type tree: either a package 
		summary page or type page.
	**/
	static function printTree(tree:TypeTree)
	{
		buf = new StringBuf();

		switch (tree)
		{
			case TPackage(name, full, subs):
				if (name.charAt(0) == '_') return;

				generatePackage(name, full, subs);
				write(full == '' ? 'index' : full + '.index');

				subs.iter(printTree);
			case TTypedecl(t):
				generateType(t);
				write(t.path);

			case TEnumdecl(t):
				generateEnum(t);
				write(t.path);

			case TClassdecl(t):
				generateClass(t);
				write(t.path);

			case TAbstractdecl(t):
				generateAbstract(t);
				write(t.path);
		}
	}

	static function generatePackage(name:String, full:String, subs:Array<TypeTree>)
	{
		if (full == "") buf.add('<h1>top level<h1>');
		else buf.add('<h1><span class="directive">package</span> $full</h1>');

		buf.add('<table class="table table-condensed"><tbody>');

		for (tree in subs)
		{
			var base = baseType(tree);
			if (base == null) continue;

			var link = pathLink(base.path);
			var desc = base.doc.substr(0, base.doc.indexOf('</p>') + 4);
			buf.add('<tr><td width="200">$link</td><td>$desc</td></tr>');
		}

		buf.add('</tbody></table>');
	}

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
				var args = args.array();
				if (isImpl(field)) args.shift();
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

		if (type.impl != null)
		{
			var impl = type.impl;
			var fields = new List();
			var statics = new List();
			for (field in impl.statics)
			{
				if (isImpl(field)) {
					if (field.name == "_new") field.name = "new";
					fields.add(field);
				}
				else statics.add(field);
			}
			printClassFields(statics, "Class Fields");
			printClassFields(fields, "Instance Fields");
		}
	}

	static function isImpl(field:ClassField)
	{
		return field.meta.exists(function(m) { return m.name == ":impl"; });
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
				nameParamsLink(path, params);
			case CAbstract(path, params):
				nameParamsLink(path, params);
			case CTypedef(path, params):
				nameParamsLink(path, params);
			case _:
				StringTools.htmlEscape(Std.string(type));
		}
	}

	static function nameParamsLink(path:String, params:List<CType>)
	{
		path = pathLink(path);
		var params = params.map(typeLink).array();
		if (params.length == 0) return path;
		return path + '&lt;' + params.join(", ") + '&gt;';
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
		params = params.map(pathLink);
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
		var name = path.split(".").pop();
		if (name.length == 1) return '<span class="type">$name</span>';
		
		var href = pathHref(path);
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
		path = 'pages/' + path.split('.').join('/') + '.html';

		var html = getHtml();
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
		// Sys.println('Generated $path');
	}

	static function baseType(type:TypeTree)
	{
		var base:{doc:String, path:String} = null;
		switch (type)
		{
			case TPackage(_, _, _):
			case TTypedecl(t): base = t;
			case TEnumdecl(t): base = t;
			case TClassdecl(t): base = t;
			case TAbstractdecl(t): base = t;
		}
		return base;
	}

	static function getHtml() return 
'<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8"> 
		<link href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
		<script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
		<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
		<link href="$baseurl/styles.css" rel="stylesheet">
		<script type="text/javascript">var baseUrl = "$baseurl";</script>
		<script type="text/javascript" src="$baseurl/index.js"></script>
	</head>
	<body>
		<div class="container-fluid">
			<div class="navbar navbar-inverse navbar-fixed-top">
				<div class="navbar-inner">
					<ul class="nav">
						<li class="active"><a href="#">API</a></li>
					</ul>
				</div>
			</div>
			<div class="row-fluid">
				<div class="packages">${nav.toString()}</div>
				<div class="content">${buf.toString()}</div>
			</div>
		</div>
	</body>
</html>';
}
