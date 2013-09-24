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
}