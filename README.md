A Haxe documentation generator.

Install dependencies:

	haxelib install hxtemplo
	haxelib install markdown

To generate std documentation:
	
	haxe doc.hxml
	haxe gen.hxml
	haxe std.hxml

Document root (-r when invoking dox.n) Should point to the absolute path of 
the documentation on your server. You might need to update this value in 
std.hxml

ie: http://localhost/workspace/docs => -r /workspace/docs
