# tests/delphi-clean.RecycleBin.Tests.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'delphi-clean.ps1 -RecycleBin tests' {

  BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../')).Path
    $script:ToolPath = Join-Path $script:RepoRoot 'source' 'delphi-clean.ps1'

    if (-not (Test-Path -LiteralPath $script:ToolPath)) {
      throw "Tool script not found: $script:ToolPath"
    }
  }

  BeforeEach {
    $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("delphi-clean-rb-tests-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:TempRoot | Out-Null

    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'source') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'source\__history') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'source\Win32') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot '.git') | Out-Null

    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.identcache') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\App.exe') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') -Value 'dummy'
  }

  AfterEach {
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
      Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  It 'recycles files -- they no longer exist at original path' {
    & $script:ToolPath -RootPath $script:TempRoot -Level lite -RecycleBin | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeFalse
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.identcache') | Should -BeFalse
  }

  It 'recycles directories -- they no longer exist at original path' {
    & $script:ToolPath -RootPath $script:TempRoot -Level build -RecycleBin | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\__history') | Should -BeFalse
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Win32') | Should -BeFalse
  }

  It 'respects excluded directories when using -RecycleBin' {
    & $script:ToolPath -RootPath $script:TempRoot -Level build -RecycleBin | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') | Should -BeTrue
  }

  It 'supports WhatIf with -RecycleBin -- no files removed' {
    & $script:ToolPath -RootPath $script:TempRoot -Level lite -RecycleBin -WhatIf | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeTrue
  }

  It 'JSON output includes RecycleBin true when -RecycleBin is specified' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level lite -RecycleBin -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $result.RecycleBin | Should -BeTrue
    $result.Disposition | Should -Be 'Recycle Bin'
  }

  It 'JSON output includes RecycleBin false when -RecycleBin is not specified' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level lite -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $result.RecycleBin | Should -BeFalse
    $result.Disposition | Should -Be 'Permanent'
  }

}
