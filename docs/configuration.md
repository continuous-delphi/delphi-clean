# delphi-clean configuration files

`delphi-clean` supports optional JSON configuration files that let you encode
per-project and per-user preferences so you do not have to repeat them on the
command line every time.  

Configuration files are hierarchical in nature: 
`$HOME < traversed parents < project < local < -ConfigFile < CLI`

---

## Configuration file names

| File | Location | Purpose |
|------|----------|---------|
| `delphi-clean.json` | `$HOME` directory | User-level defaults applied to every project |
| `delphi-clean.json` | `-RootPath` directory | Project-level settings committed with the repository |
| `delphi-clean.local.json` | `-RootPath` directory | User-local overrides (typically not committed - add to `.gitignore`) |

The `-RootPath` directory defaults to the current working directory when the
flag is not supplied on the command line.

---

## Priority order

Sources are listed from lowest to highest priority:

```
$HOME/delphi-clean.json          (user-level)
  <RootPath>/delphi-clean.json   (project-level)
    <RootPath>/delphi-clean.local.json  (local user overrides)
      -ConfigFile <path>                (explicit file, e.g. for CI)
        command-line parameters         (highest priority)
```

---

## Merge rules

**Scalars override.** The highest-priority source that specifies a scalar
value wins. Lower-priority sources are ignored for that property.

**Arrays append.** Every source contributes its array items. All items from
all sources are combined into a single list. Lower-priority items appear before
higher-priority items in the merged result. Duplicate entries are removed;
the first occurrence (lowest-priority source) is kept and later duplicates
are discarded.

Example: the user-level config adds `*.res` to `includeFilePattern`, the
project config adds `*.mab`, and the command line supplies `*.myext`. The
effective pattern list is `["*.res", "*.mab", "*.myext"]`. If two sources
both list `*.res`, it appears only once at the position contributed by the
lower-priority source.

This design means project and user configs are additive -- a project can
extend the user's patterns without erasing them, and a local override can
extend the project's patterns without erasing those.

---

## JSON format

All keys are optional. Omit any key you do not want to set.

```json
{
  "level": "standard",
  "outputLevel": "summary",
  "recycleBin": false,
  "includeFilePattern": ["*.res", "*.mab"],
  "excludeDirectoryPattern": ["vendor*", "assets"],
  "searchParentFolders": false
}
```

### Supported keys

| Key | Type | Equivalent CLI flag | Description |
|-----|------|---------------------|-------------|
| `level` | string | `-Level` | Cleanup level: `basic`, `standard`, or `deep` |
| `outputLevel` | string | `-OutputLevel` | Verbosity: `detailed`, `summary`, or `quiet` |
| `recycleBin` | boolean | `-RecycleBin` | Send items to the platform trash instead of deleting permanently |
| `includeFilePattern` | string array | `-IncludeFilePattern` | Additional glob patterns to remove |
| `excludeDirectoryPattern` | string array | `-ExcludeDirectoryPattern` | Directory name patterns to skip |
| `searchParentFolders` | boolean | _(config only)_ | Enable upward traversal for additional project configs (see below) |

Keys not listed above (such as `-Check`, `-WhatIf`, `-PassThru`, `-Json`,
`-RootPath`) are intentionally excluded from the config format because they
represent invocation-specific behavior rather than persistent preferences.

---

## `-ConfigFile` -- explicit config path

Pass an explicit JSON config file path on the command line to inject a config
at the highest priority below CLI parameters. This is useful in CI pipelines
where the config lives outside the repository tree, or when testing a config
before committing it:

```powershell
delphi-clean -RootPath C:/code/myproject -ConfigFile C:/ci/delphi-clean-ci.json
```

`-ConfigFile` uses the same JSON format as the project-level file. Its scalars
override everything in the fixed-location hierarchy; its arrays append after
(and deduplicate with) items from all lower-priority sources.

---

## `-ShowConfig` -- inspect the effective configuration

Pass `-ShowConfig` to display the merged configuration that would be used for
the current invocation and exit without scanning or cleaning. No files are
modified.

```powershell
delphi-clean -RootPath C:/code/myproject -ShowConfig
```

The output lists every config file that was loaded and the final effective
value for each property, including built-in excluded directories and any
CLI overrides already applied.

Add `-Json` to get machine-readable output:

```powershell
delphi-clean -RootPath C:/code/myproject -ShowConfig -Json
```

---

## Upward traversal (`searchParentFolders`)

By default, `delphi-clean` reads only the three fixed locations listed above.
Upward traversal is triggered only when one of those fixed-location configs
requests it -- typically the project-level `delphi-clean.json` or the local
`delphi-clean.local.json` at `-RootPath`. The `searchParentFolders` key is
ignored in the `$HOME` user-level config; user-level settings are global by
definition and do not participate in project-tree traversal.

When traversal is enabled, the tool walks from the `-RootPath` directory toward
the filesystem root, collecting a `delphi-clean.json` at each parent level it
finds one.

Traversal stops when either of these conditions is met:

- The filesystem root is reached.
- A `delphi-clean.json` is found that contains `"searchParentFolders": false`.
  That file acts as a root marker and is included in the merge, but no further
  parent directories are searched.

The priority of traversed files relative to one another follows proximity:
the file nearest to `-RootPath` has higher priority than a file found further
up the directory tree. All traversed files remain lower priority than the
three fixed locations and the command line.

Extended priority order with traversal enabled (lowest to highest):

```
$HOME/delphi-clean.json          (user-level, lowest -- searchParentFolders ignored here)
  <ancestor>/delphi-clean.json   (farthest parent found via traversal)
    ...
      <parent>/delphi-clean.json (nearest parent found via traversal)
        <RootPath>/delphi-clean.json   (project-level)
          <RootPath>/delphi-clean.local.json  (local user overrides)
            -ConfigFile <path>                (explicit file, e.g. for CI)
              command-line parameters         (highest priority)
```

Traversed parent configs slot between the user-level `$HOME` config and the
project-level config at `-RootPath`. A closer ancestor always outranks a
farther one, and all traversed configs outrank the global user defaults.

### Recommended pattern for monorepos

Place a `delphi-clean.json` with `"searchParentFolders": false` at the
repository root to act as a stop marker. Sub-projects can then enable
traversal with `"searchParentFolders": true` to inherit the root config
without accidentally walking out of the repository.

---

## Config file examples

### `$HOME/delphi-clean.json` (user-level defaults)

```json
{
  "outputLevel": "summary",
  "recycleBin": true,
  "excludeDirectoryPattern": ["vendor*"]
}
```

### `<RootPath>/delphi-clean.json` (project-level, committed to source control)

```json
{
  "level": "standard",
  "includeFilePattern": ["*.res"],
  "excludeDirectoryPattern": ["assets"],
  "searchParentFolders": false
}
```

### `<RootPath>/delphi-clean.local.json` (local user overrides, not committed)

```json
{
  "level": "deep",
  "outputLevel": "detailed"
}
```

### Effective configuration after merge

Given the three files above plus no command-line flags:

| Property | Resolved value | Winning source |
|----------|---------------|----------------|
| `level` | `deep` | local override |
| `outputLevel` | `detailed` | local override |
| `recycleBin` | `true` | user-level |
| `includeFilePattern` | `["*.res"]` | project-level |
| `excludeDirectoryPattern` | `["vendor*", "assets"]` | user-level + project-level (appended) |
| `searchParentFolders` | `false` | project-level |

---

## Monorepo traversal example

This example shows upward traversal across a monorepo where two sub-projects
share a common root config but one of them overrides part of it.

### Directory layout

```
C:/code/acme-suite/
  delphi-clean.json          <-- repo root (stop marker)
  billing/
    delphi-clean.json        <-- billing sub-project
  payments/
    delphi-clean.json        <-- payments sub-project
    delphi-clean.local.json  <-- developer's local override (not committed)
```

### `C:/code/acme-suite/delphi-clean.json` (repo root -- stop marker)

```json
{
  "level": "standard",
  "excludeDirectoryPattern": ["vendor*"],
  "searchParentFolders": false
}
```

The `searchParentFolders: false` here acts as a boundary. No config above this
directory will ever be read, regardless of what sub-project configs request.

### `C:/code/acme-suite/billing/delphi-clean.json`

```json
{
  "searchParentFolders": true
}
```

Minimal config. Enables traversal so the billing project inherits the repo root
settings. Adds nothing else of its own.

### `C:/code/acme-suite/payments/delphi-clean.json`

```json
{
  "level": "deep",
  "includeFilePattern": ["*.res"],
  "searchParentFolders": true
}
```

Overrides `level` to `deep` and adds a custom pattern. Still inherits
`excludeDirectoryPattern` from the repo root.

### `C:/code/acme-suite/payments/delphi-clean.local.json` (not committed)

```json
{
  "outputLevel": "detailed"
}
```

One developer's personal preference for verbose output in the payments project.

---

### Effective configuration when run from each sub-project

Running `delphi-clean -RootPath C:/code/acme-suite/billing`:

| Property | Resolved value | Source(s) |
|----------|---------------|-----------|
| `level` | `standard` | repo root (traversed) |
| `outputLevel` | `detailed` | built-in default |
| `excludeDirectoryPattern` | `["vendor*"]` | repo root (traversed) |
| `includeFilePattern` | `[]` | (none set) |
| `searchParentFolders` | `true` | billing project |

Traversal path: billing config (`searchParentFolders: true`) -> walks up ->
finds repo root config (`searchParentFolders: false`) -> stops.

---

Running `delphi-clean -RootPath C:/code/acme-suite/payments`:

| Property | Resolved value | Source(s) |
|----------|---------------|-----------|
| `level` | `deep` | payments project (overrides repo root) |
| `outputLevel` | `detailed` | local override |
| `excludeDirectoryPattern` | `["vendor*"]` | repo root (traversed, appended) |
| `includeFilePattern` | `["*.res"]` | payments project |
| `searchParentFolders` | `true` | payments project |

Traversal path: payments local -> payments project (`searchParentFolders: true`)
-> walks up -> finds repo root (`searchParentFolders: false`) -> stops.

The `level` scalar from the payments project config takes precedence over the
repo root's `standard` because the payments config is closer to RootPath (higher
priority). The `excludeDirectoryPattern` array from the repo root is preserved
because arrays append rather than replace.

---

## Debugging configuration resolution

Pass `-Verbose` to see exactly which config files were found and what the final
merged values are. This is the primary tool for diagnosing unexpected behavior.

Example output when running from the `payments` sub-project in the monorepo
example above:

```
VERBOSE: [config] loaded user-level:    $HOME/delphi-clean.json
VERBOSE: [config]   level        = (not set)
VERBOSE: [config]   outputLevel  = (not set)

VERBOSE: [config] loaded traversed:     C:/code/acme-suite/delphi-clean.json
VERBOSE: [config]   level        = standard
VERBOSE: [config]   excludeDirectoryPattern += ["vendor*"]
VERBOSE: [config]   searchParentFolders = false  (stop marker -- traversal ends here)

VERBOSE: [config] loaded project-level: C:/code/acme-suite/payments/delphi-clean.json
VERBOSE: [config]   level        = deep
VERBOSE: [config]   includeFilePattern += ["*.res"]
VERBOSE: [config]   searchParentFolders = true

VERBOSE: [config] loaded local override: C:/code/acme-suite/payments/delphi-clean.local.json
VERBOSE: [config]   outputLevel  = detailed

VERBOSE: [config] final merged values:
VERBOSE: [config]   level                  = deep          (payments/delphi-clean.json)
VERBOSE: [config]   outputLevel            = detailed       (payments/delphi-clean.local.json)
VERBOSE: [config]   recycleBin             = false          (default)
VERBOSE: [config]   includeFilePattern     = ["*.res"]      (payments/delphi-clean.json)
VERBOSE: [config]   excludeDirectoryPattern = ["vendor*"]   (acme-suite/delphi-clean.json)
VERBOSE: [config]   searchParentFolders    = true           (payments/delphi-clean.json)
```

Each `+=` line indicates an array append. Each `=` line for a scalar shows the
value that will take effect; if a higher-priority source later sets the same
scalar, that earlier line is superseded and the winning source is shown in the
final merged values block.

Config files that were searched but not found are not listed. If a file you
expect to be loaded is absent from the verbose output, it was not found at the
path that was searched.

---

## `.gitignore` recommendation

The `.local.json` file is intended for personal settings that vary by
developer and should not be committed. Add it to your repository's
`.gitignore`:

```
delphi-clean.local.json
```
