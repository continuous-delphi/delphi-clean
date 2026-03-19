# delphi-clean Build Profiles

This document defines the cleanup profiles used by `delphi-clean.ps1`.

Each profile is cumulative:

- `lite` defines the base cleanup set
- `build` includes everything in `lite`, plus additional build artifacts
- `full` includes everything in `build`, plus additional aggressive cleanup items

---

## `lite` (default)

Safe cleanup of common transient files.

### Files

- `*.dcu`
- `*.identcache`
- `*.bak`
- `*.tmp`
- `*.dsk`
- `*.tvsconfig`
- `*.stat`

### Directories

- `__history`

---

## `build`

Includes everything in `lite`, plus the following additional items.

### Additional Files

- `*.local`
- `*.dproj.local`
- `*.groupproj.local`
- `*.projdata`
- `*.drc`
- `*.map`
- `*.rsm`
- `*.tds`
- `*.bpl`
- `*.dcp`
- `*.bpi`
- `*.so`
- `*.dll`
- `*.exe`
- `*.obj`
- `*.hpp`
- `*.ilc`
- `*.ild`
- `*.ilf`
- `*.ipu`
- `*.ddp`
- `*.prjmgc`
- `*.vlb`
- `dunitx-results.xml`

### Additional Directories

- `Win32`
- `Win64`
- `Debug`
- `Release`
- `OSX64`
- `OSXARM64`
- `Android`
- `Android64`
- `iOSDevice64`
- `Linux64`
- `TMSWeb`

---

## `full`

Includes everything in `build`, plus the following additional items.

### Additional Files

- `*.~*`
- `*.lib`
- `*.fbpInf`
- `*.fbl8`
- `*.fbpbrk`
- `*.fb8lck`
- `TestInsightSettings.ini`


### Additional Directories

- `__recovery`
