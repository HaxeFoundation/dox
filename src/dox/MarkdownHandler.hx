package dox;

import Markdown;
import markdown.AST;
import markdown.InlineParser;

class MarkdownHandler {

	var config:Config;
	var infos:Infos;
	
	public function new(cfg:Config, inf:Infos) {
		config = cfg;
		infos = inf;
	}
	
	public function markdownToHtml(path:String, markdown:String) {
		// create document
		var document = new Document();
		document.inlineSyntaxes.push(new MagicCodeSyntax(processCode.bind(path)));

		// replace windows line endings with unix, and split
		var lines = ~/\n\r/g.replace(markdown, '\n').split("\n");

		// parse ref links
		document.parseRefLinks(lines);

		// parse ast
		var blocks = document.parseLines(lines);
		return Markdown.renderHtml(blocks);
	}

	@:access(dox.Infos.resolveType)
	function processCode(path:String, source:String) {
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

			type = infos.resolveType(path, type);
			if (type != null)
			{
				var field = e.matched(3);
				var href = resolveTypeLink(type, field);
				return '<a href="$href">$text</a>';
			}

			return text;
		});

		// Type, null => /Null.html
		source = ~/null/g.map(source, function(e){
			var href = resolveTypeLink("Null");
			return '<a href="$href">null</a>';
		});


		
		return source;
	}
	
	public function pathHref(path:String) {
		return config.rootPath + path.split(".").join("/") + ".html";
	}
	
	public function resolveTypeLink(type:String, ?field:String) {
		if (field == null) return pathHref(type);
		field = field.substr(1);
		return pathHref(type) + "#" + field;
	}
}

class MagicCodeSyntax extends CodeSyntax {

	var callback:String->String;
	
	public function new(callback:String->String) {
		this.callback = callback;
		super('`([^`]*)`');
	}

	override function onMatch(parser:InlineParser):Bool
	{
		var source = pattern.matched(1);
		parser.addNode(ElementNode.text('code', callback(source)));
		return true;
	}
}