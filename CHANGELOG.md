### 1.4.0 (to be released)

- added support for using dox as an API via `dox.Dox.run()` and `-lib dox`
- changed the order in which fields are shown (first static, then instance fields)
- fixed last argument of abstract methods being removed instead of implicit `this` ([#266](https://github.com/HaxeFoundation/dox/pull/266))

### 1.3.0 (March 11, 2020)

- added keyboard shortcuts to the filter textbox (ctrl+p, up, down, enter, escape)
- added `--include-private` to show private fields and types ([#267](https://github.com/HaxeFoundation/dox/pull/267))
- fixed header having a white border
- fixed footer not always being positioned at the bottom
- fixed duplicated separators at the top of pages with only one platform
