# delphi-clean

![delphi-clean logo](https://continuous-delphi.github.io/assets/logos/delphi-clean-480x270.png)

[![Delphi](https://img.shields.io/badge/delphi-red)](https://www.embarcadero.com/products/delphi)
[![CI](https://github.com/continuous-delphi/delphi-clean/actions/workflows/ci.yml/badge.svg)](https://github.com/continuous-delphi/delphi-clean/actions/workflows/ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/continuous-delphi/delphi-clean?display_name=release)](https://github.com/continuous-delphi/delphi-clean/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/continuous-delphi/delphi-clean)
[![Continuous Delphi](https://img.shields.io/badge/org-continuous--delphi-red)](https://github.com/continuous-delphi)

## Overview

`delphi-clean` is a PowerShell utility designed for Delphi developers to help remove
build artifacts, intermediate files, and IDE-generated clutter.

---

## Example Workflow

```powershell
# Preview cleanup
pwsh -File .\delphi-clean.ps1 -WhatIf

# Perform cleanup
pwsh -File .\delphi-clean.ps1

# CI usage
pwsh -File .\delphi-clean.ps1 -Level full -Json
```


## Features

- Three cleanup levels: `lite`, `build`, `full`
- CI-friendly output with optional JSON mode
- Optional structured output via `-PassThru`
- Supports the `-WhatIf` dry-run mode
- Add extra file patterns with `-IncludeFilePattern`
- Exclude directories by wildcard pattern with `-ExcludeDirPattern`
- Send items to the recycle bin / trash instead of permanent deletion with `-RecycleBin`

---

## PowerShell Compatibility

Runs on the widely available Windows PowerShell 5.1 (powershell.exe)
and the newer PowerShell 7+ (pwsh).

---

## Usage

Run the script from its directory, or provide a path explicitly.

### Basic Usage

```powershell
pwsh -File .\delphi-clean.ps1
```

Defaults to:

- Level: `lite`
- Root: parent directory of the script

---

### Specify Level

```powershell
pwsh -File .\delphi-clean.ps1 -Level lite
pwsh -File .\delphi-clean.ps1 -Level build
pwsh -File .\delphi-clean.ps1 -Level full
```

---

### Specify Root Path

```powershell
pwsh -File .\delphi-clean.ps1 -RootPath C:\code\my-project
```

---

### Dry Run (Recommended First)

```powershell
pwsh -File .\delphi-clean.ps1 -WhatIf
```

Shows what would be deleted without making changes.

---

### Verbose Output

```powershell
pwsh -File .\delphi-clean.ps1 -Verbose
```

---

### PassThru (Structured Output)

```powershell
pwsh -File .\delphi-clean.ps1 -PassThru
```

Returns objects describing each item processed.

---

### JSON Output (CI-friendly)

```powershell
pwsh -File .\delphi-clean.ps1 -Json
```

Outputs a JSON summary including:

- Files found
- Directories found
- Files deleted
- Directories deleted
- Item-level details
- `Disposition` (`Permanent` or `Recycle Bin`) and `RecycleBin` flag

---

### Exclude Directories

```powershell
pwsh -File .\delphi-clean.ps1 -ExcludeDirectories .git,.vs,.idea
```

Matches exact directory names. Default exclusions are `.git`, `.vs`, and `.claude`.

---

### Include Extra File Patterns

```powershell
pwsh -File .\delphi-clean.ps1 -Level lite -IncludeFilePattern '*.res'
pwsh -File .\delphi-clean.ps1 -Level lite -IncludeFilePattern '*.res','*.mab'
```

Appends additional glob patterns to the level's built-in file list. Useful for
project-specific artifacts not covered by the standard levels.

---

### Exclude Directory Patterns

```powershell
pwsh -File .\delphi-clean.ps1 -ExcludeDirPattern 'vendor*'
pwsh -File .\delphi-clean.ps1 -ExcludeDirPattern 'vendor*','assets'
```

Skips any directory whose name matches one of the given wildcard patterns.
Unlike `-ExcludeDirectories`, patterns are matched with `-like` so wildcards
(`*`, `?`) are supported.

---

### Recycle Bin

```powershell
pwsh -File .\delphi-clean.ps1 -RecycleBin
pwsh -File .\delphi-clean.ps1 -Level build -RecycleBin
```

Sends items to the platform trash instead of permanently deleting them.

| Platform | Destination |
|----------|-------------|
| Windows  | Recycle Bin (`Microsoft.VisualBasic.FileIO`) |
| macOS    | `~/.Trash/` |
| Linux    | `~/.local/share/Trash/` (FreeDesktop spec) |

Combine with `-WhatIf` to preview which items would be recycled without
making any changes.

---

## Clean Levels

- see: [/docs/cleanup-levels.md](/docs/cleanup-levels.md) for breakdown of each level

### `lite` (default)

Safe cleanup of common transient files.

Includes:

- `.dcu`, `.tmp`, `.bak`, `.identcache`
- `__history`

---

### `build`

Removes build outputs and generated artifacts.

Includes everything in `lite`, plus:

- Compiled binaries (`.exe`, `.bpl`, etc.)
- Debug and release folders
- Intermediate files

---

### `full`

More aggressive cleanup

Includes everything in `build`, plus:

- Backup files (`*.~*`)
- FinalBuilder related files (logs, breakpoint, lock)
- TestInsight custom settings

---

## Maturity

This repository is currently `incubator` and is under active development.
It will graduate to `stable` once:

- At least one downstream consumer exists.

Until graduation, breaking changes may occur

## Continuous-Delphi

This tool is part of the [Continuous-Delphi](https://github.com/continuous-delphi)
ecosystem, focused on improving engineering discipline for long-lived Delphi systems.

![continuous-delphi logo](https://continuous-delphi.github.io/assets/logos/continuous-delphi-480x270.png)
