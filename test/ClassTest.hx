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
 */
class ClassTest
{
	static function main() {}

	/**
		Tests things.

		@param foo Uh, the foo to test?
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
}