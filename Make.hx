class Make {
	static function main() {
		var args = Sys.args();
		if (args.length == 0) {
			args = ["dox", "xml", "pages", "server"];
		}
		for (arg in args) {
			switch arg {
				case "dox":
					Sys.command("npx haxe run.hxml");

				case "xml":
					Sys.command("npx haxe xml.hxml");

				case "pages":
					Sys.command("npx lix run dox -o bin/pages -i bin/xml");

				case "server":
					Sys.setCwd("bin/pages");
					Sys.command("nekotools server");

				case "package":
					Sys.command("7z a -i!run.n -i!run.js -i!images -i!themes -i!src -i!haxelib.json -i!README.md -i!LICENSE.md -i!CHANGELOG.md bin/haxelib.zip");
			}
		}
	}
}
