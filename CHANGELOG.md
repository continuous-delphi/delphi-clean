# `delphi-clean` Changelog

All notable changes to this project will be documented in this file.

---

## [0.8.0] 2026-03-30

- Fix `-WhatIf` not displaying a summary of file+directory count to
be deleted.
  [#10](https://github.com/continuous-delphi/delphi-clean/issues/10)

- Fix `-WhatIf` not displaying individual files+directories to be
deleted.
  [#13](https://github.com/continuous-delphi/delphi-clean/issues/13)

- Combine `ExcludeDirPattern` and `ExcludeDirectories` into a
single `ExcludeDirectoryPattern` parameter
  [#14](https://github.com/continuous-delphi/delphi-clean/issues/14)

- Document supported exit codes in Readme
  [#11](https://github.com/continuous-delphi/delphi-clean/issues/11) 
  
- Debugging tool: output `Exit Code = #` when using `-Verbose`
  [#12](https://github.com/continuous-delphi/delphi-clean/issues/12)

## [0.7.0] 2026-03-29

- Move to "basic+standard+deep" cleanup levels
  [#8](https://github.com/continuous-delphi/delphi-clean/issues/8)

## [0.6.0] 2026-03-26

- More conservative clean
  Remove `*.dll` + `*.obj` from clean list
  User will need to add with `-IncludeFiles` if desired
  May revisit this later...maybe add an `Extended` level
  [#5](https://github.com/continuous-delphi/delphi-clean/issues/5)
  [#6](https://github.com/continuous-delphi/delphi-clean/issues/6)

## [0.5.0] 2026-03-25

- Add `-RecycleBin` option to move to recycle bin instead of permanent delete
  [#3](https://github.com/continuous-delphi/delphi-clean/issues/3)

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
