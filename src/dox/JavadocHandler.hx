package dox;

class JavadocHandler {
	var config:Config;
	var infos:Infos;
	var markdown:MarkdownHandler;

	public function new(cfg:Config, inf:Infos, mdown:MarkdownHandler) {
		config = cfg;
		infos = inf;
		markdown = mdown;
	}

	public function parse(path:String, doc:String):DocInfos {
		var tags = [];
		// TODO: need to parse this better as haxe source might have this sort of meta
		var ereg = ~/^@(param|default|exception|throws|deprecated|return|returns|since|see|event|author)\s+([^@]+)/gm;

		doc = ereg.map(doc, function(e) {
			var name = e.matched(1);
			var doc = e.matched(2);
			var value:Null<String> = null;

			switch (name) {
				case 'param', 'exception', 'throws', 'event':
					var ereg = ~/([^\s]+)\s+(.*)/gs;
					if (ereg.match(doc)) {
						value = ereg.matched(1);
						doc = ereg.matched(2);
					}
				default:
			}
			doc = trimDoc(doc);
			tags.push({
				name: name,
				doc: config.useMarkdown ? markdown.markdownToHtml(path, doc) : doc,
				value: value
			});
			return '';
		});

		var infos:DocInfos = {
			doc: config.useMarkdown ? markdown.markdownToHtml(path, doc) : doc,
			throws: [],
			params: [],
			sees: [],
			events: [],
			tags: tags
		};
		for (tag in tags)
			switch (tag.name) {
				case 'param':
					infos.params.push(tag);
				case 'exception', 'throws':
					infos.throws.push(tag);
				case 'deprecated':
					infos.deprecated = tag;
				case 'return', 'returns':
					infos.returns = tag;
				case 'since':
					infos.since = tag;
				case 'default':
					infos.defaultValue = tag;
				case 'see':
					infos.sees.push(tag);
				case 'event':
					infos.events.push(tag);
				default:
			}
		return infos;
	}

	function trimDoc(doc:String) {
		var ereg = ~/^\s+/m;
		if (ereg.match(doc)) {
			var space = new EReg('^' + ereg.matched(0), 'mg');
			doc = space.replace(doc, '');
		}
		return doc;
	}
}

typedef DocInfos = {
	doc:String,
	?returns:DocTag,
	?deprecated:DocTag,
	?since:DocTag,
	?defaultValue:DocTag,
	sees:Array<DocTag>,
	params:Array<DocTag>,
	throws:Array<DocTag>,
	events:Array<DocTag>,
	tags:Array<DocTag>
}

typedef DocTag = {
	name:String,
	doc:String,
	?value:String
}
