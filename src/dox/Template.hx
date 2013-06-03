package dox;

@:build(dox.TemplateMacro.build()) class Template
{
	inline static function maybe(value:Dynamic, text:String)
	{
		return value == null ? '' : text;
	}
}