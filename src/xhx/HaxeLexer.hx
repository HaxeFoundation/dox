package xhx;

import xhx.Data;
import haxe.macro.Expr;
import hxparse.Lexer;

enum LexerErrorMsg {
	UnterminatedString;
	UnterminatedRegExp;
	UnclosedComment;
}

class LexerError {
	public var msg:LexerErrorMsg;
	public var pos:Position;
	public function new(msg, pos) {
		this.msg = msg;
		this.pos = pos;
	}
}

class HaxeLexer extends Lexer implements hxparse.RuleBuilder {

	static inline function mkPos(p:Pos) {
		return {
			file: p.psource,
			min: p.pmin,
			max: p.pmax
		};
	}
	
	static function mk(lexer:Lexer, td) {
		return {
			tok: td,
			pos: mkPos(lexer.curPos())
		}
	}
	
	// @:keywords generates a map with lowercase enum constructor names as keys
	// and the constructor itself as value
	static var keywords = @:mapping Data.Keyword;
	
	static var buf = new StringBuf();
	
	static var ident = "_*[a-z][a-zA-Z0-9_]*|_+|_+[0-9][_a-zA-Z0-9]*";
	static var idtype = "_*[A-Z][a-zA-Z0-9_]*";
	
	// @:rule wraps the expression to the right of => with function(lexer) return
	public static var tok = @:rule [
		"" => mk(lexer, Eof),
		"[\r\n\t ]" => lexer.token(tok),
		"0x[0-9a-fA-F]+" => mk(lexer, Const(CInt(lexer.current))),
		"[0-9]+" => mk(lexer, Const(CInt(lexer.current))),
		"[0-9]+.[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
		".[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
		"[0-9]+[eE][\\+\\-]?[0-9]+" => mk(lexer,Const(CFloat(lexer.current))),
		"[0-9]+.[0-9]*[eE][\\+\\-]?[0-9]+" => mk(lexer,Const(CFloat(lexer.current))),
		"[0-9]+..." => mk(lexer,IntInterval(lexer.current.substr(0,-3))),
		"//[^\n\r]*" => mk(lexer, CommentLine(lexer.current.substr(2))),
		"+\\+" => mk(lexer,Unop(OpIncrement)),
		"--" => mk(lexer,Unop(OpDecrement)),
		"~" => mk(lexer,Unop(OpNegBits)),
		"%=" => mk(lexer,Binop(OpAssignOp(OpMod))),
		"&=" => mk(lexer,Binop(OpAssignOp(OpAnd))),
		"|=" => mk(lexer,Binop(OpAssignOp(OpOr))),
		"^=" => mk(lexer,Binop(OpAssignOp(OpXor))),
		"+=" => mk(lexer,Binop(OpAssignOp(OpAdd))),
		"-=" => mk(lexer,Binop(OpAssignOp(OpSub))),
		"*=" => mk(lexer,Binop(OpAssignOp(OpMult))),
		"/=" => mk(lexer,Binop(OpAssignOp(OpDiv))),
		"==" => mk(lexer,Binop(OpEq)),
		"!=" => mk(lexer,Binop(OpNotEq)),
		"<=" => mk(lexer,Binop(OpLte)),
		"&&" => mk(lexer,Binop(OpBoolAnd)),
		"|\\|" => mk(lexer,Binop(OpBoolOr)),
		"<<" => mk(lexer,Binop(OpShl)),
		"->" => mk(lexer,Arrow),
		"..." => mk(lexer,Binop(OpInterval)),
		"=>" => mk(lexer,Binop(OpArrow)),
		"!" => mk(lexer,Unop(OpNot)),
		"<" => mk(lexer,Binop(OpLt)),
		">" => mk(lexer,Binop(OpGt)),
		";" => mk(lexer, Semicolon),
		":" => mk(lexer, DblDot),
		"," => mk(lexer, Comma),
		"." => mk(lexer, Dot),
		"%" => mk(lexer,Binop(OpMod)),
		"&" => mk(lexer,Binop(OpAnd)),
		"|" => mk(lexer,Binop(OpOr)),
		"^" => mk(lexer,Binop(OpXor)),
		"+" => mk(lexer,Binop(OpAdd)),
		"*" => mk(lexer,Binop(OpMult)),
		"/" => mk(lexer,Binop(OpDiv)),
		"-" => mk(lexer,Binop(OpSub)),
		"=" => mk(lexer,Binop(OpAssign)),
		"[" => mk(lexer, BkOpen),
		"]" => mk(lexer, BkClose),
		"{" => mk(lexer, BrOpen),
		"}" => mk(lexer, BrClose),
		"(" => mk(lexer, POpen),
		")" => mk(lexer, PClose),
		"?" => mk(lexer, Question),
		"@" => mk(lexer, At),
		'"' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string) catch (e:haxe.io.Eof) throw new LexerError(UnterminatedString, mkPos(pmin));
			var token = mk(lexer, Const(CString(buf.toString())));
			token.pos.min = pmin.pmin; token;
		},
		"'" => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string2) catch (e:haxe.io.Eof) throw new LexerError(UnterminatedString, mkPos(pmin));
			var token = mk(lexer, Const(CString(buf.toString())));
			token.pos.min = pmin.pmin; token;
		},
		'~/' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(regexp) catch (e:haxe.io.Eof) throw new LexerError(UnterminatedRegExp, mkPos(pmin));
			var token = mk(lexer, Const(CRegexp(buf.toString(),'')));
			token.pos.min = pmin.pmin; token;
		},
		'/\\*' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(comment) catch (e:haxe.io.Eof) throw new LexerError(UnclosedComment, mkPos(pmin));
			var token = mk(lexer, Comment(buf.toString()));
			token.pos.min = pmin.pmin; token;
		},
		"#" + ident => mk(lexer, Sharp(lexer.current.substr(1))),
		"$" + ident => mk(lexer, Dollar(lexer.current.substr(1))),
		ident => {
			var kwd = keywords.get(lexer.current);
			if (kwd != null)
				mk(lexer, Kwd(kwd));
			else
				mk(lexer, Const(CIdent(lexer.current)));
		},
		idtype => mk(lexer, Const(CIdent(lexer.current))),
	];
	
	public static var string = @:rule [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string);
		},
		"\\\\n" => {
			buf.add("\n");
			lexer.token(string);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string);
		},
		"\\\\\"" => {
			buf.add('"');
			lexer.token(string);
		},
		'"' => lexer.curPos().pmax,
		"[^\\\\\"]+" => {
			buf.add(lexer.current);
			lexer.token(string);
		}
	];
	
	public static var string2 = @:rule [
		"\\\\\\\\" => {
			buf.add("\\");
			lexer.token(string2);
		},
		"\\\\n" =>  {
			buf.add("\n");
			lexer.token(string2);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(string2);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(string2);
		},
		'\\\\\'' => {
			buf.add('"');
			lexer.token(string2);
		},
		"'" => lexer.curPos().pmax,
		'[^\\\\\']+' => {
			buf.add(lexer.current);
			lexer.token(string2);
		}
	];
	
	public static var comment = @:rule [
		"*/" => lexer.curPos().pmax,
		"*" => {
			buf.add("*");
			lexer.token(comment);
		},
		"[^\\*]" => {
			buf.add(lexer.current);
			lexer.token(comment);
		}
	];

	public static var regexp = @:rule [
		"\\\\/" => {
			buf.add("/");
			lexer.token(regexp);
		},
		"\\\\r" => {
			buf.add("\r");
			lexer.token(regexp);
		},
		"\\\\n" => {
			buf.add("\n");
			lexer.token(regexp);
		},
		"\\\\t" => {
			buf.add("\t");
			lexer.token(regexp);
		},
		"\\\\[\\$\\.*+\\^|{}\\[\\]()?\\-0-9]" => {
			buf.add(lexer.current);
			lexer.token(regexp);
		},
		"\\\\[wWbBsSdDx]" => {
			buf.add(lexer.current);
			lexer.token(regexp);
		},
		"/" => {
			lexer.token(regexp_options);
			lexer.curPos().pmax;
		},
		"[^\\\\/\r\n]+" => {
			buf.add(lexer.current);
			lexer.token(regexp);
		}
	];

	public static var regexp_options = @:rule [
		"[gimsu]*" => {
			buf.add(lexer.current);
			lexer.curPos().pmax;
		}
	];
}