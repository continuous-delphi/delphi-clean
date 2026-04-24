# delphi-clean levels

This document defines the default cleanup levels used by `delphi-clean.ps1`.

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
- `*.o`
- `*.a`
- `*.dylib`
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
- `WinARM64EC`
- `Debug`
- `Release`
- `OSX64`
- `OSXARM64`
- `Android`
- `Android64`
- `iOSDevice64`
- `iOSSimulatorArm64`
- `Linux64`
- `LinuxARM64`
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
- `*.mab`
- `TestInsightSettings.ini`


### Additional Directories

- `__recovery`
