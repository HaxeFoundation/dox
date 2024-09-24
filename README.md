# Dox
[![Build Status](https://github.com/HaxeFoundation/dox/workflows/CI/badge.svg "GitHub Actions")](https://github.com/HaxeFoundation/dox/actions?query=workflow%3ACI)
[![Haxelib Version](https://badgen.net/haxelib/v/dox)](https://lib.haxe.org/p/dox)
[![Haxelib Downloads](https://badgen.net/haxelib/d/dox?color=blue)](https://lib.haxe.org/p/dox)
[![Haxelib License](https://badgen.net/haxelib/license/dox)](LICENSE.md)


A Haxe documentation generator used by many popular projects such as:

- [Haxe](https://api.haxe.org/)
- [OpenFL](https://api.openfl.org/)
- [HaxeFlixel](https://api.haxeflixel.com/)
- [Heaps](https://heaps.io/api/)
- [Kha](http://api.kha.tech/)
- [Ceramic](https://ceramic-engine.com/api-docs/)

![image](resources/screenshot.png)


## Installation

Install the library via [haxelib](https://lib.haxe.org/p/dox):
```sh
haxelib install dox
```


## Usage

> **Note:** Dox requires Haxe 3.1 or higher due to some minor changes in
abstract rtti xml generation. You'll also need an up-to-date haxelib
(requires support for `classPath` in _haxelib.json_)

1. Compile the code to be included in the documentation using:
   ```sh
   haxe -xml docs/doc.xml -D doc-gen [LIBS] <CLASSPATH> <TARGET> <PACKAGE_NAME>
   ```
   E.g.
   ```sh
   haxe -xml docs/doc.xml -D doc-gen --lib hxargs --classpath src -java bin my.aweseome.package
   ```
2. Generate the HTML pages using:
   ```sh
   haxelib run dox -i <INPUT_DIR>
   ```
   ...where `input_dir` points to the directory containing the generated .xml file(s) of the previous step, i.e.
   ```sh
   haxelib run dox -i docs
   ```

**:clipboard: For more details, custom theme creation and options [check out the Dox wiki](https://github.com/HaxeFoundation/dox/wiki/)**


## Local development

To test Dox locally, clone the git repo, run `npm install` in root directory. This installs the correct Haxe version using lix and all required dependencies.

After that you can run:
```sh
npx haxe --run Make dox xml pages server
```
This compiles Dox, creates XML's, generates the pages and starts a local dev server at <http://localhost:2000>.


## Local development - testing with nektos/act

The GitHub workflow can be run locally using Nekto's [act](https://github.com/nektos/act) command-line tool. To use it:

1. Install docker
1. Install [act](https://github.com/nektos/act)
1. Navigate into the root of your project (where the .github folder is located)
1. Run the command `act`
1. On subsequent re-runs you can use `act -r` to reuse previous container which avoids re-installation of components and thus greatly reduces build time.
