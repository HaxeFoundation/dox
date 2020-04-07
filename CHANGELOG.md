### 1.4.1 (to be released)

- added a "final" prefix for final classes and interfaces
- added support for deprecation messages on types ([#261](https://github.com/HaxeFoundation/dox/issues/261))
- added support for `@:noCompletion` implying `@:dox(hide)` ([#250](https://github.com/HaxeFoundation/dox/issues/250))
- added a `--keep-field-order` argument ([#258](https://github.com/HaxeFoundation/dox/issues/258))
- added tooltips with descriptions for compiler metadata ([#240](https://github.com/HaxeFoundation/dox/issues/240))
- improved function type printing to use Haxe 4 syntax ([#273](https://github.com/HaxeFoundation/dox/issues/273))
- fixed JS version being used if the node version is not supported (< 8.10.0)
- fixed interfaces with multiple `extends` only showing the first one ([#260](https://github.com/HaxeFoundation/dox/issues/260))
- fixed overloads not being filtered by visibility / metadata ([#272](https://github.com/HaxeFoundation/dox/issues/272))
- fixed anchor links of variables in abstracts ([#215](https://github.com/HaxeFoundation/dox/issues/215))
- fixed `@author` tags showing up in package overview ([#228](https://github.com/HaxeFoundation/dox/issues/228))
- fixed "View Source" being shown for types not defined in .hx files ([#224](https://github.com/HaxeFoundation/dox/issues/224))

### 1.4.0 (March 27, 2020)

- added support for using dox as an API via `dox.Dox.run()` and `-lib dox`
- added support for automatically using a much faster JS version when `node` is available
- changed the order in which fields are shown (first static, then instance fields)
- changed metadata rendering to only show specific ones (instead of hiding specific ones)
- improved how enum abstracts as well as final and optional fields are rendered
- improved various things in the default theme
- fixed last argument of abstract methods being removed instead of implicit `this` ([#266](https://github.com/HaxeFoundation/dox/issues/266))
- removed support for `--interp`

### 1.3.0 (March 11, 2020)

- added keyboard shortcuts to the filter textbox (ctrl+p, up, down, enter, escape)
- added `--include-private` to show private fields and types ([#267](https://github.com/HaxeFoundation/dox/pull/267))
- fixed header having a white border
- fixed footer not always being positioned at the bottom
- fixed duplicated separators at the top of pages with only one platform
