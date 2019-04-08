import sys.io.File;

using StringTools;

class RunTravis {
	static inline var DryRun = false;
	static inline var BaseHxml = "runBase.hxml";
	static var exitCode = 0;

	static function command(commandLine:String) {
		var args = commandLine.split(" ");
		var cmd = args.shift();

		Sys.println(commandLine);
		if (!DryRun) {
			if (Sys.command(cmd, args) != 0) {
				exitCode = 1;
			}
		}
	}

	static function haxe(cmd:String) {
		command('haxe $cmd');
	}

	static function compile(args:String) {
		haxe('$BaseHxml $args');
	}

	static function run(cmd:String) {
		command('$cmd -o bin/pages -i bin/xml');
	}

	static function target(name:String, f:Void->Void) {
		Sys.println('Running $name\n');
		f();
		Sys.println("----------------");
	}

	static function main() {
		target("Neko", function() {
			haxe("run.hxml");
			haxe("gen-test.hxml");
			haxe("pages.hxml");
		});

		target("Java", function() {
			var out = 'bin/java';
			compile('-java $out');
			run('java -jar $out/Dox.jar');
		});

		target("JavaScript", function() {
			var out = 'bin/dox.js';
			compile('-lib hxnodejs -js $out');
			run('node $out');
		});

		target("CPP", function() {
			var out = 'bin/cpp';
			compile('-cpp $out -D HXCPP_SILENT');
			run('./$out/Dox');
		});

		#if haxe4
		target("Python", function() {
			var out = 'bin/dox.py';
			compile('-python $out');
			run('python3 $out');
		});
		#end

		#if false
		target("PHP", function() {
			var out = 'bin/php';
			compile('-php $out');
			run('php $out/index.php');
		});
		#end

		target("Interp", function() {
			// hack for 3.4.7
			File.saveContent(BaseHxml, File.getContent(BaseHxml).replace("-main dox.Dox", ""));
			run('haxe $BaseHxml --run dox.Dox');
		});

		Sys.exit(exitCode);
	}
}
