package dox.test;

import dox.test.processor.ProcessorTest;
import utest.ui.Report;
import utest.Runner;

class TestRunner {
	public static function main():Void {
		var runner = new Runner();
		runner.addCase(new ProcessorTest());
		Report.create(runner);
		runner.run();
	}
}
