A Haxe documentation generator.

> Note: Dox currently requires the development branch of Haxe due to some
minor changes in abstract rtti xml generation.

Install dependencies:

	haxelib install hxtemplo
	haxelib install hxargs
	haxelib install markdown

To generate std documentation:

	haxe run.hxml
	haxe gen.hxml
	haxe std.hxml

Document root (-r when invoking dox.n) Should point to the absolute path of
the documentation on your server. You might need to update this value in
std.hxml

ie: http://localhost/workspace/docs => -r /workspace/docs
