package dox;

import haxe.rtti.CType;
using Lambda;

class GeneratorXml
{
	static function main()
	{
		var parser = new haxe.rtti.XmlParser();
		
		for (platform in [
			"cpp", 
			"cs", 
			"flash8", 
			"flash9", 
			// "java", 
			"js", 
			"neko", 
			"php"])
		{
			var data = sys.io.File.getContent('xml/$platform.xml');
			var xml = Xml.parse(data).firstElement();
			parser.process(xml, platform);
		}

		parser.root.iter(printTree);
	}

	static function printTree(tree:TypeTree)
	{
		switch (tree)
		{
			case TTypedecl(t):
				trace(t.path);
			case TPackage(name, full, subs):
				trace(full);
				subs.iter(printTree);
			case TEnumdecl(t):
				trace(t.path);
			case TClassdecl(t):
				trace(t.path);
			case TAbstractdecl(t):
				trace(t.path);
		}
	}
}