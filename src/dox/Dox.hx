package dox;

class Dox {
	static public function main() {
		// check if we're running from haxelib (last arg is original working dir)
		var owd = Sys.getCwd();
		var args = Sys.args();
		var last = new haxe.io.Path(args[args.length-1]).toString();
		var slash = last.substr(-1);
		if (slash == "/"|| slash == "\\")
			last = last.substr(0,last.length-1);
		if (sys.FileSystem.exists(last) && sys.FileSystem.isDirectory(last)) {
			args.pop();
			Sys.setCwd(last);
		}

		var cfg = new Config();

		cfg.resourcePaths.push(owd + "resources");
		cfg.rootPath = Sys.getCwd() + "pages/";
		cfg.outputPath = "pages";
		cfg.xmlPath = "xml";
		cfg.addTemplatePath(owd + "templates");
		cfg.addTemplatePath("templates");
		
		var argHandler = hxargs.Args.generate([
			@doc("Set the document root path")
			["-r", "--document-root"] => function(path:String) cfg.rootPath = path,
			
			@doc("Set the output path for generated pages")
			["-o", "--output-path"] => function(path:String) cfg.outputPath = path,
			
			@doc("Set the xml input path")
			["-i", "--input-path"] => function(path:String) cfg.xmlPath = path,
			
			@doc("Add template directory")
			["-t", "--template-path"] => function(path:String) cfg.addTemplatePath(path),
			
			@doc("Add a resource directory whose contents are copied to the output directory")
			["-res", "--resource-path"] => function(dir:String) cfg.resourcePaths.push(dir),
			
			@doc("Add a path include filter")
			["-in", "--include"] => function(regex:String) cfg.addFilter(regex, true),
			
			@doc("Add a path exclude filter")
			["-ex", "--exclude"] => function(regex:String) cfg.addFilter(regex, false),
			
			@doc("Set the page main title")
			["--title"] => function(name:String) cfg.pageTitle = name,
			
			_ => function(arg:String) throw "Unknown command: " +arg
		]);
		
		// var args = Sys.args();
		if (args.length == 0) {
			Sys.println("Dox 1.0");
			Sys.println(argHandler.getDoc());
			Sys.exit(0);
		}
		
		argHandler.parse(args);
				
		try {
			if (!sys.FileSystem.exists(cfg.outputPath))
				sys.FileSystem.createDirectory(cfg.outputPath);
		} catch (e:Dynamic) {
			Sys.println('Could not create output directory ${cfg.outputPath}');
			Sys.println(Std.string(e));
			Sys.exit(1);
		}
		
		if (!sys.FileSystem.exists(cfg.xmlPath) || !sys.FileSystem.isDirectory(cfg.xmlPath)) {
			Sys.println('Could not read input path ${cfg.xmlPath}');
			Sys.exit(1);
		}
		var parser = new haxe.rtti.XmlParser();
		
		var tStart = haxe.Timer.stamp();
		
		for (file in sys.FileSystem.readDirectory(cfg.xmlPath)) {
			if (!StringTools.endsWith(file, ".xml")) continue;
			var name = new haxe.io.Path(file).file;
			Sys.println('Parsing $file');
			var data = sys.io.File.getContent(cfg.xmlPath + "/" +file);
			var xml = try Xml.parse(data).firstElement() catch(err:Dynamic) {
				trace('Error while parsing $file');
				throw err;
			};
			if (name == "flash8") transformPackage(xml, "flash", "flash8");
			parser.process(xml, name);
			cfg.platforms.push(name);
		}
		
		Sys.println("Processing types");
		var proc = new Processor(cfg);
		var root = proc.process(parser.root);
		
		var api = new Api(cfg, proc.infos);
		var gen = new Generator(api);
		
		Sys.println("");
		Sys.println("Generating navigation");
		gen.generateNavigation(root);
		
		Sys.println('Generating to ${cfg.outputPath}');
		gen.generate(root);
		
		Sys.println("");
		Sys.println('Generated ${api.infos.numGeneratedTypes} types in ${api.infos.numGeneratedPackages} packages');
		
		for (dir in cfg.resourcePaths) {
			Sys.println('Copying resources from $dir');
			for (file in sys.FileSystem.readDirectory(dir)) {
				sys.io.File.copy('$dir/$file', cfg.outputPath + "/" + file);
			}
		}
		
		var elapsed = Std.string(haxe.Timer.stamp() - tStart).substr(0, 5);
		Sys.println('Done (${elapsed}s)');
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