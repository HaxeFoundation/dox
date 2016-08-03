package dox;

import haxe.io.Path;
import sys.FileSystem;

class Dox {
	static public function main() {
		// check if we're running from haxelib (last arg is original working dir)
		var owd = Sys.getCwd();
		owd = haxe.io.Path.addTrailingSlash(owd);
		var args = Sys.args();
		var last = new haxe.io.Path(args[args.length-1]).toString();
		if (sys.FileSystem.exists(last) && sys.FileSystem.isDirectory(last)
		    && (args.length < 2 || args[args.length - 2].charCodeAt(0) != "-".code))
		{
			args.pop();
			Sys.setCwd(last);
		}

		var cfg = new Config();

		cfg.outputPath = "pages";
		cfg.xmlPath = "xml";

		var argHandler = hxargs.Args.generate([
			["-r", "--document-root"] => function(path:String) throw 'The -r command is obsolete and can be omitted',

			@doc("Set the output path for generated pages")
			["-o", "--output-path"] => function(path:String) cfg.outputPath = path,

			@doc("Set the xml input path (file names correspond to platform names)")
			["-i", "--input-path"] => function(path:String) cfg.xmlPath = path,

			@doc("Add template directory")
			["-t", "--template-path"] => function(path:String) loadTemplates(cfg, path),

			@doc("Add a resource directory whose contents are copied to the output directory")
			["-res", "--resource-path"] => function(dir:String) cfg.resourcePaths.push(dir),

			@doc("Add a path include filter")
			["-in", "--include"] => function(regex:String) cfg.addFilter(regex, true),

			@doc("Add a path exclude filter")
			["-ex", "--exclude"] => function(regex:String) cfg.addFilter(regex, false),

			@doc("Set the page main title")
			["--title"] => function(name:String) cfg.pageTitle = name,

			@doc("Set the package which serves as top-level")
			["--toplevel-package"] => function(dotPath:String) cfg.toplevelPackage = dotPath,

			@doc("Disable markdown rendering")
			["--no-markdown"] => function() cfg.useMarkdown = false,

			@doc("Set the theme name or path")
			["-theme"] => function(name:String) {
				function setTheme(path:String) {
					if (path.indexOf("/") == -1 && path.indexOf("\\") == -1) {
						path = Path.normalize(Path.join([owd, "themes", path]));
					}
					var configPath = Path.join([path, "config.json"]);
					var themeConfig = try
						sys.io.File.getContent(configPath)
					catch(e:Dynamic) {
						Sys.println('Could not load $configPath');
						Sys.exit(1);
						null;
					}
					var theme:Theme = haxe.Json.parse(themeConfig);
					if (theme.parentTheme != null) {
						setTheme(theme.parentTheme);
					}
					var resourcesPath = Path.join([path, "resources"]);
					if (FileSystem.exists(resourcesPath)) cfg.resourcePaths.push(resourcesPath);
					
					loadTemplates(cfg, Path.join([path, "templates"]));
					return theme;
				}
				cfg.theme = setTheme(name);
			},

			@doc("Defines key = value
  Dox has some special defines:
    -D version <version> : Version shown on the default theme's index.html
    -D source-path <url> : The base URL used for 'View Source' buttons")
			["-D", "--define"] => function(key:String, value:String) cfg.defines[key] = value,

			_ => function(arg:String) throw "Unknown command: " +arg
		]);

		if (args.length == 0) {
			Sys.println("Dox 1.0");
			Sys.println(argHandler.getDoc());
			Sys.exit(0);
		}

		function sortArgs(args:Array<String>) {
			var i = 0;
			var args2 = [];
			var hasThemeArgument = false;
			while (i < args.length) {
				if (args[i] == "-theme") {
					hasThemeArgument = true;
					args2.unshift(args[i + 1]);
					args2.unshift(args[i]);
					i += 2;
				} else {
					args2.push(args[i++]);
				}
			}

			if (!hasThemeArgument) {
				args2.unshift("default");
				args2.unshift("-theme");
			}
			return args2;
		}

		argHandler.parse(sortArgs(args));

		var writer = new Writer(cfg);

		if (!sys.FileSystem.exists(cfg.xmlPath)) {
			Sys.println('Could not read input path ${cfg.xmlPath}');
			Sys.exit(1);
		}
		var parser = new haxe.rtti.XmlParser();

		var tStart = haxe.Timer.stamp();

		function parseFile(path) {
			var name = new haxe.io.Path(path).file;
			Sys.println('Parsing $path');
			var data = sys.io.File.getContent(path);
			var xml = try Xml.parse(data).firstElement() catch(err:Dynamic) {
				trace('Error while parsing $path');
				throw err;
			};
			parser.process(xml, name);
			cfg.platforms.push(name);
		}

		if (sys.FileSystem.isDirectory(cfg.xmlPath)) {
			for (file in sys.FileSystem.readDirectory(cfg.xmlPath)) {
				if (!StringTools.endsWith(file, ".xml")) continue;
				parseFile(cfg.xmlPath + "/" +file);
			}
		} else {
			parseFile(cfg.xmlPath);
		}

		Sys.println("Processing types");
		var proc = new Processor(cfg);
		var root = proc.process(parser.root);

		var api = new Api(cfg, proc.infos);
		var gen = new Generator(api, writer);

		Sys.println("");
		Sys.println("Generating navigation");
		gen.generateNavigation(root);

		Sys.println('Generating to ${cfg.outputPath}');
		gen.generate(root);

		Sys.println("");
		Sys.println('Generated ${api.infos.numGeneratedTypes} types in ${api.infos.numGeneratedPackages} packages');

		for (dir in cfg.resourcePaths) {
			Sys.println('Copying resources from $dir');
			writer.copyFrom(dir);
		}

		writer.finalize();

		var elapsed = Std.string(haxe.Timer.stamp() - tStart).substr(0, 5);
		Sys.println('Done (${elapsed}s)');
	}

	static function loadTemplates(cfg:Config, path:String) {
		cfg.addTemplatePath(path);
		if (!sys.FileSystem.exists(path)) {
			return;
		}
		for (file in sys.FileSystem.readDirectory(path)) {
			var path = new haxe.io.Path(file);
			if (path.ext == "mtt") {
				cfg.loadTemplate(file);
			}
		}
	}
}
