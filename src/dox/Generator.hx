package dox;

import Markdown;
import markdown.AST;
import markdown.InlineParser;
import haxe.rtti.CType;
using Lambda;

class Generator
{
	public static var baseurl = "/dox/pages";
	// public static var baseurl = "/dox";

	static var buf:StringBuf;
	static var nav:StringBuf;

	static var numPlatforms:Int;
	static var numGeneratedTypes(default, set) = 0;
	static var numGeneratedPackages = 0;
	
	static var subClasses = new Map<String, Array<String>>();
	static var implementors = new Map<String, Array<String>>();
	static var infos = new Map<String, TypeInfos>();

	static function set_numGeneratedTypes(v) {
		if (v & 16 == 0) Sys.print(".");
		return numGeneratedTypes = v;
	}
	
	static function main()
	{
		var parser = new haxe.rtti.XmlParser();
		var platforms = ['cpp', 'cs', 'flash8', 'flash', 'js', 'neko', 'php', 'java'];
		numPlatforms = platforms.length;
		
		for (platform in platforms)
		{
			Sys.println('Parsing $platform');
			var data = sys.io.File.getContent('bin/$platform.xml');
			var xml = Xml.parse(data).firstElement();
			if (platform == "flash8") transformPackage(xml, "flash", "flash8");
			parser.process(xml, platform);
		}

		var root = process(parser.root);
		
		function getName(t:TypeTree) {
			return switch(t) {
				case TEnumdecl(t): t.path;
				case TTypedecl(t): t.path;
				case TClassdecl(t): t.path;
				case TAbstractdecl(t): t.path;
				case TPackage(n,_,_): n;
			}
		}
	
		function compare(t1,t2) {
			return switch [t1, t2] {
				case [TPackage(n1,_,_),TPackage(n2,_,_)]: n1 < n2 ? -1 : 1;
				case [TPackage(_),_]: -1;
				case [_,TPackage(_)]: 1;
				case [t1,t2]:
					return getName(t1) < getName(t2) ? -1 : 1;
			}
		}
		
		function sort(t:TypeTree) {
			switch(t) {
				case TPackage(_, _, subs):
					subs.sort(compare);
					subs.iter(sort);
				case _:
			}
		}
		root.sort(compare); // we may not want this one
		root.iter(sort);
		root.unshift(root.pop()); // toplevel ends up last
		
		nav = new StringBuf();
		nav.add('<ul>');
		root.iter(printNavigationTree);
		nav.add('</ul>');

		sys.io.File.saveContent("pages/nav.js", "var navContent = '" + nav.toString() + "';");
		
		root.iter(printTree);
		
		Sys.println('done');
		Sys.println('Created $numGeneratedTypes types in $numGeneratedPackages packages.');
	}

	static function transformPackage(x:Xml, p1, p2)
	{
		switch( x.nodeType ) {
		case Xml.Element:
			var p = x.get("path");
			if( p != null && p.substr(0,6) == p1 + "." )
				x.set("path",p2 + "." + p.substr(6));
			for( x in x.elements() )
				transformPackage(x,p1,p2);
		default:
		}
	}

	static function process(root:TypeRoot)
	{
		Sys.println("Processing types");
		
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
				infos.set(t.path, t);
				t.doc = processDoc(t.doc);
				t.constructors.iter(processEnumField);

			case TTypedecl(t):
				infos.set(t.path, t);
				t.doc = processDoc(t.doc);

			case TClassdecl(t):
				infos.set(t.path, t);
				t.doc = processDoc(t.doc);
				t.fields.iter(processClassField);
				t.statics.iter(processClassField);
				if (t.isInterface) implementors.set(t.path, []);
				if (t.superClass != null)
				{
					if (!subClasses.exists(t.superClass.path)) subClasses.set(t.superClass.path, [t.path]);
					else subClasses.get(t.superClass.path).push(t.path);
				}
				for (i in t.interfaces)
				{
					if (!implementors.exists(i.path)) implementors.set(i.path, [t.path]);
					else implementors.get(i.path).push(t.path);
				}

			case TAbstractdecl(t):
				infos.set(t.path, t);
				if (t.impl != null)
				{
					t.impl.fields.iter(processClassField);
					t.impl.statics.iter(processClassField);
				}
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
		while (ereg.match(doc))
		{
			var tabs = new EReg("^" + ereg.matched(1), "gm");
			doc = tabs.replace(doc, "");
		}
		if (doc.charAt(doc.length - 1) == "*") doc = doc.substr(0, doc.length - 1);
		doc = StringTools.trim(doc);

		return markdownToHtml(doc);
	}
	
	static var packageDepth = 0;
	static var sysPlatform = [
		"java" => true,
		"cs" => true,
		"neko" => true,
		"php" => true,
		"cpp" => true
	];

	/**
		Generates the navigation from the type tree, called recursively on each 
		package and type.
	**/
	static function printNavigationTree(tree:TypeTree)
	{
		switch (tree)
		{
			case TPackage(name, full, subs):
				if (name.charAt(0) == '_') return;
				packageDepth += 1;

				var style = "";
				if (packageDepth == 1 && name != "top level" && name != "haxe")
				{
					style = "platform platform-" + name;
				}

				var href = full.split('.').join('/') + "/index.html";
				nav.add('<li class="expando $style"><div>');
				nav.add('<a href="#" onclick="toggleCollapsed(this)"><img src="$baseurl/triangle-closed.png"></a>');
				nav.add('<a href="$baseurl/$href">$name</a>');
				nav.add('</div>');

				nav.add('<ul>');
				subs.iter(printNavigationTree);
				nav.add('</ul>');
				nav.add('</li>');
				packageDepth -= 1;
			case _:
		}

		var type = typeInfos(tree);
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
				numGeneratedPackages++;
				
			case TTypedecl(t):
				generateType(t);
				write(t.path);
				numGeneratedTypes++;

			case TEnumdecl(t):
				generateEnum(t);
				write(t.path);
				numGeneratedTypes++;

			case TClassdecl(t):
				generateClass(t);
				write(t.path);
				numGeneratedTypes++;

			case TAbstractdecl(t):
				generateAbstract(t);
				write(t.path);
				numGeneratedTypes++;
		}
	}

	static function generatePackage(name:String, full:String, subs:Array<TypeTree>)
	{
		if (full == "") buf.add('<h1>top level</h1>');
		else buf.add('<h1><span class="directive">package</span> $full</h1>');

		buf.add('<table class="table table-condensed"><tbody>');

		for (tree in subs)
		{
			var infos = typeInfos(tree);
			if (infos == null) continue;

			var link = pathLink(infos.path);
			var desc = infos.doc.substr(0, infos.doc.indexOf('</p>') + 4);
			buf.add('<tr><td width="200">$link</td><td>$desc</td></tr>');
		}

		buf.add('</tbody></table>');
	}

	static function generateType(type:Typedef)
	{
		var link = typeParamsLink(type.path, type.params);
		var target = '';

		switch (type.type)
		{
			case CAnonymous(_):
			case _: target = ' = ' + typeLink(type.type);
		}
		
		buf.add('<h1><code><span class="directive">typedef</span> $link$target</code></h1>\n');
		printModule(type.path, type.module);
		printPlatforms(type.platforms);
		printFile(type.file);
		printDoc(type.doc);

		switch (type.type)
		{
			case CAnonymous(fields):
				printClassFields(fields, 'Instance Fields');
			case _:
		}
	}

	static function generateEnum(type:Enumdef)
	{
		var link = typeParamsLink(type.path, type.params);

		buf.add('<h1><code><span class="directive">enum</span> $link</code></h1>\n');
		printModule(type.path, type.module);
		printPlatforms(type.platforms);
		printFile(type.file);
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

	/**
		Generate documentation for a class.
	**/
	static function generateClass(type:Classdef)
	{
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

		var kind = type.isInterface ? 'interface' : 'class';
		buf.add('<h1><code><span class="directive">$kind</span> $link$api</code></h1>\n');
		printModule(type.path, type.module);
		printPlatforms(type.platforms);
		printFile(type.file);

		var subClasses = getSubClasses(type.path);
		printRelatedTypes(subClasses, "Subclasses");
		if (type.isInterface) printRelatedTypes(implementors.get(type.path), "Implementors");

		printDoc(type.doc);

		printClassFields(type.statics, "Class Fields");
		printClassFields(type.fields, "Instance Fields");
	}

	/**
		Returns all paths that subclass (directly or indirectly) a path.
	**/
	static function getSubClasses(path:String)
	{
		if (!subClasses.exists(path)) return [];
		var subs = subClasses.get(path);
		var result = subs.copy();
		for (path in subs) result = result.concat(getSubClasses(path));
		result.sort(Reflect.compare);
		return result;
	}

	/**
		Print an expandable table ot related types with a title (used for 
		implementors and subclasses)
	**/
	static function printRelatedTypes(types:Array<String>, title:String)
	{
		if (types.length == 0) return;
		
		var table = "<table class='table table-condensed'><tbody>";
		for (path in types)
		{
			var link = pathLink(path);
			var info = infos.get(path);
			var desc = info.doc.substr(0, info.doc.indexOf('</p>') + 4);
			table += '<tr><td width="200">$link</td><td>$desc</td></tr>';
		}
		table += "</tbody></table>";

		buf.add('<table class="related-types toggle" style="margin-top:16px;"><tbody>');
		buf.add('<tr><td colspan="2">$title</td></tr>');

		var links = types.map(pathLink).join(", ");
		buf.add('<tr>');
		buf.add('<td width="12" style="vertical-align:top;"><a href="#" onclick="toggleInherited(this)"><img style="padding-top:4px;" src="$baseurl/triangle-closed.png"></a></td>');
		buf.add('<td class="toggle-hide">$links</td>');
		buf.add('<td class="toggle-show">$table</td>');
		buf.add('</tr>');
		
		buf.add("</tbody></table>");
	}

	/**
		Print documentation a group of class fields with a title (eg. statics, 
		instance fields)
	**/
	static function printClassFields(fields:List<ClassField>, title:String)
	{
		var fields = fields.filter(function(field){ return field.isPublic; });
		if (fields.length == 0) return;
		
		buf.add('<h2>$title</h2>\n');
		var fields = fields.array();
		fields.sort(function(cf1, cf2) return cf1.name == "new" ? -1 : cf2.name == "new" ? 1 : cf1.name < cf2.name ? -1 : 1);
		for (field in fields) printClassField(field);
	}

	static function getPlatformClass(platforms:List<String>)
	{
		if (platforms.isEmpty()) return "";
		return "platform " + platforms.map(function(p){ return "platform-"+p; }).join(" ");
	}

	/**
		Print an individual class field.
	**/
	static function printClassField(field:ClassField)
	{
		var name = field.name;
		
		var platformClass = getPlatformClass(field.platforms);
		buf.add('<span class="$platformClass">\n');

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
		if (field.platforms.length < numPlatforms && field.platforms.length > 0) printPlatforms(field.platforms);
		printDoc(field.doc);
		
		buf.add("<hr/></span>");
	}

	static function generateAbstract(type:Abstractdef)
	{
		var link = typeParamsLink(type.path, type.params);

		buf.add('<h1><code><span class="directive">abstract</span> $link</code></h1>\n');
		printModule(type.path, type.module);
		printPlatforms(type.platforms);
		printFile(type.file);
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

		buf.add('<div><code class="dark"><span class="macro">Available on ');
		if (platforms.length == numPlatforms)
		{
			buf.add('all platforms');
		}		
		else if (platforms.length > 1)
		{
			buf.add(platforms.join(", "));
		}
		else
		{
			buf.add(platforms.join(""));
		}
		buf.add('</span></code></div>\n');
	}
	
	static function printFile(file:String)
	{
		buf.add('<div><code class="dark"><span class="macro">Defined in $file</span></code></div>\n');
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
			case CEnum(path, params):
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

	static function typeInfos(type:TypeTree)
	{
		var infos:TypeInfos = null;
		switch (type)
		{
			case TPackage(_, _, _):
			case TTypedecl(t): infos = t;
			case TEnumdecl(t): infos = t;
			case TClassdecl(t): infos = t;
			case TAbstractdecl(t): infos = t;
		}
		return infos;
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
		<script type="text/javascript" src="$baseurl/nav.js"></script>
		<script type="text/javascript" src="$baseurl/index.js"></script>
	</head>
	<body>
		<div class="container-fluid">
			<div class="navbar navbar-inverse navbar-fixed-top">
				<div class="navbar-inner">
					<form class="navbar-search pull-left">
						<input type="text" class="search-query" placeholder="Search">
					</form>
					<ul class="nav">
						<li id="select-version" class="dropdown">
							<a href="#" class="dropdown-toggle" data-toggle="dropdown">Version<b class="caret"></b></a>
							<ul class="dropdown-menu">
								<li data="3_0"><a href="#">3.0</a></li>
								<li data="3_1"><a href="#">3.1</a></li>
								<li data="3_2"><a href="#">3.2</a></li>
							</ul>
						</li>
					</ul>
					<ul class="nav">
						<li id="select-platform" class="dropdown">
							<a href="#" class="dropdown-toggle" data-toggle="dropdown">Platform<b class="caret"></b></a>
							<ul class="dropdown-menu">
								<li data="all"><a href="#">All Platforms</a></li>
								<li data="sys"><a href="#">System</a></li>
								<li data="neko"><a href="#">Neko</a></li>
								<li data="php"><a href="#">PHP</a></li>
								<li data="java"><a href="#">Java</a></li>
								<li data="cs"><a href="#">C Sharp</a></li>
								<li data="flash8"><a href="#">Flash 8</a></li>
								<li data="flash"><a href="#">Flash 9+</a></li>
								<li data="js"><a href="#">Javascript</a></li>
							</ul>
						</li>
					</ul>
				</div>
			</div>
			<div class="row-fluid">
				<div class="packages" id="nav"></div>
				<div class="content">${buf.toString()}</div>
			</div>
		</div>
	</body>
</html>';

	static function markdownToHtml(markdown:String)
	{
		// create document
		var document = new Document();
		document.inlineSyntaxes.push(new MagicCodeSyntax());

		// replace windows line endings with unix, and split
		var lines = ~/\n\r/g.replace(markdown, '\n').split("\n");

		// parse ref links
		document.parseRefLinks(lines);

		// parse ast
		var blocks = document.parseLines(lines);
		return Markdown.renderHtml(blocks);
	}

	public static function processCode(source:String)
	{
		source = StringTools.htmlEscape(source);

		// this.field => #field
		source = ~/this\.(\w+)/g.map(source, function(e){
			var field = e.matched(1);
			return 'this.<a href="#$field">$field</a>';
		});

		// Type, pack.Type, pack.Type.field => pack/Type.html#field
		source = ~/\b((\w+\.)*[A-Z]\w+)(\.\w+)*\b/g.map(source, function(e){
			var text = e.matched(0);
			var type =  e.matched(1);
			var field = e.matched(3);
			var href = resolveTypeLink(type, field);
			return '<a href="$href">$text</a>';
		});

		// Type, null => /Null.html
		source = ~/null/g.map(source, function(e){
			var href = resolveTypeLink("Null");
			return '<a href="$href">null</a>';
		});
		
		// Sys.println(source);
		return source;
	}

	static function resolveTypeLink(type:String, ?field:String)
	{
		if (field == null) return pathHref(type);
		field = field.substr(1);
		return pathHref(type) + "#" + field;
	}
}

class MagicCodeSyntax extends CodeSyntax
{
	public function new()
	{
		super('`([^`]*)`');
	}

	override function onMatch(parser:InlineParser):Bool
	{
		var source = pattern.matched(1);
		parser.addNode(ElementNode.text('code', Generator.processCode(source)));
		return true;
	}
}
