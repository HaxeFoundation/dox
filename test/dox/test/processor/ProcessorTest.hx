package dox.test.processor;

import utest.Assert;

using Lambda;
using StringTools;

class ProcessorTest extends utest.Test {
	public function testProcessor() {
		var cfg = new Config(Sys.getCwd());
		cfg.inputPath = "bin/doc.xml";

		cfg.outputPath = "bin/pages";
		cfg.toplevelPackage = "dox.test";
		cfg.loadTheme("default");

		var xml = try Xml.parse(sys.io.File.getContent("bin/doc.xml")).firstElement() catch (err:Dynamic) throw err;
		var parser = new haxe.rtti.XmlParser();

		parser.process(xml, "unused");

		var root = new Processor(cfg).process(parser.root);
		var testAbstract = Processor.findInTrees("dox.test.processor.TestAbstract", root);
		Assert.notNull(testAbstract);
		switch (testAbstract) {
			case TAbstractdecl(realType):
				var fields = realType.impl.fields.map(cf -> cf.name);
				fields.sort(Reflect.compare);
				var statics = realType.impl.statics.map(cf -> cf.name);
				statics.sort(Reflect.compare);
				Assert.same([
					"abstract_instance_func_no_args",
					"abstract_instance_func_with_args",
					"abstract_instance_ro_var",
					"abstract_instance_wo_var",
					"impl_instance_func",
					"impl_instance_var",
					"new"
				], fields);
				Assert.same([
					"abstract_static_func_no_args",
					"abstract_static_func_with_args",
					"abstract_static_ro_var",
					"abstract_static_wo_var",
					"impl_static_func",
					"impl_static_var"
				], statics);
			case _:
				throw "Type TestAbstract is not an abstract!";
		}
		var testAbstractOfAbstract = Processor.findInTrees("dox.test.processor.TestAbstractOfAbstract", root);
		Assert.notNull(testAbstractOfAbstract);
		switch (testAbstractOfAbstract) {
			case TAbstractdecl(realType):
				var fields = realType.impl.fields.map(cf -> cf.name);
				fields.sort(Reflect.compare);
				var statics = realType.impl.statics.map(cf -> cf.name);
				statics.sort(Reflect.compare);
				Assert.same([
					"abstract_instance_func_no_args",
					"abstract_instance_func_with_args",
					"abstract_instance_ro_var",
					"abstract_instance_wo_var",
					"impl_instance_func",
					"impl_instance_var",
					"new"
				], fields);
				Assert.same([
					"abstract_static_func_no_args",
					"abstract_static_func_with_args",
					"abstract_static_ro_var",
					"abstract_static_wo_var",
					"impl_static_func",
					"impl_static_var"
				], statics);
			case _:
				throw "Type TestAbstractOfAbstract is not an abstract!";
		}
	}
}
