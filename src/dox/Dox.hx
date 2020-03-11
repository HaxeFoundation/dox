package dox;

import sys.FileSystem;

class Dox {
	static public function main() {
		var args = Sys.args();

		#if (!macro && !eval) // doesn't get any more interp than this
		function hasInterpArg()
			return args.indexOf("--interp") != -1;

		if (hasInterpArg()) {
			while (hasInterpArg()) {
				args.remove("--interp");
			}
			var haxeArgs = ["runBase.hxml", "--run", "dox.Dox"].concat(args);
			Sys.println("haxe " + haxeArgs.join(" "));
			Sys.exit(Sys.command("haxe", haxeArgs));
		}
		#end

		var owd = Sys.getCwd();
		owd = Path.addTrailingSlash(owd);

		// check if we're running from haxelib (last arg is original working dir)
		var last = args[args.length - 1];
		if (last != null && Sys.getEnv("HAXELIB_RUN") == "1") {
			var path = new Path(last).toString();
			if (FileSystem.exists(path) && FileSystem.isDirectory(path)) {
				args.pop();
				Sys.setCwd(path);
			}
		}

		var cfg = new Config();
		var help = false;

		// @formatter:off
		var argHandler = hxargs.Args.generate([
			@doc("Set the output path for generated pages (directory or a .zip file)")
			["-o", "--output-path"] => function(path:String) cfg.outputPath = path,

			@doc("Set the xml input path (file names correspond to platform names)")
			["-i", "--input-path"] => function(path:String) cfg.xmlPath = path,

			@doc("Add template directory")
			["-t", "--template-path"] => function(path:String) cfg.loadTemplates(path),

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

			@doc("Include private fields and types")
			["--include-private"] => function() cfg.includePrivate = true,

			@doc("Set the theme name or path")
			["-theme"] => function(name:String) cfg.loadTheme(owd, name),

			@doc("Defines key = value
  Available defines for the default theme:
    -D version <version>  : Version shown on the default theme's index.html
    -D source-path <url>  : The base URL used for 'View Source' buttons
    -D themeColor <color> : Background color of header/footer - default value 0xFAFAFA
    -D textColor <color>  : Text color of header/footer  - defaults to a contrasting color to the themeColor
    -D website <url>      : URL to website for logo and footer
    -D logo <path>        : Path to logo image for the header
    -D description <text> : A paragraph at the landing page / toplevel package view")
			["-D", "--define"] => function(key:String, value:String) cfg.defines[key] = value,

			@doc("Run dox using Haxe's macro interpreter (requires dox from source)")
			["--interp"] => function() { /* handled above, just want the --help doc */ },

			@doc("Display this list of options")
			["-help", "--help"] => function() help = true,

			_ => function(arg:String) throw "Unknown command: " +arg
		]);
		// @formatter:on
		function printHelp() {
			Sys.println("Dox 1.3.0");
			Sys.println(argHandler.getDoc());
			Sys.exit(0);
		}

		if (args.length == 0) {
			printHelp();
		}

		argHandler.parse(args);
		if (help) {
			printHelp();
		}

		if (cfg.theme == null) {
			cfg.loadTheme(owd, "default");
		}

		var writer = new Writer(cfg);

		if (!FileSystem.exists(cfg.xmlPath)) {
			Sys.println('Could not read input path ${cfg.xmlPath}');
			Sys.exit(1);
		}
		var parser = new haxe.rtti.XmlParser();

		var tStart = haxe.Timer.stamp();

		function parseFile(path) {
			var name = new Path(path).file;
			Sys.println('Parsing $path');
			var data = sys.io.File.getContent(path);
			var xml = try Xml.parse(data).firstElement() catch (err:Dynamic) {
				trace('Error while parsing $path');
				throw err;
			};
			parser.process(xml, name);
			cfg.platforms.push(name);
		}

		if (FileSystem.isDirectory(cfg.xmlPath)) {
			for (file in FileSystem.readDirectory(cfg.xmlPath)) {
				if (!file.endsWith(".xml"))
					continue;
				parseFile(cfg.xmlPath + "/" + file);
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

		Sys.println("Generating 404 page");
		gen.generateErrorPage(root);

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
}
