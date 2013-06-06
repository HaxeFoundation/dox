package dox;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using StringTools;

class Args {
	macro static public function generate(definition:Expr) {
		var p = Context.currentPos();
		var el = switch(definition.expr) {
			case EArrayDecl(el): el;
			case _: Context.error("Command mapping expected", p);
		}
		var docs = [];
		var cases = [];
		
		function addDoc(e, s, args:Array<FunctionArg>) {
			var e = switch(e.expr) {
				case EParenthesis(e): e;
				case _: e;
			}
			var argString = args.length == 0 ? "" : " " +args.map(function(arg) return '<${arg.name}>').join(" ");
			docs.push(e.toString().replace('"', "") + '$argString: $s');
		}
		
		function addCase(cmds, action) {
			var args = [];
			var fArgs = switch(action.expr) {
				case EFunction(name, func):
					for (i in 0...func.args.length) {
						args.push(macro __args[__index + $v{i}]);
					}
					func.args;
				case _: Context.error("Function expected", action.pos);
			}
			cmds = switch(cmds.expr) {
				case EMeta({name: "doc", params: [{expr: EConst(CString(s))}]}, e):
					addDoc(e, s, fArgs);
					e;
				case _: cmds;
			}
			var cmds = switch(cmds.expr) {
				case EArrayDecl(el):
					for (e in el) {
						switch(e.expr) {
							case EConst(CString(_)):
							case _: Context.error("String expected", e.pos);
						}
					}
					el;
				case EConst(CString(_)): [cmds];
				case _: Context.error("[commands] or command expected", cmds.pos);
			}
			var e = macro {
				if (__index + $v{fArgs.length} > __args.length)
					throw "Not enough arguments: " +__args[__index -1]+ " expects " + $v{fArgs.length};
				${action}($a{args});
				__index += $v{fArgs.length};
			}

			cases.push({
				values: cmds,
				guard: null,
				expr: e
			});
		}
				
		for (e in el) {
			switch(e.expr) {
				case EBinop(OpArrow, cmds, action):
					addCase(cmds, action);
				case _:
					Context.error("Command mapping expected", e.pos);
			}
		}
		
		cases.push({
			values: [macro c],
			guard: null,
			expr: macro throw "Unknown command: " +c
		});
		
		var eswitch = {
			expr: ESwitch(macro __args[__index++], cases, null),
			pos: p
		};

		return macro {
			getDoc: function() {
				return $v{docs.join("\n")};
			},
			parse: function(__args:Array<String>) {
				var __index = 0;
				while (__index < __args.length) {
					$eswitch;
				}
			}
		}
	}
}