package dox;

class Dox {
	static public function main() {
		var cfg = new Config();
		cfg.rootPath = Sys.args()[1] == null ? (Sys.getCwd() + "pages/") : Sys.args()[1];
		cfg.platforms = ["cpp"];
		cfg.templateDir = "templates";
		
		var parser = new haxe.rtti.XmlParser();
		for (platform in cfg.platforms) {
			Sys.println('Parsing $platform');
			var data = sys.io.File.getContent('xml/$platform.xml');
			var xml = Xml.parse(data).firstElement();
			if (platform == "flash8") transformPackage(xml, "flash", "flash8");
			parser.process(xml, platform);			
		}
		
		var proc = new Processor(cfg);
		var gen = new Generator(cfg);
		gen.generate(proc.process(parser.root));
	}
	
	static function transformPackage(x:Xml, p1, p2) {
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
}