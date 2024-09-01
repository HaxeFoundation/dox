package dox;

import sys.FileSystem;

class Dox {
	static function main() {
		var args = Sys.args();

		#if neko
		// use the faster JS version if possible
		try {
			var process = new sys.io.Process("node", ["-v"]);
			var isValidNode = false;
			if (process.exitCode() == 0) {
				var output = process.stdout.readAll().toString();
				output = output.substr(1); // remove leading "v"
				var parts = output.split(".").map(Std.parseInt);
				// min supported node version is 8.10.0 due to usage of regex dotall flag
				isValidNode = parts[0] > 8 || parts[0] == 8 && parts[1] >= 10;
			}
			process.close();
			if (isValidNode && FileSystem.exists("run.js")) {
				Sys.println("Using Node.js version of dox...");
				var exitCode = Sys.command("node", ["run.js"].concat(args));
				Sys.exit(exitCode);
			}
		} catch (e:Any) {}
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

		var cfg = new Config(owd);
		var help = false;

		// @formatter:off
		var argHandler = hxargs.Args.generate([
			@doc("Set the output path for generated pages (directory or a .zip file)")
			["-o", "--output-path"] => function(path:String) cfg.outputPath = path,

			@doc("Set the xml input path (file names correspond to platform names)")
			["-i", "--input-path"] => function(path:String) cfg.inputPath = path,

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

			@doc("Don't sort fields alphabetically")
			["--keep-field-order"] => function() cfg.keepFieldOrder = true,

			@doc("Set the theme name or path")
			["-theme"] => function(name:String) cfg.loadTheme(name),

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

			@doc("Display this list of options")
			["-help", "--help"] => function() help = true,

			_ => function(arg:String) throw "Unknown command: " +arg
		]);
		// @formatter:on
		function printHelp() {
			Sys.println("Dox 1.6.0");
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
			cfg.loadTheme("default");
		}

		run(cfg, Api.new);
	}

	public static function run(cfg:Config, createApi:Config->Infos->Api) {
		if (cfg.theme == null) {
			throw "cfg does not have a theme";
		}

		var writer = new Writer(cfg);

		if (!FileSystem.exists(cfg.inputPath)) {
			Sys.println('Could not read input path ${cfg.inputPath}');
			Sys.exit(1);
		}
		var parser = new haxe.rtti.XmlParser();

		var tStart = haxe.Timer.stamp();

		function parseFile(path) {
			var name = new Path(path).file;
			Sys.println('Parsing $path');

			var hashPaths = cfg.outputPath + "/hashes/";

			if (!FileSystem.exists(hashPaths))
				FileSystem.createDirectory(hashPaths);

			var data = sys.io.File.getContent(path);
			var md5Hash = haxe.crypto.Md5.encode(data);

			if (sys.FileSystem.exists(hashPaths + name + ".md5")) {
				var previousHash = sys.io.File.getContent(hashPaths + name + ".md5");
				if (md5Hash == previousHash) {
					Sys.println('Skipping $path, no file changes detected');
					return;
				}
			}

			sys.io.File.saveContent(hashPaths + name + ".md5", md5Hash);

			var xml = try Xml.parse(data).firstElement() catch (err:Dynamic) {
				trace('Error while parsing $path');
				throw err;
			};
			parser.process(xml, name);
			cfg.platforms.push(name);
		}

		if (FileSystem.isDirectory(cfg.inputPath)) {
			for (file in FileSystem.readDirectory(cfg.inputPath)) {
				if (!file.endsWith(".xml"))
					continue;
				parseFile(cfg.inputPath + "/" + file);
			}
		} else {
			parseFile(cfg.inputPath);
		}

		Sys.println("Processing types");
		var proc = new Processor(cfg);
		var root = proc.process(parser.root);

		var api = createApi(cfg, proc.infos);
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
