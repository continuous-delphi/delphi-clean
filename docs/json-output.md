# delphi-clean JSON output reference

Pass `-Json` to any invocation to receive a single JSON object on standard
output. All plain-text messages and progress output are suppressed when `-Json`
is active. The exit code is still set normally.

---

## Clean / WhatIf / Check output

This object is returned after a scan, whether or not files are deleted.

```json
{
  "Level": "standard",
  "Root": "C:/code/myproject",
  "ExcludeDirectoryPattern": [".git", ".vs", ".claude"],
  "IncludeFilePattern": [],
  "Mode": "Clean",
  "Disposition": "Permanent",
  "RecycleBin": false,
  "Check": false,
  "FilesFound": 14,
  "DirectoriesFound": 3,
  "FilesDeleted": 14,
  "DirectoriesDeleted": 3,
  "FilesFailed": 0,
  "DirectoriesFailed": 0,
  "BytesFreed": 1491763,
  "DurationMs": 82,
  "Items": [
    { "Type": "File",      "Path": "C:/code/myproject/source/Unit1.dcu", "Deleted": true,  "Size": 4096 },
    { "Type": "Directory", "Path": "C:/code/myproject/Win32",            "Deleted": true,  "Size": 51200 }
  ]
}
```

### Top-level fields

| Field | Type | Description |
|-------|------|-------------|
| `Level` | string | Cleanup level used: `basic`, `standard`, or `deep` |
| `Root` | string | Absolute path of the scanned root directory |
| `ExcludeDirectoryPattern` | string array | Combined list of built-in and user-supplied exclusion patterns |
| `IncludeFilePattern` | string array | Additional file patterns supplied via config or `-IncludeFilePattern` |
| `Mode` | string | `Clean`, `WhatIf`, or `Check` |
| `Disposition` | string | `Permanent` or `Recycle Bin` |
| `RecycleBin` | boolean | Whether `-RecycleBin` was active |
| `Check` | boolean | Whether `-Check` was active |
| `FilesFound` | integer | Total files matched by the scan |
| `DirectoriesFound` | integer | Total directories matched by the scan |
| `FilesDeleted` | integer | Files actually removed (0 in WhatIf/Check) |
| `DirectoriesDeleted` | integer | Directories actually removed (0 in WhatIf/Check) |
| `FilesFailed` | integer | Files that could not be removed (0 in WhatIf/Check) |
| `DirectoriesFailed` | integer | Directories that could not be removed (0 in WhatIf/Check) |
| `BytesFreed` | integer | Bytes freed (Clean), bytes that would be freed (WhatIf), or bytes that need to be freed (Check) |
| `DurationMs` | integer | Elapsed time from start to end of the operation, in milliseconds |
| `Items` | array | Per-item records (see below) |

### Item records (`Items[]`)

Each element in the `Items` array describes one file or directory that was found
during the scan.

| Field | Type | Description |
|-------|------|-------------|
| `Type` | string | `File` or `Directory` |
| `Path` | string | Absolute path to the item |
| `Deleted` | boolean | `true` if the item was actually removed; `false` in WhatIf/Check or after a failure |
| `Size` | integer | Size in bytes. For files, the file length. For directories, the recursive sum of all contained files computed before deletion. |

### `Mode` values

| Value | When set |
|-------|----------|
| `Clean` | Normal run -- items are deleted (or recycled) |
| `WhatIf` | `-WhatIf` was supplied -- scan only, no deletions |
| `Check` | `-Check` was supplied -- scan only, no deletions |

---

## Nothing-to-clean output

When the scan finds no matching artifacts, the same object shape is returned
with zeroed counters and an empty `Items` array.

```json
{
  "Level": "standard",
  "Root": "C:/code/myproject",
  "ExcludeDirectoryPattern": [".git", ".vs", ".claude"],
  "IncludeFilePattern": [],
  "Mode": "Clean",
  "Disposition": "Permanent",
  "RecycleBin": false,
  "Check": false,
  "FilesFound": 0,
  "DirectoriesFound": 0,
  "FilesDeleted": 0,
  "DirectoriesDeleted": 0,
  "FilesFailed": 0,
  "DirectoriesFailed": 0,
  "BytesFreed": 0,
  "DurationMs": 11,
  "Items": []
}
```

---

## -ShowConfig output

When `-ShowConfig -Json` is used, a different object shape is returned
describing the effective merged configuration. No scan or cleanup is performed.

```json
{
  "Root": "C:/code/myproject",
  "ConfigSources": [
    "C:/Users/darian/delphi-clean.json",
    "C:/code/myproject/delphi-clean.json"
  ],
  "Level": "standard",
  "OutputLevel": "detailed",
  "RecycleBin": false,
  "IncludeFilePattern": ["*.res"],
  "ExcludeDirectoryPattern": [".git", ".vs", ".claude", "vendor*"]
}
```

| Field | Type | Description |
|-------|------|-------------|
| `Root` | string | Absolute path that would be used as the scan root |
| `ConfigSources` | string array | Config files that were found and loaded, in priority order (lowest first) |
| `Level` | string | Effective cleanup level |
| `OutputLevel` | string | Effective output verbosity |
| `RecycleBin` | boolean | Whether recycle-bin mode is active |
| `IncludeFilePattern` | string array | Merged additional file patterns |
| `ExcludeDirectoryPattern` | string array | Merged directory exclusion patterns (includes built-in entries) |

---

## -Version output

When `-Version -Format json` is used, a version envelope is returned.

```json
{
  "ok": true,
  "command": "version",
  "tool": {
    "name": "delphi-clean",
    "version": "0.12.0"
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `ok` | boolean | Always `true` |
| `command` | string | Always `"version"` |
| `tool.name` | string | Always `"delphi-clean"` |
| `tool.version` | string | Semantic version of the script |
