# `delphi-clean` Changelog

All notable changes to this project will be documented in this file.

---
## [0.4.0] 2026-03-21

- Add `-IncludeFilePattern` and `-ExcludeDirPattern`
  Mainly to optionally delete *.res as I was not intentionally deleting those
  but it's been leaving my work folders with extra .res files.
  [#2](https://github.com/continuous-delphi/delphi-clean/issues/2)

## [0.3.0] 2026-03-20

- Add `-Version` switch for version reporting
  - Default (text) format: `delphi-clean 0.3.0`
  - JSON format (`-Format json`): machine envelope matching delphi-inspect
    convention: `{"ok":true,"command":"version","tool":{"name":"delphi-clean","version":"0.3.0"}}`
  - `-Version` and clean parameters (`-Level`, `-RootPath`, etc.) are
    mutually exclusive via parameter sets


## [0.2.0] 2026-03-19

- Code review change:
  - Write-Host changed to Write-Information
  - Fix: remove trailing slash after `__recovery/`

## [0.1.0] 2026-03-19

- Initial release of `delphi-clean- utility
- Three different cleanup levels
- Dry-run / WhatIf mode
- ExcludeDirectories option
- Basic tests

<br />
<br />

### `delphi-clean` - a developer tool from Continuous Delphi

![continuous-delphi logo](https://continuous-delphi.github.io/assets/logos/continuous-delphi-480x270.png)

https://github.com/continuous-delphi
