package dox;

class Dox {
	static public function main() {
		var cfg = new Config();
		cfg.rootPath = Sys.args()[0] == null ? (Sys.getCwd() + "pages/") : Sys.args()[0];
		cfg.outputPath = "pages";
		cfg.platforms = ["cpp"];
		cfg.templateDir = "templates";
		cfg.resourcePaths = ["../res"];
		
		var parser = new haxe.rtti.XmlParser();
		for (platform in cfg.platforms) {
			Sys.println('Parsing $platform');
			var data = sys.io.File.getContent('xml/$platform.xml');
			var xml = Xml.parse(data).firstElement();
			if (platform == "flash8") transformPackage(xml, "flash", "flash8");
			parser.process(xml, platform);
		}
		
		var proc = new Processor(cfg);
		var root = proc.process(parser.root);
		Sys.println('Generating to ${cfg.outputPath}');
		
		var api = new Api(cfg, proc.infos);
		var gen = new Generator(api);
		gen.generate(root);
		gen.generateNavigation(root);
		
		for (dir in cfg.resourcePaths) {
			Sys.println('Copying resources from $dir');
			for (file in sys.FileSystem.readDirectory(dir)) {
				sys.io.File.copy('$dir/$file', cfg.outputPath + file);
			}
		}
		Sys.println("Done");
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