package dox;

import haxe.rtti.CType;

using Lambda;

class Printer {
	var api:Api;
	var buf:StringBuf;
	var packageDepth:Int;
	var nav:StringBuf;
	
	public function new(api:Api) {
		this.api = api;
		packageDepth = 0;
		buf = new StringBuf();
		nav = new StringBuf();
	}
	
	public function generate(root:TypeRoot) {
		root.iter(generateTree);
	}
	
	function generateTree(tree:TypeTree)
	{
		buf = new StringBuf();

		switch (tree)
		{
			case TPackage(name, full, subs):
				if (name.charAt(0) == '_') return;

				generatePackage(name, full, subs);
				write(full == '' ? 'index' : full + '.index');

				subs.iter(generateTree);
				api.infos.numGeneratedPackages++;

			case TTypedecl(t):
				generateType(t);
				write(t.path);
				api.infos.numGeneratedTypes++;

			case TEnumdecl(t):
				generateEnum(t);
				write(t.path);
				api.infos.numGeneratedTypes++;

			case TClassdecl(t):
				generateClass(t);
				write(t.path);
				api.infos.numGeneratedTypes++;

			case TAbstractdecl(t):
				generateAbstract(t);
				write(t.path);
				api.infos.numGeneratedTypes++;
		}
	}
	
	public function generateNavigation(tree:TypeRoot) {
		tree.iter(printNavigationTree);
		sys.io.File.saveContent(api.config.outputPath + "nav.js", 'var navContent =\'${nav.toString()}\';');
	}
	
	function printNavigationTree(tree:TypeTree)
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
				nav.add('<a href="#" onclick="toggleCollapsed(this)"><img src="${api.config.rootPath}triangle-closed.png"></a>');
				nav.add('<a href="${api.config.rootPath}$href">$name</a>');
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
		nav.add('<li><div><a href="${api.config.rootPath}$href">$name</a></div></li>');
	}
	
	function write(path:String)
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
	
	function printFile(file:String)
	{
		buf.add('<div><code class="dark"><span class="macro">Defined in $file</span></code></div>\n');
	}

	function printDoc(doc:String)
	{
		if (doc == null) return;
		buf.add('<div class="doc">$doc</div>\n');
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
	
	function generatePackage(name:String, full:String, subs:Array<TypeTree>)
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

	
	function paramsLink(params:Array<String>):String
	{
		if (params == null || params.length == 0) return "";
		params = params.map(pathLink);
		return "&lt;" + params.join(", ") + "&gt;";
	}

	function typeParamsLink(path:String, params:TypeParams)
	{
		var path = pathLink(path);
		if (params == null || params.length == 0) return path;

		var paramLinks = params.map(pathLink);
		return path + "&lt;" + paramLinks.join(", ") + "&gt;";
	}

	function typeLink(type:CType)
	{
		return switch (type)
		{
			case CFunction(args, ret):
				args.map(argType).concat([ret]).map(typeLink).join(" -> ");
			case CDynamic(_):
				'<a href="${api.config.rootPath}Dynamic.html"><span class="type">Dynamic</span></a>';
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

	function nameParamsLink(path:String, params:List<CType>)
	{
		path = pathLink(path);
		var params = params.map(typeLink).array();
		if (params.length == 0) return path;
		return path + '&lt;' + params.join(", ") + '&gt;';
	}

	function argType(arg:{t:CType, opt:Bool, name:String})
	{
		return arg.t;
	}

	function fieldLink(field:ClassField):String
	{
		return field.name + ":" + typeLink(field.type);
	}

	function argLink(arg:{t:CType, opt:Bool, name:String})
	{
		var opt = arg.opt ? '?' : '';
		var name = arg.name;
		var link = typeLink(arg.t);
		return '$opt<span class="identifier">$name</span>:$link';
	}
	
	function pathParamsLink(params:PathParams)
	{
		var path = pathLink(params.path);
		if (params.params == null || params.params.length == 0) return path;

		var paramLinks = params.params.map(typeLink);
		return path + "&lt;" + paramLinks.join(", ") + "&gt;";
	}
	
	function pathLink(path:String):String
	{
		var name = path.split(".").pop();
		if (name.length == 1) return '<span class="type">$name</span>';

		var href = pathHref(path);
		return '<a href="$href"><span class="type">$name</span></a>';
	}

	/**
		Converts a type path into a url.
	**/
	function pathHref(path:String)
	{
		return api.config.rootPath + path.split(".").join("/") + ".html";
	}
	
	function generateType(type:Typedef)
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

	function generateEnum(type:Enumdef)
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

	function printEnumField(field:EnumField)
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
	function generateClass(type:Classdef)
	{
		var link = typeParamsLink(type.path, type.params);
		var apiString = "";

		if (type.superClass != null)
		{
			var link = pathParamsLink(type.superClass);
			apiString += ' <span class="keyword">extends</span> $link';
		}

		for (type in type.interfaces)
		{
			var link = pathParamsLink(type);
			apiString += ' <span class="keyword">implements</span> $link';
		}

		var kind = type.isInterface ? 'interface' : 'class';
		buf.add('<h1><code><span class="directive">$kind</span> $link$apiString</code></h1>\n');
		printModule(type.path, type.module);
		printPlatforms(type.platforms);
		printFile(type.file);

		var subClasses = getSubClasses(type.path);
		printRelatedTypes(subClasses, "Subclasses");
		if (type.isInterface) printRelatedTypes(api.infos.implementors.get(type.path), "Implementors");

		printDoc(type.doc);

		printClassFields(type.statics, "Class Fields");
		printClassFields(type.fields, "Instance Fields");
	}

	function getHtml() return
'<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<link href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
		<script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
		<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
		<link href="${api.config.rootPath}styles.css" rel="stylesheet">
		<script type="text/javascript">var rootPath = "${api.config.rootPath}";</script>
		<script type="text/javascript" src="${api.config.rootPath}nav.js"></script>
		<script type="text/javascript" src="${api.config.rootPath}index.js"></script>
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

	/**
		Returns all paths that subclass (directly or indirectly) a path.
	**/
	function getSubClasses(path:String)
	{
		if (!api.infos.subClasses.exists(path)) return [];
		var subs = api.infos.subClasses.get(path);
		var result = subs.copy();
		for (path in subs) result = result.concat(getSubClasses(path));
		result.sort(Reflect.compare);
		return result;
	}

	/**
		Print an expandable table ot related types with a title (used for
		implementors and subclasses)
	**/
	function printRelatedTypes(types:Array<String>, title:String)
	{
		if (types.length == 0) return;

		var table = "<table class='table table-condensed'><tbody>";
		for (path in types)
		{
			var link = pathLink(path);
			var info = api.infos.typeMap.get(path);
			var desc = info.doc.substr(0, info.doc.indexOf('</p>') + 4);
			table += '<tr><td width="200">$link</td><td>$desc</td></tr>';
		}
		table += "</tbody></table>";

		buf.add('<table class="related-types toggle" style="margin-top:16px;"><tbody>');
		buf.add('<tr><td colspan="2">$title</td></tr>');

		var links = types.map(pathLink).join(", ");
		buf.add('<tr>');
		buf.add('<td width="12" style="vertical-align:top;"><a href="#" onclick="toggleInherited(this)"><img style="padding-top:4px;" src="${api.config.rootPath}triangle-closed.png"></a></td>');
		buf.add('<td class="toggle-hide">$links</td>');
		buf.add('<td class="toggle-show">$table</td>');
		buf.add('</tr>');

		buf.add("</tbody></table>");
	}

	/**
		Print documentation a group of class fields with a title (eg. statics,
		instance fields)
	**/
	function printClassFields(fields:List<ClassField>, title:String)
	{
		var fields = fields.filter(function(field){ return field.isPublic; });
		if (fields.length == 0) return;

		buf.add('<h2>$title</h2>\n');
		var fields = fields.array();
		fields.sort(function(cf1, cf2) return cf1.name == "new" ? -1 : cf2.name == "new" ? 1 : cf1.name < cf2.name ? -1 : 1);
		for (field in fields) printClassField(field);
	}

	function getPlatformClass(platforms:List<String>)
	{
		if (platforms.isEmpty()) return "";
		return "platform " + platforms.map(function(p){ return "platform-"+p; }).join(" ");
	}

	/**
		Print an individual class field.
	**/
	function printClassField(field:ClassField)
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
		if (field.platforms.length < api.config.platforms.length && field.platforms.length > 0) printPlatforms(field.platforms);
		printDoc(field.doc);

		buf.add("<hr/></span>");
	}

	function generateAbstract(type:Abstractdef)
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

	function printModule(path:String, module:String)
	{
		if (module == null || module == 'StdTypes' || module == path) return;
		buf.add('<div><code class="dark"><span class="directive">import</span> <span class="type">$module</span>;</code></div>\n');
	}

	function printPlatforms(platforms:List<String>)
	{
		var platforms = platforms.array();

		buf.add('<div><code class="dark"><span class="macro">Available on ');
		if (platforms.length == api.config.platforms.length)
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
}