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

    # Redirect home config lookup so a real $HOME/delphi-clean.json does not affect results
    $script:FakeHome = Join-Path ([System.IO.Path]::GetTempPath()) ("delphi-clean-home-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:FakeHome | Out-Null
    $env:DELPHI_CLEAN_HOME_OVERRIDE = $script:FakeHome
  }

  AfterEach {
    $env:DELPHI_CLEAN_HOME_OVERRIDE = $null
    foreach ($dir in @($script:TempRoot, $script:FakeHome)) {
      if ($dir -and (Test-Path -LiteralPath $dir)) {
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
      }
    }
  }

  It 'supports WhatIf without deleting files' {
    & $script:ToolPath -RootPath $script:TempRoot -Level standard -WhatIf | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\App.exe') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Win32') | Should -BeTrue
  }

  It 'returns parseable JSON output' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level standard -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $result.Level | Should -Be 'standard'
    $result.FilesFound | Should -BeGreaterThan 0
    $result.DirectoriesFound | Should -BeGreaterThan 0
    @($result.Items).Count | Should -BeGreaterThan 0
  }

  It 'JSON output includes DurationMs as a non-negative integer' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level standard -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $result.PSObject.Properties.Name | Should -Contain 'DurationMs'
    $result.DurationMs | Should -BeGreaterOrEqual 0
  }

  It 'JSON output includes DurationMs when nothing to clean' {
    # Use a root with no artifacts so the nothing-to-clean path is taken
    $emptyRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("delphi-clean-empty-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $emptyRoot | Out-Null
    try {
      $jsonText = & $script:ToolPath -RootPath $emptyRoot -Level standard -Json
      $result = $jsonText | ConvertFrom-Json

      $result.PSObject.Properties.Name | Should -Contain 'DurationMs'
      $result.DurationMs | Should -BeGreaterOrEqual 0
    }
    finally {
      Remove-Item -LiteralPath $emptyRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
  }

  It 'JSON output includes DurationMs in -Check mode' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level standard -Json -Check
    $result = $jsonText | ConvertFrom-Json

    $result.PSObject.Properties.Name | Should -Contain 'DurationMs'
    $result.DurationMs | Should -BeGreaterOrEqual 0
  }

  It 'JSON Items have a Size property on file records' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level standard -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $fileItem = @($result.Items) | Where-Object { $_.Type -eq 'File' } | Select-Object -First 1
    $fileItem | Should -Not -BeNullOrEmpty
    $fileItem.PSObject.Properties.Name | Should -Contain 'Size'
    $fileItem.Size | Should -BeGreaterOrEqual 0
  }

  It 'JSON Items have a Size property on directory records' {
    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level standard -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $dirItem = @($result.Items) | Where-Object { $_.Type -eq 'Directory' } | Select-Object -First 1
    $dirItem | Should -Not -BeNullOrEmpty
    $dirItem.PSObject.Properties.Name | Should -Contain 'Size'
    $dirItem.Size | Should -BeGreaterOrEqual 0
  }

  It 'JSON Items file Size matches the actual file size on disk' {
    # Write a file with known byte content so we can verify the reported size
    $knownContent = 'A' * 128
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\App.map') -Value $knownContent -NoNewline -Encoding ASCII

    $jsonText = & $script:ToolPath -RootPath $script:TempRoot -Level standard -Json -WhatIf
    $result = $jsonText | ConvertFrom-Json

    $mapItem = @($result.Items) | Where-Object { $_.Path -like '*App.map' } | Select-Object -First 1
    $mapItem | Should -Not -BeNullOrEmpty
    $mapItem.Size | Should -Be 128
  }

  It 'removes build artifacts in standard level' {
    & $script:ToolPath -RootPath $script:TempRoot -Level standard | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeFalse
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\App.exe') | Should -BeFalse
    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Win32') | Should -BeFalse
  }

  It 'respects excluded directories' {
    & $script:ToolPath -RootPath $script:TempRoot -Level standard | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $script:TempRoot '.vs\keep.exe') | Should -BeTrue
  }

  It 'keeps deep-only backup files during standard level cleanup' {
    & $script:ToolPath -RootPath $script:TempRoot -Level standard | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Backup.~pas') | Should -BeTrue
  }

  It 'removes deep-only backup files during deep level cleanup' {
    & $script:ToolPath -RootPath $script:TempRoot -Level deep | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Backup.~pas') | Should -BeFalse
  }

  It 'deletes files matching -IncludeFilePattern' {
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'source\App.res') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level basic -IncludeFilePattern '*.res' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\App.res') | Should -BeFalse
  }

  It 'does not delete -IncludeFilePattern files under excluded directories' {
    Set-Content -LiteralPath (Join-Path $script:TempRoot '.git\keep.res') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level basic -IncludeFilePattern '*.res' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot '.git\keep.res') | Should -BeTrue
  }

  It 'skips files inside directories matching -ExcludeDirectoryPattern' {
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'assets') | Out-Null
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'assets\icon.dcu') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level basic -ExcludeDirectoryPattern 'asset*' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'assets\icon.dcu') | Should -BeTrue
  }

  It 'still cleans files outside -ExcludeDirectoryPattern directories' {
    New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'assets') | Out-Null
    Set-Content -LiteralPath (Join-Path $script:TempRoot 'assets\icon.dcu') -Value 'dummy'

    & $script:ToolPath -RootPath $script:TempRoot -Level basic -ExcludeDirectoryPattern 'asset*' | Out-Null

    Test-Path -LiteralPath (Join-Path $script:TempRoot 'source\Unit1.dcu') | Should -BeFalse
  }

}
