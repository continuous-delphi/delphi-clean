# tests/Invoke-ScriptAnalyzer.Tests.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'PSScriptAnalyzer -- delphi-clean.ps1' {

  BeforeAll {
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
      throw 'PSScriptAnalyzer module is not installed. Run: Install-Module PSScriptAnalyzer -Scope CurrentUser'
    }

    Import-Module PSScriptAnalyzer -Force

    $repoRoot     = (Resolve-Path (Join-Path $PSScriptRoot '../../')).Path
    $scriptPath   = Join-Path $repoRoot 'source' 'delphi-clean.ps1'
    $settingsPath = Join-Path $repoRoot 'tests' 'pwsh' 'PSScriptAnalyzerSettings.psd1'

    if (-not (Test-Path -LiteralPath $scriptPath)) {
      throw "Script not found: $scriptPath"
    }

    if (-not (Test-Path -LiteralPath $settingsPath)) {
      throw "Settings file not found: $settingsPath"
    }

    $script:Findings = Invoke-ScriptAnalyzer -Path $scriptPath -Settings $settingsPath
  }

  It 'reports no errors' {
    $errors = @($script:Findings | Where-Object Severity -EQ 'Error')
    $errors | Should -BeNullOrEmpty -Because (
      "PSScriptAnalyzer errors:`n" +
      ($errors | ForEach-Object { "  [$($_.ScriptName):$($_.Line)] $($_.RuleName) -- $($_.Message)" } | Join-String -Separator "`n")
    )
  }

  It 'reports no warnings' {
    $warnings = @($script:Findings | Where-Object Severity -EQ 'Warning')
    $warnings | Should -BeNullOrEmpty -Because (
      "PSScriptAnalyzer warnings:`n" +
      ($warnings | ForEach-Object { "  [$($_.ScriptName):$($_.Line)] $($_.RuleName) -- $($_.Message)" } | Join-String -Separator "`n")
    )
  }

}
