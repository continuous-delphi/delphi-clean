# delphi-clean

![delphi-clean logo](https://continuous-delphi.github.io/assets/logos/delphi-clean-480x270.png)

[![Delphi](https://img.shields.io/badge/delphi-red)](https://www.embarcadero.com/products/delphi)
[![CI](https://github.com/continuous-delphi/delphi-clean/actions/workflows/ci.yml/badge.svg)](https://github.com/continuous-delphi/delphi-clean/actions/workflows/ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/continuous-delphi/delphi-clean?display_name=release)](https://github.com/continuous-delphi/delphi-clean/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/continuous-delphi/delphi-clean)
[![Continuous Delphi](https://img.shields.io/badge/org-continuous--delphi-red)](https://github.com/continuous-delphi)

## Overview

`delphi-clean` is a PowerShell utility for Delphi developers to remove build
artifacts, intermediate files, and IDE-generated clutter, with support for
preview, validation, and CI workflows.

---

## Running the Tool

If `delphi-clean` is on your PATH:

```powershell
delphi-clean -Level standard
```

Otherwise, run it directly:

```powershell
pwsh -File .\delphi-clean.ps1 -Level standard
# or
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\delphi-clean.ps1 -Level standard
```

## PowerShell Compatibility

Runs on the widely available Windows PowerShell 5.1 (`powershell.exe`)
and the newer PowerShell 7+ (`pwsh`).

---

## Features

- Specify cleanup levels: `basic`, `standard`, `deep` via `-Level`
- CI-friendly output with optional `-Json` mode
- Optional structured output via `-PassThru`
- Supports the `-WhatIf` dry-run mode
- Add extra file patterns with `-IncludeFilePattern`
- Exclude directories by wildcard pattern with `-ExcludeDirectoryPattern`
- Send items to the recycle bin / trash instead of permanent deletion with `-RecycleBin`
- Use `-OutputLevel` to adjust how much detail is shown.
- Check for cleanup artifacts without modifying files using `-Check`.

---

## Usage

Run `delphi-clean` from the current working directory,
or specify a different root with `-RootPath`

### Basic Usage

```powershell
delphi-clean
```

---

## -RootPath

Root path defaults to the current working directory (via `Get-Location`),
or you can provide it explicitly.

Example:

```powershell
delphi-clean -RootPath C:\code\my-project
```

---

## -WhatIf
Preview cleanup without making changes. (Dry Run Mode)

```powershell
delphi-clean -WhatIf
```

Shows what would be deleted without making changes.

---

## -Verbose

Extra output for debugging purposes

```powershell
delphi-clean -Verbose
```

---

## -PassThru

Structured Output: Returns objects describing each item processed.

```powershell
delphi-clean -PassThru
```

---

## -Json

Outputs a JSON summary including:

- Files found
- Directories found
- Files deleted
- Directories deleted
- Item-level details
- `Disposition` (`Permanent` or `Recycle Bin`) and `RecycleBin` flag

```powershell
delphi-clean -Json
```

---

## -IncludeFilePattern

Appends additional glob patterns to the level's built-in file list. Useful for
project-specific artifacts not covered by the standard levels.

```powershell
delphi-clean -Level basic -IncludeFilePattern '*.res'
delphi-clean -Level basic -IncludeFilePattern '*.res','*.mab'
```

---

## -ExcludeDirectoryPattern

Skips any directory whose name matches one of the given wildcard patterns.
Patterns are matched with `-like` so wildcards (`*`, `?`) are supported.

Specific directories are excluded by default: `.git`, `.vs`, and `.claude`.

```powershell
delphi-clean -ExcludeDirectoryPattern 'vendor*'
delphi-clean -ExcludeDirectoryPattern 'vendor*','assets'
```

---

## -RecycleBin

Sends items to the platform trash instead of permanently deleting them.

| Platform | Destination |
|----------|-------------|
| Windows  | Recycle Bin (`Microsoft.VisualBasic.FileIO`) |
| macOS    | `~/.Trash/` |
| Linux    | `~/.local/share/Trash/` (FreeDesktop spec) |

Combine with `-WhatIf` to preview which items would be recycled without
making any changes.

```powershell
delphi-clean -RecycleBin
delphi-clean -Level standard -RecycleBin
```

---

## -Level

### Clean Levels

#### `basic` (default)

Safe cleanup of common transient files.

Includes:

- `.dcu`, `.tmp`, `.bak`, `.identcache`
- `__history`

---

#### `standard`

Removes build outputs and generated artifacts.

Includes everything in `basic`, plus:

- Compiled binaries (`.exe`, `.bpl`, etc.)
- Debug and release folders
- Intermediate files

---

#### `deep`

More aggressive cleanup

Includes everything in `standard`, plus:

- Backup files (`*.~*`)
- FinalBuilder related files (logs, breakpoint, lock)
- TestInsight custom settings

Examples:

```powershell
delphi-clean -Level basic
delphi-clean -Level standard
delphi-clean -Level deep
```

See [/docs/cleanup-levels.md](/docs/cleanup-levels.md) for breakdown
of what is included by default in each level


---

## -OutputLevel

Use `-OutputLevel` to control how much information `delphi-clean` writes
during execution or check mode.

### Options

- `detailed` (default)
  
  Shows full output including headers, per-item actions (or matches in -Check), and summary totals.

- `summary`

  Suppresses per-item output and shows only high-level information and totals.

- `quiet`

  Suppresses all normal output. Only warnings and errors are displayed.
  Intended for automation scenarios where the exit code is the primary signal.

### Behavior

- Applies to both normal cleanup runs and `-Check` mode
- Does not affect JSON output (`-Json` always returns structured data)
- Warnings and errors are never suppressed, even with quiet
  
### Examples

Show full detail (default):

```powershell
delphi-clean
```

Show only totals:

```powershell
delphi-clean -OutputLevel summary
```

Silent run for CI:

```powershell
delphi-clean -Level standard -OutputLevel quiet
```

### Notes

- `detailed` is useful for interactive use and troubleshooting
- `summary` is ideal for large repositories to reduce noise
- `quiet` is best for scripts where only the exit code matters


## -Check

Use `-Check` to audit a project folder without making any changes.

In check mode, `delphi-clean` performs a full scan using the selected cleanup level
and reports any files or directories that would be removed during a normal run.

No files are deleted, moved, or modified.

```powershell
delphi-clean -Check
```

Output controlled by `-OutputLevel`:

- detailed (default): lists matching items and summary
- summary: totals only
- quiet: no output (use exit code only)

Example: use in CI to validate a workspace

```powershell
delphi-clean -Check -OutputLevel quiet
if ($LASTEXITCODE -ne 0) {
    throw "Repository contains build artifacts"
}
```

Example: view detailed list of matching files:

```powershell
delphi-clean -Level deep -Check -OutputLevel detailed
```

Notes:

- `-Check` cannot be combined with `-WhatIf`
- `-RecycleBin` has no effect in check mode
- For a simulated run that shows what would be deleted during execution, use `-WhatIf`
  
Check vs WhatIf:
- Use `-WhatIf` to preview what a cleanup run would do
- Use `-Check` to determine whether cleanup is needed (with exit code support)

---

## Exit Codes

```text
  0 = success: cleanup completed, WhatIf completed, or Check found no artifacts
  1 = dirty: check mode found artifacts (validation failure)
  2 = partial: the script reached the removal phase but at least one item could not
               be deleted or recycled; 
               Note: successfully removed items are not rolled back
  3 = fatal:   unhandled exception before or during the scan phase - bad root path,
               unsupported platform for -RecycleBin, scan error, etc.
```

---

## Maturity

This repository is currently `incubator` and is under active development.
It will graduate to `stable` once:

- At least one downstream consumer exists.

Until graduation, breaking changes may occur

---

## Continuous-Delphi

This tool is part of the [Continuous-Delphi](https://github.com/continuous-delphi)
ecosystem, focused on strengthening Delphi’s continued success

![continuous-delphi logo](https://continuous-delphi.github.io/assets/logos/continuous-delphi-480x270.png)
