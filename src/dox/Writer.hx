package dox;

import haxe.zip.Entry;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;

class Writer {
	var config:Config;
	var zipEntries:Null<List<Entry>>;

	public function new(config:Config) {
		this.config = config;
		if (!config.outputPath.endsWith(".zip")) {
			try {
				if (!FileSystem.exists(config.outputPath)) {
					FileSystem.createDirectory(config.outputPath);
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
			var path = Path.join([config.outputPath, path]);
			var dir = new Path(path).dir;
			if (dir != null && !FileSystem.exists(dir)) {
				FileSystem.createDirectory(dir);
			}
			File.saveContent(path, content);
		} else {
			zipEntries.push(makeEntry(path, Bytes.ofString(content)));
		}
	}

	public function copyFrom(dir:String) {
		function loop(rel) {
			var dir = Path.join([dir, rel]);
			for (file in FileSystem.readDirectory(dir)) {
				var path = Path.join([dir, file]);
				if (FileSystem.isDirectory(path)) {
					var outDir = Path.join([config.outputPath, rel, file]);
					if (zipEntries == null && !FileSystem.exists(outDir))
						FileSystem.createDirectory(outDir);
					loop(Path.join([rel, file]));
				} else {
					if (zipEntries != null) {
						makeEntry(Path.join([rel, file]), File.getBytes(path));
					} else {
						File.copy(path, Path.join([config.outputPath, rel, file]));
					}
				}
			}
		}
		loop("");
	}

	public function finalize() {
		if (zipEntries != null) {
			var output = File.write(config.outputPath);
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
		return entry;
	}
}
