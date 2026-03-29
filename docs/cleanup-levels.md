# delphi-clean levels

This document defines the cleanup levels and per-invocation extension
parameters used by `delphi-clean.ps1`.

Each level is cumulative:

- `basic` defines the base cleanup set
- `standard` includes everything in `basic`, plus additional build artifacts
- `deep` includes everything in `standard`, plus additional aggressive cleanup items

---

## LEVEL=`basic` (default)

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

## LEVEL=`standard`

Includes everything in `basic, plus the following additional items.

### Additional Files

- `*.drc`
- `*.map`
- `*.rsm`
- `*.tds`
- `*.bpl`
- `*.dcp`
- `*.bpi`
- `*.so`
- `*.exe`
- `*.hpp`
- `*.dres`
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

## LEVEL=`deep`

Includes everything in `standard`, plus the following additional items.

### Additional Files

- `*.local`
- `*.dproj.local`
- `*.groupproj.local`
- `*.projdata`
- `*.~*`
- `*.lib`
- `*.fbpInf`
- `*.fbl8`
- `*.fbpbrk`
- `*.fb8lck`
- `TestInsightSettings.ini`


### Additional Directories

- `__recovery`

---

## Per-invocation extension parameters

These parameters are independent of the chosen level and can be combined
with any level.

### `-IncludeFilePattern <string[]>`

Adds one or more extra wildcard file patterns to the deletion set for this
run.  Use this for project-specific files that are intentionally omitted
from the built-in levels.

Example -- delete compiled resource files in addition to the `basic` set:

    delphi-clean.ps1 -Level basic -IncludeFilePattern '*.res'

Example -- delete multiple extra patterns:

    delphi-clean.ps1 -Level standard -IncludeFilePattern '*.res','*.mab'

### `-ExcludeDirPattern <string[]>`

Skips any directory whose name matches one of the supplied wildcard
patterns.  This supplements the fixed `-ExcludeDirectories` list and is
useful when a project folder (such as `assets` or a vendor subtree)
contains files that would otherwise match the cleanup patterns.

Example -- protect an assets folder from cleanup:

    delphi-clean.ps1 -Level basic -ExcludeDirPattern 'assets'

Example -- wildcard to protect all vendor-prefixed folders:

    delphi-clean.ps1 -Level standard -ExcludeDirPattern 'vendor*'

Both parameters may be combined:

    delphi-clean.ps1 -Level basic -IncludeFilePattern '*.res' -ExcludeDirPattern 'assets','vendor*'

### `-RecycleBin`

Sends deleted items to the platform trash instead of permanently removing them.
Supported on Windows (Recycle Bin), macOS (`~/.Trash/`), and Linux
(`~/.local/share/Trash/` per the FreeDesktop spec).

Example:

    delphi-clean.ps1 -Level standard -RecycleBin

Can be combined with `-WhatIf` to preview which items would be recycled without
making any changes:

    delphi-clean.ps1 -Level standard -RecycleBin -WhatIf
