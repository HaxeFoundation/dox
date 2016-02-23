/**
 * <p>A node in the entity hierarchy, and a collection of components.</p>
 *
 * <p>To iterate over the hierarchy, use the parent, firstChild, next and firstComponent fields. For
 * example:</p>
 *
 * <pre>
 * // Iterate over entity's children
 * var child = entity.firstChild;
 * while (child != null) {
 *     var next = child.next; // Store in case the child is removed in process()
 *     process(child);
 *     child = next;
 * }
 * </pre>
 *
 * Working link http://google.com
 *
 * Previously broken link http://php.net/manual/en/function.mail.php
 *
 * ```haxe
 * 	var foo = bar;
 * ```
 */
class TestClass
{
	static function main() {}

	/**
		The value of something.

		@default 10
	**/
	public var value:Int = 10;

	/**
		Tests things.

		@param foo Uh, the foo to test?
			Also some newlines.

			Even a paragraph.

				trace("Even a freaking code sample")

		@return The result of the `foo` test.
	**/
	public static function test(foo:String):String
	{
		return "foo";
	}

	/**
		Simple doc
	**/
	public static function haxe_doc_style()
	{

	}

	/**
	 * Javadoc style
	 *
	 * Asterix on previous line should still be stripped (no trailing space)
	 */
	public static function java_doc_style()
	{

	}

	/**
	 * Adds a child to this entity.
	 * @param append Whether to add the entity to the end or beginning of the child list.
	 * @returns This instance, for chaining.
	 */
	public static function java_doc_style_spaces()
	{

	}

	/**
		Tests @returns without @param

		@return A random String.
	**/
	public static function java_doc_return_without_param() {

	}

	/**
	 * Creates a FlxSprite at a specified position with a specified one-frame graphic.
	 * If none is provided, a 16x16 image of the HaxeFlixel logo is used.
	 *
	 * @param   X               The initial X position of the sprite.
	 * @param   Y               The initial Y position of the sprite.
	 * @param   SimpleGraphic   The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 *
	 * @see     http://google.com
	 * @see     http://haxe.org
	 */
	public static function java_doc_multiline_comments() {

	}

	/**
	  @param x some documentation for parameters.
	**/
	public function indentation_space_cadets(x:Int):Void
	{
	}

	@:dox(hide) public var hiddenField:String;

	public static var hexInit = 0xFF0000;
	public static var nonHexInit = 12;

	/**
		Arguments should look like this:
		
		- `a:Int = 0x00FF00`
		- `b:String = "foo"`
		- `c:Bool = true`
		- `?d:String`
		- `?e:String`
		- `?f:String`
	**/
	public static function defaultValues(a = 0x00FF00, ?b = "foo", c = true, ?d:String = null, e:String = null, ?f:String) { }
	
	/**
		There should not be a line break between `FlipX:Bool =` and `false`.
	**/
	public function add(Name:String, Frames:Array<Int>, FrameRate:Int = 30, Looped:Bool = true, FlipX:Bool = false, FlipY:Bool = false):Void
	{	
	}
	
	/**
		There should not be a line break between `?` and `NotifyCallback`.
	**/
	public static inline function collide(?ObjectOrGroup1:TestClass, ?ObjectOrGroup2:TestClass, ?NotifyCallback:Dynamic->Dynamic->Void):Void
	{
	}
	
	/**
		Should be in the "variables" section as `callback:String -> Int -> Void`.
	**/
	public var callback:String->Int->Void;
}

/**
	Some *documentation*.
**/
typedef TestTypeDef =
{
	/**
		Some description with a type reference `Foo`.

		And a Second Line `"type":"ItemDetail"`
	**/
	var myField:String;

	@:dox(hide) var hiddenField:Bool;
}

/**
	Some *documentation*.
**/
enum TestEnum
{
	/**
		Some *documentation*.
	**/
	@:dox(hide) HiddenConstructor;

	/**
		Some *documentation*.
	**/
	VisibleConstructor;
}

@:dox(hide) enum TestHiddenEnum {}

/**
	Use this type to have access to the bitwise operators of C# enums that have a `cs.system.FlagsAttribute` attribute.

	```haxe
		import cs.system.reflection.BindingFlags;

		var binding = new Flags(BindingFlags.Public) | BindingFlags.Static | BindingFlags.NonPublic;
	```
**/
class TestClass2
{

}

@:enum
abstract TestEnumAbstract(Int)
{
	/**
		Expression shouldn't have a `cast`.
	**/
	var value = 0;
}