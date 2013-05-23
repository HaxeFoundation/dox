package dox;

using dox.TypeTools;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Type;
using haxe.macro.Tools;
using Lambda;
using StringTools;

class Printer
{
	public static var baseurl = "C:\\Users\\simn\\Documents\\GitHub\\dox\\pages";

	var model:Model;
	var buf:StringBuf;
	var nav:String;

	public function new(model:Model)
	{
		this.model = model;
		buf = new StringBuf();

		nav = "";

		var packs = [for (key in model.packages.keys()) key];
		packs.sort(Reflect.compare);
		for (pack in packs)
		{
			var parts = pack.split(".");
			if (parts.length == 1 && parts[0] == "") parts = [];
			parts.push("index.html");

			var href = parts.join("/");
			if (pack == "") pack = "top level";
			nav += '<li><a href="$baseurl/$href">$pack</a></li>\n';
		}
	}

	public function printType(type:Type)
	{
		var base = type.toBaseType();

		// only document base types (no anon, mono, fun)
		if (base == null) return;

		// reset buffer
		buf = new StringBuf();

		// print the heading
		var kind = typeKind(type);
		var link = typeLink(type);
		buf.add('<h1><span class="d">$kind</span> $link</h1>\n');

		switch (type)
		{
			case TType(t,_): printDef(t.get());
			case TInst(t,_): printClass(t.get());
			case TEnum(t,_): printEnum(t.get());
			case TAbstract(t,_): printAbstract(t.get());
			case _:
		}
	}

	function html(body) return
'<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8"> 
		<link href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
		<script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
		<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
		<link href="$baseurl/styles.css" rel="stylesheet">
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
				<div class="packages">$nav</div>
				<div class="content">$body</div>
			</div>
		</div>
	</body>
</html>';
	
	public function getHtml():String
	{
		return html(buf.toString());
	}

	public function getString():String
	{
		return buf.toString();
	}

	function printClass(type:ClassType)
	{
		if (type.superClass != null)
		{
			var link = refLink(type.superClass);
			buf.add('<div>extends $link</div>\n');
		}

		if (type.interfaces.length > 0)
		{
			var links = type.interfaces.map(refLink).join(" ");
			buf.add('<div>implements $links</div>\n');
		}

		printRelatedTypes(model.getDirectSubclasses(type), "Direct Subclasses");
		printRelatedTypes(model.getIndirectSubclasses(type), "Indirect Subclasses");
		printRelatedTypes(model.getDirectImplementors(type), "Direct Implementors");

		printMarkDownDoc(model.getDoc(type));

		printClassFields(type.statics.get(), "Class Fields");
		printClassFields(type.fields.get(), "Instance Fields");
	}

	function printEnum(type:EnumType)
	{
		printMarkDownDoc(model.getDoc(type));

		buf.add('<h2>Constructs:</h2>\n');
		for (field in type.constructs) printEnumField(field);
	}

	function printEnumField(field:EnumField)
	{
		var name = field.name;

		switch (field.type)
		{
			case TFun(args, _):
				var argLinks = args.map(argLink).join(", ");
				if (argLinks.length > 0) argLinks = '($argLinks)';
				buf.add('<h3><code>$name$argLinks</code></h3>\n');
			case _:
				buf.add('<h3><code>$name</code></h3>\n');
		}

		printDoc(field.doc);
	}

	function printDef(type:DefType)
	{
		printMarkDownDoc(model.getDoc(type));

		switch (type.type)
		{
			case TAnonymous(a):
				var ref = a.get();
				printClassFields(ref.fields, "Instance Fields");
			case _:
		}
	}

	function printAbstract(type:AbstractType)
	{
		printMarkDownDoc(model.getDoc(type));
		
		if (type.impl != null)
		{
			var impl = type.impl.get();
			var fields = [];
			var statics = [];
			for (field in impl.statics.get())
			{
				if (field.meta.has(":impl")) fields.push(field);
				else statics.push(field);
			}
			printClassFields(statics, "Class Fields");
			printClassFields(fields, "Instance Fields");
		}
	}

	function printTypeNav(type:BaseType)
	{
		buf.add('<div class="package-nav">');
		var nav = [];
		var parts = [];
		for (pack in type.pack)
		{
			parts.push(pack);
			var path = parts.join("/");
			nav.push('<a href="$baseurl/$path">$pack</a>');
		}
		buf.add('<a href="$baseurl">root</a> ' + nav.join("."));
		buf.add('</div>');
	}

	function printRelatedTypes(types:Array<ClassType>, title:String)
	{
		if (types.length > 0)
		{
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
	}

	function printClassFields(fields:Array<ClassField>, title:String)
	{
		var fields = fields.filter(function(field){ return field.isPublic; });
		if (fields.length > 0)
		{
			buf.add('<h2>$title</h2>\n');
			for (field in fields) printClassField(field);
		}
	}

	function printClassField(field:ClassField)
	{
		var name = field.name;
		
		switch (field.kind)
		{
			case FVar(_,write):
				var link = typeLink(field.type);
				buf.add('<a name="$name"></a><h3><code><span class="k">var</span> <span class="i">$name</span>:$link</code></h3>\n');

			case FMethod(_):
				switch (field.type)
				{
					case TFun(args, ret):
						if (field.meta.has(":impl")) args.shift();
						var argLinks = args.map(argLink).join(", ");
						var retLink = typeLink(ret);
						buf.add('<a name="$name"></a><h3><code><span class="k">function</span> <span class="i">$name</span>($argLinks):$retLink</code></h3>\n');
					case _:
				}
		}
		
		printDoc(field.doc);
	}
	
	function printMarkDownDoc(doc:String)
	{
		buf.add('<div class="doc">$doc</div>\n');
	}

	function printDoc(doc:String)
	{
		printMarkDownDoc(model.parseDoc(doc));
	}

	public function printPack(pack:String)
	{
		buf = new StringBuf();

		if (pack == "") buf.add('<h1>top level<h1>');
		else buf.add('<h1><span class="d">package</span> $pack</h1>');
		
		// var guides = "doc/" + pack.split(".").join("/");
		// if (pack.length > 0 && sys.FileSystem.exists(guides))
		// {
		// 	for (file in sys.FileSystem.readDirectory(guides))
		// 	{
		// 		if (file.indexOf(".md") == -1) continue;
		// 		Sys.println("Generating " + file);

		// 		var doc = model.markupFile(guides + "/" + file);
		// 		// doc = model.markup(doc);

		// 		if (file == "index.md")
		// 		{
		// 			doc = shiftHeadings(doc, 3, true);
		// 			buf.add('<h3>Overview</h3>\n');
		// 			buf.add(doc);
		// 		}
		// 		else
		// 		{
		// 			var copy = parts.copy();
		// 			copy.pop();
		// 			copy.push("doc");
		// 			var dir = out + "/"+copy.join("/");
		// 			copy.push(file.split(".md").join(".html"));

		// 			var output = out + "/" + copy.join("/");
		// 			doc = shiftHeadings(doc, 1, true);

		// 			// msys.FS.mkdir_p(dir, {});
		// 			// sys.io.File.saveContent(output, html(doc));
		// 		}
		// 	}
		// }

		var interfaces:Array<BaseType> = [];
		var classes:Array<BaseType> = [];
		var enums:Array<BaseType> = [];
		var typedefs:Array<BaseType> = [];
		var abstracts:Array<BaseType> = [];
		var types = model.packages.get(pack);

		for (type in types)
		{
			switch (type)
			{
				case TInst(t,_):
					var ref = t.get();
					if (ref.isInterface) interfaces.push(ref);
					else classes.push(ref);
				case TEnum(t,_):
					enums.push(t.get());
				case TType(t,_):
					typedefs.push(t.get());
				case TAbstract(t,_):
					abstracts.push(t.get());
				case _:
			}
		}

		printPackTypes(interfaces, "Interfaces");
		printPackTypes(classes, "Classes");
		printPackTypes(typedefs, "Type Definitions");
		printPackTypes(enums, "Enums");
		printPackTypes(abstracts, "Abstracts");
	}

	function shiftHeadings(doc:String, start:Int, ?removeTop:Bool=false):String
	{
		var matches = matchAll(~/<h([1-9])>/i, doc, 1);
		var levels = matches.map(function(m){ return m[1]; });
		levels.sort(Reflect.compare);
		var top = Std.parseInt(levels[0]);

		if (removeTop)
		{
			doc = new EReg('<h$top>.+?</h$top>','i').replace(doc, "");
		}

		doc = ~/<(\/?)h([1-9])>/gi.map(doc, function(e){
			var level = (Std.parseInt(e.matched(2)) - top) + start;
			return "<"+e.matched(1)+"h"+level+">";
		});
		return doc;
	}

	function matchAll(ereg:EReg, string:String, ?groups:Int=0):Array<Array<String>>
	{
		var matches = [];
		var pos = {pos:0,len:0};
		while (ereg.matchSub(string, pos.pos + pos.len))
		{
			pos = ereg.matchedPos();

			var match = [];
			for (i in 0...groups+1) match.push(ereg.matched(i));
			matches.push(match);
		}
		return matches;
	}

	function printPackTypes(types:Array<BaseType>, title:String)
	{
		if (types.length == 0) return;

		buf.add('<h2>$title</h2>');
		buf.add('<table class="table table-condensed"><tbody>');
		for (type in types)
		{
			var link = baseTypeLink(type);
			var desc = model.getDescription(type);
			buf.add('<tr><td width="200">$link</td><td>$desc</td></tr>');
		}
		buf.add('</tbody></table>');
	}

	// transformers

	function typeLink(type:Type):String
	{
		if (type == null) return null;
		var base = type.toBaseType();

		if (base == null)
		{
			return switch (type)
			{
				case TFun(args, ret): 
					args.map(argType).concat([ret]).map(typeLink).join(" -> ");
				case TDynamic(_):
					'<a href="$baseurl/Dynamic.html">Dynamic</a>';
				case TAnonymous(a):
					"{ "+a.get().fields.map(fieldLink).join(", ")+" }";
				case _:
					// return StringTools.htmlEscape(type.toString());
					StringTools.htmlEscape(Std.string(type));
			}
		}

		var link = baseTypeLink(base);

		switch (type)
		{
			case TType(_, params), TInst(_, params), TEnum(_, params):
				link += paramsLink(params);
			case _:
		}

		return link;
	}

	function fieldLink(field:ClassField):String
	{
		return field.name + ":" + typeLink(field.type);
	}

	function paramsLink(params:Array<Type>):String
	{
		if (params.length == 0) return "";
		return "&lt;" + params.map(typeLink).join(", ") + "&gt;";
	}

	function refLink(ref:{t:Ref<ClassType>, params:Array<Type>}):String
	{
		return baseTypeLink(ref.t.get()) + paramsLink(ref.params);
	}

	function argType(arg:{t:Type, opt:Bool, name:String}):Type
	{
		return arg.t;
	}

	function argLink(arg:{t:Type, opt:Bool, name:String}):String
	{
		var opt = arg.opt ? "?" : "";
		var name = arg.name;
		var link = typeLink(arg.t);
		return '$opt<span class="i">$name</span>:$link';
	}

	function baseTypeLink(type:BaseType):String
	{
		var href = baseTypeURL(type);
		return '<a href="$href">${type.name}</a>';
	}

	function baseTypeURL(type:BaseType):String
	{
		// return "javascript:client.filter('"+baseTypePath(type).join(".")+"');";
		return baseurl + "/" + baseTypePath(type).join("/") + ".html";
	}

	function baseTypePath(type:BaseType):Array<String>
	{
		return type.pack.concat([type.name]);
	}

	function typeKind(type:Type):String
	{
		return switch (type)
		{
			case TType(_,_): 'typedef';
			case TInst(t,_): t.get().isInterface ? 'interface' : 'class';
			case TEnum(_,_): 'enum';
			case TAbstract(_,_): 'abstract';
			case _: null;
		}
	}
}