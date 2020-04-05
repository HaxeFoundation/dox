### 1.4.1 (to be released)

- only switch to the JS version if the node version is supported (>= 8.10.0)

### 1.4.0 (March 27, 2020)

- added support for using dox as an API via `dox.Dox.run()` and `-lib dox`
- added support for automatically using a much faster JS version when `node` is available
- changed the order in which fields are shown (first static, then instance fields)
- changed metadata rendering to only show specific ones (instead of hiding specific ones)
- improved how enum abstracts as well as final and optional fields are rendered
- improved various things in the default theme
- fixed last argument of abstract methods being removed instead of implicit `this` ([#266](https://github.com/HaxeFoundation/dox/pull/266))
- removed support for `--interp`

### 1.3.0 (March 11, 2020)

- added keyboard shortcuts to the filter textbox (ctrl+p, up, down, enter, escape)
- added `--include-private` to show private fields and types ([#267](https://github.com/HaxeFoundation/dox/pull/267))
- fixed header having a white border
- fixed footer not always being positioned at the bottom
- fixed duplicated separators at the top of pages with only one platform
