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
		var lines = markdown.replace("\r\n", "\n").split("\n");

		// parse ref links
		document.parseRefLinks(lines);

		// parse ast
		try {
			var blocks = document.parseLines(lines);
			return Markdown.renderHtml(blocks);
		} catch (err:Dynamic) {
			trace("Parsing warning: " + err);
			return markdown;
		}
	}

	@:access(dox.Infos.resolveType)
	function processCode(path:String, source:String) {
		source = source.htmlEscape();

		// this.field => #field
		source = ~/this\.(\w+)/g.map(source, function(e) {
			var field = e.matched(1);
			return 'this.<a href="#$field">$field</a>';
		});

		// Type, pack.Type, pack.Type.field => pack/Type.html#field
		source = ~/\b([A-Za-z_$][\w\.$]+)\b/g.map(source, function(e) {
			var match = e.matched(0);

			var tmp1 = match.split(".");
			var field = tmp1.pop();
			var type = tmp1.join(".");

			var tmp2 = match.split(".");
			tmp2.pop(); // split possible field
			var type2 = tmp2.pop();
			var path2 = tmp2.join(".");

			var possibleTypes = [infos.resolveType(path, type)];
			if (field != null) {
				possibleTypes.push(infos.resolveType(type, field));
				possibleTypes.push(infos.resolveType(path, field));
			}

			if (type2 != null)
				possibleTypes.push(infos.resolveType(path, type2));
			if (path2 != null)
				possibleTypes.push(infos.resolveType(path, path2));
			if (type2 != null && path2 != null)
				possibleTypes.push(infos.resolveType(type2, path2));

			while (possibleTypes.length > 0) {
				var type = possibleTypes.pop();
				if (type != null) {
					var href = resolveTypeLink(type, field);
					return '<a href="$href">$match</a>';
				}
			}

			return match;
		});

		// true|false => Bool
		source = ~/\b(true|false)\b/g.map(source, function(e) {
			var field = e.matched(1);
			var path = "Bool";
			var type = infos.resolveType(path, path);
			return if (type != null) '<a href="${resolveTypeLink(type)}">$field</a>' else field;
		});

		return source;
	}

	public function pathHref(path:String) {
		return config.rootPath + path.split(".").join("/") + ".html";
	}

	public function resolveTypeLink(type:String, ?field:String) {
		if (field == null)
			return pathHref(type);
		return if (type != field) pathHref(type) + "#" + field else pathHref(type);
	}
}

class MagicCodeSyntax extends CodeSyntax {
	var callback:String->String;

	public function new(callback:String->String) {
		this.callback = callback;
		super('`([^`]*)`');
	}

	override function onMatch(parser:InlineParser):Bool {
		var source = pattern.matched(1);
		parser.addNode(ElementNode.text('code', callback(source)));
		return true;
	}
}
