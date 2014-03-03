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
			sys.FileSystem.createDirectory(new haxe.io.Path(path).dir);
			sys.io.File.saveContent(path, content);
		} else {
			makeEntry(path, Bytes.ofString(content));
		}
	}
	
	public function copyFrom(dir:String) {
		for (file in sys.FileSystem.readDirectory(dir)) {
			var path = '$dir/$file';
			if (zipEntries != null) {
				makeEntry(path, sys.io.File.getBytes(path));
			} else {
				sys.io.File.copy(path, haxe.io.Path.join([config.outputPath, file]));
			}
		}
	}
	
	public function finalize() {
		if (zipEntries != null) {
			var output = sys.io.File.write(config.outputPath);
			var zip = new haxe.zip.Writer(output);
			zip.write(zipEntries);
		}
	}
	
	function makeEntry(path:String, bytes:Bytes) {
		zipEntries.add({
			fileName: path,
			fileSize: bytes.length,
			fileTime: Date.now(),
			compressed: false,
			dataSize: bytes.length,
			data: bytes,
			crc32: null,
			extraFields: null
		});
	}
}