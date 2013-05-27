package xhx;

import haxe.macro.Expr;

enum Keyword {
	Function;
	Class;
	Var;
	If;
	Else;
	While;
	Do;
	For;
	Break;
	Continue;
	Return;
	Extends;
	Implements;
	Import;
	Switch;
	Case;
	Default;
	Static;
	Public;
	Private;
	Try;
	Catch;
	New;
	This;
	Throw;
	Extern;
	Enum;
	In;
	Interface;
	Untyped;
	Cast;
	Override;
	Typedef;
	Dynamic;
	Package;
	Inline;
	Using;
	Null;
	True;
	False;
	Abstract;
	Macro;
}

enum TokenDef {
	Kwd(k:Keyword);
	Const(c:haxe.macro.Expr.Constant);
	Sharp(s:String);
	Dollar(s:String);
	Unop(op:haxe.macro.Expr.Unop);
	Binop(op:haxe.macro.Expr.Binop);
	Comment(s:String);
	CommentLine(s:String);
	IntInterval(s:String);
	Semicolon;
	Dot;
	DblDot;
	Arrow;
	Comma;
	BkOpen;
	BkClose;
	BrOpen;
	BrClose;
	POpen;
	PClose;
	Question;
	At;
	Eof;
}

typedef Token = {
	tok: TokenDef,
	pos: Position
}

typedef EnumConstructor = {
	name : String,
	doc: String,
	meta: Metadata,
	args: Array<{ name: String, opt: Bool, type: ComplexType}>,
	pos: Position,
	params: Array<TypeParamDecl>,
	type: Null<ComplexType>
}

typedef Definition<A,B> = {
	name : String,
	doc: String,
	params: Array<TypeParamDecl>,
	meta: Metadata,
	flags: Array<A>,
	data: B
}

enum TypeDef {
	EClass(d:Definition<ClassFlag, Array<Field>>);
	EEnum(d:Definition<EnumFlag, Array<EnumConstructor>>);
	EImport(sl:Array<{pack:String, pos:Position}>, mode:ImportMode);
	ETypedef(d:Definition<EnumFlag, ComplexType>);
	EUsing(path:TypePath);
}

enum ClassFlag {
	HInterface;
	HExtern;
	HPrivate;
	HExtends(t:TypePath);
	HImplements(t:TypePath);
}

enum EnumFlag {
	EPrivate;
	EExtern;
}

enum ImportMode {
	INormal;
	IAsName(s:String);
	IAll;
}
