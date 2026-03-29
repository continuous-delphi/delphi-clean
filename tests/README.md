# Tests

This folder contains the initial automated test suite for `delphi-clean.ps1`.

The suite currently includes:

- PSScriptAnalyzer validation for the script source
- tests for common command-line usage
- JSON output verification
- basic cleanup behavior verification in an isolated temporary workspace

The project uses Pester v5.

---

# Running the Tests

From the repository root:

    pwsh ./tests/run-tests.ps1

Or run Pester directly:

    pwsh
    Invoke-Pester -Configuration ./tests/PesterConfig.psd1

Both approaches execute the same test configuration.

---

# Test Structure

tests/
|-- run-tests.ps1
|-- run-tests.bat
|-- PesterConfig.psd1
|-- PSScriptAnalyzerSettings.psd1
|-- Invoke-ScriptAnalyzer.Tests.ps1
|-- delphi-clean.Integration.Tests.ps1
|-- README.md

---

# Prerequisites

Install the required modules:

```powershell
Install-Module Pester -MinimumVersion 5.7.0 -Force -Scope CurrentUser
Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
```

---

# What the Integration Tests Cover

The tests create a temporary workspace and verify that:

- `-WhatIf` does not delete files
- `-Json` returns parseable JSON
- the `standard` level removes generated artifacts
- excluded directories are respected

These tests avoid modifying the repository itself.

---

# Continuous Integration

A typical CI sequence is:

```powershell
pwsh -Command "Install-Module Pester -MinimumVersion 5.7.0 -Force -Scope CurrentUser"
pwsh -Command "Install-Module PSScriptAnalyzer -Force -Scope CurrentUser"
pwsh -NoProfile -File tests/run-tests.ps1
```
