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

	public function parse(doc:String):DocInfos
	{
		var tags = [];
		var ereg = ~/@(\w+) ([^@]+)/gs;

		doc = ereg.map(doc, function(e){
			var name = e.matched(1);
			var doc = e.matched(2);
			var value = null;
			switch (name)
			{
				case 'param', 'exception', 'throws':
					var i = doc.indexOf(' ');
					if (i > -1)
					{
						value = doc.substring(0, i);
						doc = doc.substr(i+1);
					}
				default:
			}
			doc = trimDoc(doc);
			tags.push({name:name, doc:markdown.markdownToHtml(doc), value:value});
			return '';
		});

		var infos:DocInfos = {doc:markdown.markdownToHtml(doc), throws:[], params:[], tags:tags};
		for (tag in tags) switch (tag.name)
		{
			case 'param': infos.params.push(tag);
			case 'exception', 'throws': infos.throws.push(tag);
			case 'deprecated': infos.deprecated = tag;
			case 'return', 'returns': infos.returns = tag;
			case 'since': infos.since = tag;
			default:
		}
		return infos;
	}

	function trimDoc(doc:String)
	{
		var ereg = ~/^\s+/m;
		if (ereg.match(doc))
		{
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
	params:Array<DocTag>,
	throws:Array<DocTag>,
	tags:Array<DocTag>	
}

typedef DocTag = {
	name:String,
	doc:String,
	value:String
}
