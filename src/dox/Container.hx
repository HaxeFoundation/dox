package dox;

using Lambda;

private typedef ContainerType<T> = #if (haxe_ver < 4) List<T> #else Array<T> #end;

@:forward(filter)
abstract Container<T>(ContainerType<T>) from ContainerType<T> to ContainerType<T> {
	public inline function new() {
		this = new ContainerType();
	}

	public function sort(f:T->T->Int) {
		#if (haxe_ver < 4)
		var a = this.array();
		a.sort(f);
		return a.list();
		#else
		return this;
		#end
	}
}
