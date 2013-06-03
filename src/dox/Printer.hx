package dox;

using xray.TypeTools;
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
using Lambda;
using StringTools;

typedef Package = { full:String, name:String, types:Array<Type>, packs:Map<String, Package>};

class Printer
{
	// public static var baseurl = "/dox";
	public static var baseurl = "/dox/pages";

	var model:Model;
	var buf:StringBuf;
	var nav:String;

	public function new(model:Model)
	{
		this.model = model;
		buf = new StringBuf();

		nav = "";

		var root = { name:"", full:"", types:[], packs:new Map<String, Package>()};
		var top = { name:"global", full:"", types:[], packs:new Map<String, Package>()};
		root.packs.set("top", top);

		for (pack in model.packages.keys())
		{
			var types = model.packages.get(pack);
			var cur = root;
			var parts = pack.split(".");
			var full = [];

			for (part in parts)
			{
				full.push(part);

				if (cur.packs.exists(part))
				{
					cur = cur.packs.get(part);
				}
				else
				{
					var next = { full:full.join("."), name:part, types:[], packs:new Map<String, Package>()};
					cur.packs.set(part, next);
					cur = next;
				}
			}

			if (pack == "") top.types = types;
			else cur.types = types;
		}

		nav = getNav(root);
	}

	function getNav(pack:Package):String
	{
		var parts = pack.full.split(".");
		if (parts.length == 1 && parts[0] == "") parts = [];
		var href = parts.join("/");

		var buf = new StringBuf();
		var root = (pack.name == "");

		if (!root)
		{
			buf.add('<li class="expando"><div>');
			buf.add('<a href="#" onclick="toggleCollapsed(this)"><img src="$baseurl/triangle-closed.png"></a>');
			buf.add('<a href="$baseurl/$href">${pack.name}</a>');
			buf.add('</div><ul>');
		}
		else
		{
			buf.add('<ul>');
		}
		
		for (pack in pack.packs) buf.add(getNav(pack));
		pack.types.sort(function(t1,t2) return t1.getName() < t2.getName() ? -1 : 1);
		for (type in pack.types)
		{
			var base = type.toBaseType();
			var link = baseTypeLink(base);
			buf.add('<li><div>$link</div></li>');
		}
		
		buf.add('</ul>');
		if (!root)buf.add('</li>');

		return buf.toString();
	}

	public function printType(type:Type, platforms:Array<String>)
	{
		var name = type.getName();
		var base = type.toBaseType();

		// reset buffer
		buf = new StringBuf();

		// print heading
		printHeading(type);

		// platform availability
		if (platforms.length > 1)
		{
			buf.add('<div><code class="dark"><span class="macro">#if (${platforms.join(" || ")})</span></code></div>\n');
		}
		else
		{
			buf.add('<div><code class="dark"><span class="macro">#if ${platforms.join("")}</span></code></div>\n');
		}
		
		// module to import
		if (base.module != "StdTypes" && name != base.module)
			buf.add('<div><code class="dark"><span class="directive">import</span> <span class="type">${base.module}</span>;</code></div>\n');

		switch (type)
		{
			case TType(t,_): printDef(t.get());
			case TInst(t,_): printClass(t.get());
			case TEnum(t,_): printEnum(t.get());
			case TAbstract(t,_): printAbstract(t.get());
			case _:
		}
	}

	function getHtml() return 
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
				<div class="packages">$nav</div>
				<div class="content">${buf.toString()}</div>
			</div>
		</div>
	</body>
</html>';

	function printHeading(type:Type)
	{
		var kind = switch (type)
		{
			case TType(_,_): 'typedef';
			case TInst(t,_): t.get().isInterface ? 'interface' : 'class';
			case TEnum(_,_): 'enum';
			case TAbstract(_,_): 'abstract';
			case _: null;
		}

		var link = typeLink(type);
		var api = "";

		switch (type)
		{
			case TInst(t, _):
				var ref = t.get();
				if (ref.superClass != null)
				{
					var link = refLink(ref.superClass);
					api += ' <span class="keyword">extends</span> $link';
				}

				if (ref.interfaces.length > 0)
				{
					var links = ref.interfaces.map(refLink);
					for (link in links)
						api += ' <span class="keyword">implements</span> $link';
				}
			default:
		}

		buf.add('<h1><code><span class="directive">$kind</span> $link$api</code></h1>\n');
	}

	function printClass(type:ClassType)
	{
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

		if (type.constructs.array().length > 0)
		{
			buf.add('<h2>Constructs:</h2>\n');
			for (field in type.constructs) printEnumField(field);
		}
	}

	function printEnumField(field:EnumField)
	{
		var name = field.name;
		
		switch (field.type)
		{
			case TFun(args, _):
				var argLinks = args.map(argLink).join(", ");
				if (argLinks.length > 0) argLinks = '($argLinks)';
				buf.add('<h3><code><a name="$name" href="#$name"><span class="type">$name</span></a>$argLinks</code></h3>\n');
			case _:
				buf.add('<h3><code><a name="$name" href="#$name"><span class="type">$name</span></a></code></h3>\n');
		}

		printDoc(field.doc);
	}

	function printDef(type:DefType)
	{
		printMarkDownDoc(model.getDoc(type));

		switch (type.type)
		{
			case TAnonymous(a):
				printClassFields(a.get().fields, "Instance Fields");
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
				if (field.meta.has(":impl")) {
					if (field.name == "_new") field.name = "new";
					fields.push(field);
				}
				else statics.push(field);
			}
			printClassFields(statics, "Class Fields");
			printClassFields(fields, "Instance Fields");
		}
	}

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

	function printClassFields(fields:Array<ClassField>, title:String)
	{
		var fields = fields.filter(function(field){ return field.isPublic; });
		if (fields.length == 0) return;
		
		buf.add('<h2>$title</h2>\n');
		for (field in fields) printClassField(field);
	}

	function printClassField(field:ClassField)
	{
		var name = field.name;
		
		switch (field.kind)
		{
			case FVar(read,write):
				var link = typeLink(field.type);
				var readonly = read == AccInline || write == AccNo || write == AccNever;
				var access = readonly ? '<span class="comment"> // readonly</span>' : '';
				buf.add('<h3><code><span class="keyword">var</span> <a name="$name" href="#$name"><span class="identifier">$name</span></a>:$link;$access</code></h3>\n');

			case FMethod(_):
				switch (field.type)
				{
					case TFun(args, ret):
						if (field.meta.has(":impl")) args.shift();
						var argLinks = args.map(argLink).join(", ");
						var retLink = typeLink(ret);
						var params = field.params.map(function(p) { return p.t; });
						var paramLinks = paramsLink(params);
						buf.add('<a name="$name"></a><h3><code><span class="keyword">function</span> <a name="$name" href="#$name"><span class="identifier">$name</span></a>$paramLinks($argLinks):$retLink;</code></h3>\n');
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
		else buf.add('<h1><span class="directive">package</span> $pack</h1>');
		
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
					'<a href="$baseurl/Dynamic.html"><span class="type">Dynamic</span></a>';
				case TAnonymous(a):
					"{ "+a.get().fields.map(fieldLink).join(", ")+" }";
				case _:
					StringTools.htmlEscape(Std.string(type));
			}
		}

		// don't link type params
		switch (type)
		{
			case TInst(t,_):
				var ref = t.get();
				switch (ref.kind)
				{
					case KTypeParameter(_):
						return '<span class="type">${base.name}</span>';
					default:
				}
			default:
		}

		var link = baseTypeLink(base);

		switch (type)
		{
			case TType(_, params), TInst(_, params), TEnum(_, params), TAbstract(_, params):
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
		return '$opt<span class="identifier">$name</span>:$link';
	}

	function baseTypeLink(type:BaseType):String
	{
		var href = baseTypeURL(type);
		return '<a href="$href"><span class="type">${type.name}</span></a>';
	}

	function baseTypeURL(type:BaseType):String
	{
		return baseurl + "/" + type.pack.concat([type.name]).join("/") + ".html";
	}
}
