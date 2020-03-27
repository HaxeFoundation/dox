class Make {
	static function main() {
		for (arg in Sys.args()) {
			switch arg {
				case "xml":
					Sys.command("npx haxe xml.hxml");

				case "pages":
					Sys.command("npx lix run dox -o bin/pages -i bin/xml");

				case "server":
					Sys.setCwd("bin/pages");
					Sys.command("nekotools server");

				case "package":
					Sys.command("7z a -i!run.n -i!themes -i!haxelib.json -i!README.md -i!LICENSE.md -i!CHANGELOG.md bin/haxelib.zip");
			}
		}
	}
}
