A Haxe documentation generator.

> Note: Dox currently requires the development branch of Haxe due to some
minor changes in abstract rtti xml generation. You'll also need an up to date
haxelib (requires support for `classPath` in haxelib.json)

Install dependencies:
	haxelib git hxparse https://github.com/Simn/hxparse development src
	haxelib git hxtemplo https://github.com/Simn/hxtemplo master src
	haxelib install hxargs
	haxelib install markdown

To generate std documentation:

	haxelib install hxcpp
	haxelib install hxjava
	haxelib install hxcs

	haxelib dev dox .

	haxe run.hxml
	haxe gen.hxml
	haxe std.hxml

Document root (-r when invoking dox.n) Should point to the absolute path of
the documentation on your server. You might need to update this value in
std.hxml

ie: http://localhost/workspace/docs => -r /workspace/docs
