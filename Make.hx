function main() {
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
				Sys.command("npx lix run dox -o bin/pages -i bin/xml --include dox -D source-path https://github.com/HaxeFoundation/dox/tree/master/test");

			case "server":
				Sys.command("npx http-server bin/pages -c-1");

			case "package":
				Sys.command("7z a -i!run.n -i!run.js -i!resources -i!themes -i!src -i!haxelib.json -i!README.md -i!LICENSE.md -i!CHANGELOG.md bin/haxelib.zip");
		}
	}
}
