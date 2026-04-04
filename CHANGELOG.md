# `delphi-clean` Changelog

All notable changes to this project will be documented in this file.

---

## [0.10.0] 2026-04-04

- Add JSON configuration file hierarchy
  (`$HOME`, project-level, local override, `-ConfigFile`)
  with scalar-override and array-append merge rules and optional
  upward traversal via `searchParentFolders`
  See `docs/configuration.md` for details.

- Add `-ConfigFile <path>` to inject an explicit config file (e.g. for CI
  pipelines) at highest config priority below command-line parameters.

- Add `-ShowConfig` to display the effective merged configuration and exit
  without scanning or cleaning. Supports `-Json` for machine-readable output.

- Add freed-space reporting to the clean summary:
  `Space freed : 142.3 MB` (text) or `BytesFreed` (JSON).
  Also reported in `-Check` mode as `Space to free` and in `-WhatIf` mode
  as `Space would free`.

- Add elapsed time to all summaries (`Duration` in text, `DurationMs` in JSON).

- Add `Size` (bytes) to every item in the JSON `Items` array, covering both
  files (direct length) and directories (recursive sum computed before deletion).

- Add `Write-Progress` feedback during file scan (updates every 500 files) and
  during the deletion phase; suppressed when `-Json` is active.

- Add cross-platform build artifact patterns to the `standard` level:
  `*.o`, `*.a` (Linux/macOS object/static-lib), `*.dylib` (macOS dynamic lib).

- Add `iOSSimulatorArm64` and `LinuxARM64` output directories to the
  `standard` level for Delphi 12+ platform targets.

- Add `*.mab` (MadExcept/JEDI debug map) to the `deep` level.

---

## [0.9.0] 2026-03-30

- Add `-Check` for simple 0:clean, 1:dirty check
- Add `-OutputLevel` with `detailed`, `summary`, `quiet` options
to control the amount of output
  [#17](https://github.com/continuous-delphi/delphi-clean/issues/17)


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
