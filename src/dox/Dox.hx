package dox;

class Dox {
	static public function main() {
		var cfg = new Config();

		cfg.rootPath = Sys.getCwd() + "pages/";
		cfg.outputPath = "pages";
		cfg.templateDir = "templates";
		
		var argHandler = Args.generate([
			@doc("Set the document root path")
			"-r" => function(path:String) cfg.rootPath = path,
			@doc("Set the output path for generated pages")
			"-o" => function(path:String) cfg.outputPath = path,
			@doc("Add a platform")
			"-s" => function(name:String, xmlPath:String) cfg.platforms.push(name),
			@doc("Set the template directory")
			"-t" => function(path:String) cfg.templateDir = path,
			@doc("Add a resource directory whose contents are copied to the output directory")
			"-res" => function(dir:String) cfg.resourcePaths.push(dir)
		]);
		
		var args = Sys.args();
		if (args.length == 0) {
			Sys.println("Dox 1.0");
			Sys.println(argHandler.getDoc());
			Sys.exit(0);
		}
		
		argHandler.parse(args);
		
		if (cfg.platforms.length == 0) {
			Sys.println("No source specified, use the -s command to add a source");
			Sys.exit(1);
		}
		
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
		
		haxe.Timer.measure(function() {
		gen.generate(root);
		gen.generateNavigation(root);
		});
		
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