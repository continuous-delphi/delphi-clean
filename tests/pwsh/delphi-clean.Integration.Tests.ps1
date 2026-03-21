# tests/delphi-clean.Integration.Tests.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'delphi-clean.ps1 integration tests' {

  BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../')).Path
    $script:ToolPath = Join-Path $script:RepoRoot 'source' 'delphi-clean.ps1'

    if (-not (Test-Path -LiteralPath $script:ToolPath)) {
      throw "Tool script not found: $script:ToolPath"
    }
  }

  BeforeEach {
    $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("delphi-clean-tests-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:TempRoot | Out-Null

    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'source') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'source\__history') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'source\Win32') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot '.git') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot '.vs') | Out-Null

    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.identcache') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\App.exe') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\App.map') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\Backup.~pas') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\Win32\output.txt') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') -Value 'dummy'
    Set-Content -LiteralPath (Join-Path $script:TempRoot '.vs\keep.exe') -Value 'dummy'
  }

  AfterEach {
    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
      Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  It 'supports WhatIf without deleting files' {
    & $script:ToolPath -RootPath $script:TempRoot -Level build -WhatIf | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\App.exe') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Win32') | Should -BeTrue
  }

  It 'returns parseable JSON output' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level build -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $result.Level | Should -Be 'build'
    $result.FilesFound | Should -BeGreaterThan 0
    $result.DirectoriesFound | Should -BeGreaterThan 0
    @($result.Items).Count | Should -BeGreaterThan 0
  }

  It 'removes build artifacts in build level' {
    & $script:ToolPath -RootPath $script:TempRoot -Level build | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeFalse
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\App.exe') | Should -BeFalse
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Win32') | Should -BeFalse
  }

  It 'respects excluded directories' {
    & $script:ToolPath -RootPath $script:TempRoot -Level build | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $script:TempRoot '.vs\keep.exe') | Should -BeTrue
  }

  It 'keeps full-only backup files during build level cleanup' {
    & $script:ToolPath -RootPath $script:TempRoot -Level build | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Backup.~pas') | Should -BeTrue
  }

  It 'removes full-only backup files during full level cleanup' {
    & $script:ToolPath -RootPath $script:TempRoot -Level full | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Backup.~pas') | Should -BeFalse
  }

  It 'deletes files matching -IncludeFilePattern' {
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\App.res') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level lite -IncludeFilePattern '*.res' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\App.res') | Should -BeFalse
  }

  It 'does not delete -IncludeFilePattern files under excluded directories' {
    Set-Content -LiteralPath (Join-Path $script:TempRoot '.git\keep.res') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level lite -IncludeFilePattern '*.res' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot '.git\keep.res') | Should -BeTrue
  }

  It 'skips files inside directories matching -ExcludeDirPattern' {
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'assets') | Out-Null
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'assets\icon.dcu') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level lite -ExcludeDirPattern 'asset*' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'assets\icon.dcu') | Should -BeTrue
  }

  It 'still cleans files outside -ExcludeDirPattern directories' {
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'assets') | Out-Null
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'assets\icon.dcu') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level lite -ExcludeDirPattern 'asset*' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeFalse
  }

}
