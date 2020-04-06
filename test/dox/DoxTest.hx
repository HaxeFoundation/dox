package dox;

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
 * Working link <http://google.com>
 * Doesnt work link http://google.com
 *
 * Previously broken link <http://php.net/manual/en/function.mail.php>
 * Previously broken link http://php.net/manual/en/function.mail.php
 *
 * ```haxe
 * 	var foo = bar;
 * ```
 */
class TestClass {
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
	public static function test(foo:String):String {
		return "foo";
	}

	/**
		Simple doc
	**/
	public static function haxe_doc_style() {}

	/**
	 * Javadoc style
	 *
	 * Asterix on previous line should still be stripped (no trailing space)
	 */
	public static function java_doc_style() {}

	/**
	 * Adds a child to this entity.
	 * @param append Whether to add the entity to the end or beginning of the child list.
	 * @returns This instance, for chaining.
	 */
	public static function java_doc_style_spaces() {}

	/**
		Tests @returns without @param

		@return A random String.
	**/
	public static function java_doc_return_without_param() {}

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
	 *
	 * @event   added           Dispatched when something is added.
	 * @event   removed         Dispatched when something is removed.
	 */
	public static function java_doc_multiline_comments() {}

	/**
		@param x some documentation for parameters.
	**/
	public function indentation_space_cadets(x:Int):Void {}

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
	public static function defaultValues(a = 0x00FF00, ?b = "foo", c = true, ?d:String = null, e:String = null, ?f:String) {}

	/**
		There should not be a line break between `FlipX:Bool =` and `false`.
	**/
	public function add(Name:String, Frames:Array<Int>, FrameRate:Int = 30, Looped:Bool = true, FlipX:Bool = false, FlipY:Bool = false):Void {}

	/**
		There should not be a line break between `?` and `NotifyCallback`.
	**/
	public static inline function collide(?ObjectOrGroup1:TestClass, ?ObjectOrGroup2:TestClass, ?NotifyCallback:Dynamic->Dynamic->Void):Void {}

	/**
		There should not be a line break between `,` and `Looped`.
	**/
	public function addByIndices(Name:String, Prefix:String, Indices:Array<Int>, Postfix:String, VeryVeryVeryLongArgumentName:Int = 30,
		Looped:Bool = true):Void {}

	/**
		Should be in the "variables" section as `callback:String -> Int -> Void`.
	**/
	public var callback:String->Int->Void;

	extern public function externFunction();

	public final finalVar = "";

	public final function finalFunction() {}
}

/**
	Some *documentation*.
**/
typedef TestTypedef = {
	/**
		Some description with a type reference `Foo`.

		And a Second Line `"type":"ItemDetail"`
	**/
	var myField:String;

	@:dox(hide) var hiddenField:Bool;
	var ?optionalField:String;
}

/**
	Some *documentation*.
**/
enum TestEnum {
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
class TestCodeBlock {}

@:enum
abstract TestEnumAbstract(Int) {
	/**
		Expression shouldn't have a `cast`.
	**/
	var value = 0;
}

abstract TestAbstract(Int) {
	/**
		Method should have `a:Int` and `b:String` arguments, but the implicit `this` argument shouldn't show up.
	**/
	public function foo(a:Int, b:String) {}

	@:from public static function from(i:Int):TestAbstract {
		return cast i;
	}

	@:to public function to():String {
		return Std.string(this);
	}

	@:op(A + B) public function add(b:Int):Int {
		return this + b;
	}
}

/**
	Properties should be sorted alphabetically.
**/
typedef TestTypedefOrder = {
	var z:Int;
	var a:Int;
	var b:Int;
	var q:Int;
}

class TestFieldVisibility {
	static public var staticVarPublic:Int;
	static private var staticVarPrivate:Int;
	@:dox(hide)
	static public var staticVarPublicHiden:Int;
	@:dox(show)
	static private var staticVarPrivateShown:Int;

	public var varPublic:Int;

	private var varPrivate:Int;

	@:dox(hide)
	public var varPublicHidden:Int;

	@:dox(show)
	private var varPrivateShown:Int;

	static public function staticFunctionPublic() {}

	static private function staticFunctionPrivate() {}

	@:dox(hide)
	static public function staticFunctionPublicHidden() {}

	@:dox(show)
	static private function staticFunctionTest4() {}

	public function functionPublic() {}

	private function functionPrivate() {}

	@:dox(hide)
	public function functionPublicHidden() {}

	@:dox(show)
	private function functionPrivateShown() {}
}

/**
 * `obj`
 * `this.obj`,
 * `this.OBJ`
 * `TestLinks.obj`
 * `TestLinks.OBJ`
 * `Std.int`
 * `haxe.io.Eof.new`
 * `true` or `false`
 * `Type`
 * `TestMetaData.RED`
 * `TestEnum.VisibleConstructor`
 * `this.obj + this.OBJ`
 * `TestLinks.obj + TestLinks.OBJ`
**/
class TestLinks {
	public var obj:Int;
	public var OBJ = {x: 10, y: 10};
}

class TestMetaData {
	/**
		Deprecated red color value
	**/
	@:metaWithParams("123", 123)
	@:deprecated("Use `red` instead")
	@:metaWithoutParams
	public static var deprecatedRed = 0xFF0000;

	@:meta
	@:to
	public static var red = 12;
	public static var RED = 12;
}

/**
	This should not be visible on the index page.
**/
class Index {}

@:generic class GenericClass<T> {}
class ChildOfGeneric extends GenericClass<String> {}

/**
	This interface shouldn't show compiler-generated `get_` / `set_` fields (#239).
**/
interface TestInterface {
	public var active(get, set):Bool;
}

class ClassWithImplements implements TestInterface {
	public var active(get, set):Bool;

	inline function get_active()
		return false;

	inline function set_active(active)
		return false;
}

final class FinalClass {}
final interface FinalInterface {}

// #260
interface MultiExtends extends A extends B {}
interface A {}
interface B {}

@:deprecated("This class is deprecated in favor of something else")
class DeprecatedClass {}

@:deprecated("This enum is deprecated in favor of something else")
enum DeprecatedEnum {}

@:deprecated("This abstract is deprecated in favor of something else")
abstract DeprecatedAbstract(Int) {}

@:deprecated("This typedef is deprecated in favor of something else")
typedef DeprecatedTypedef = {}
