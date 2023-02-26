package dox.test.processor;

@:keep
@:forward
@:forwardStatics
abstract TestAbstractOfAbstract(TestAbstract) from TestAbstract to TestAbstract {}

@:keep
@:forward(impl_instance_var, impl_instance_func)
@:forwardStatics(impl_static_var, impl_static_func)
abstract TestAbstract(TestAbstractImpl) from TestAbstractImpl to TestAbstractImpl {
	/**
	 * static members
	 */
	public static var abstract_static_ro_var(get, never):TestAbstract;

	private static function get_abstract_static_ro_var():TestAbstract {
		return null;
	}

	public static var abstract_static_wo_var(never, set):TestAbstract;

	private static function set_abstract_static_wo_var(value:TestAbstract):TestAbstract {
		return value;
	}

	public static function abstract_static_func_no_args():Void {};

	public static function abstract_static_func_with_args(unused:Int):Void {};

	/**
	 * instance members
	 */
	public function new(someValue:Int) {
		this = new TestAbstractImpl();
	}

	public var abstract_instance_ro_var(get, never):TestAbstract;

	private function get_abstract_instance_ro_var():TestAbstract {
		return this;
	};

	public var abstract_instance_wo_var(never, set):TestAbstract;

	private function set_abstract_instance_wo_var(value:TestAbstract):TestAbstract {
		return value;
	};

	public function abstract_instance_func_no_args():Void {};

	public function abstract_instance_func_with_args(unused:Int):Void {};
}

@:keep
private class TestAbstractImpl {
	/*
	 * fields that should be forwarded
	 */
	public static var impl_static_var:Int = 10;

	public static function impl_static_func():Void {};

	public var impl_instance_var:Int;

	public function impl_instance_func():Void {};

	/*
	 * public fields that should not be forwarded
	 */
	public static var hidden_impl_static_var:Int;

	public static function hidden_impl_static_func():Void {};

	public var hidden_impl_instance_var:Int;

	public function hidden_impl_instance_func():Void {};

	/*
	 * private fields that should not be forwarded
	 */
	private static var private_impl_static_var:Int;

	private static function private_impl_static_func():Void {};

	private var private_impl_instance_var:Int;

	private function private_impl_instance_func():Void {};

	public function new() {}
}
