package dox;

import haxe.zip.Entry;
import haxe.io.Bytes;

using StringTools;

class Writer {
	var config:Config;
	var zipEntries:Null<List<Entry>>;

	public function new(config:Config) {
		this.config = config;
		if (!config.outputPath.endsWith(".zip")) {
			try {
				if (!sys.FileSystem.exists(config.outputPath)) {
					sys.FileSystem.createDirectory(config.outputPath);
				}
			} catch (e:Dynamic) {
				Sys.println('Could not create output directory ${config.outputPath}');
				Sys.println(Std.string(e));
				Sys.exit(1);
			}
		} else {
			zipEntries = new List();
		}
	}

	public function saveContent(path:String, content:String) {
		if (zipEntries == null) {
			var path = haxe.io.Path.join([config.outputPath, path]);
			var dir = new haxe.io.Path(path).dir;
			if (dir != null) {
				sys.FileSystem.createDirectory(dir);
			}
			sys.io.File.saveContent(path, content);
		} else {
			makeEntry(path, Bytes.ofString(content));
		}
	}

	public function copyFrom(dir:String) {
		function loop(rel) {
			var dir = haxe.io.Path.join([dir, rel]);
			for (file in sys.FileSystem.readDirectory(dir)) {
				var path = haxe.io.Path.join([dir, file]);
				if (sys.FileSystem.isDirectory(path)) {
					var outDir = haxe.io.Path.join([config.outputPath, rel, file]);
					if (zipEntries == null && !sys.FileSystem.exists(outDir))
						sys.FileSystem.createDirectory(outDir);
					loop(haxe.io.Path.join([rel, file]));
				} else {
					if (zipEntries != null) {
						makeEntry(haxe.io.Path.join([rel, file]), sys.io.File.getBytes(path));
					} else {
						sys.io.File.copy(path, haxe.io.Path.join([config.outputPath, rel, file]));
					}
				}
			}
		}
		loop("");
	}

	public function finalize() {
		if (zipEntries != null) {
			var output = sys.io.File.write(config.outputPath);
			var zip = new haxe.zip.Writer(output);
			zip.write(zipEntries);
		}
	}

	function makeEntry(path:String, bytes:Bytes) {
		var entry = {
			fileName: path,
			fileSize: bytes.length,
			fileTime: Date.now(),
			compressed: false,
			dataSize: bytes.length,
			data: bytes,
			crc32: haxe.crypto.Crc32.make(bytes),
			extraFields: null
		};
		haxe.zip.Tools.compress(entry, 1);
		zipEntries.add(entry);
	}
}
