# tests/pwsh/delphi-clean.Config.Tests.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'delphi-clean.ps1 configuration files' {

    BeforeAll {
        $script:RepoRoot    = (Resolve-Path (Join-Path $PSScriptRoot '../../')).Path
        $script:ToolPath    = Join-Path $script:RepoRoot 'source' 'delphi-clean.ps1'
        $script:FixturesDir = Join-Path $PSScriptRoot 'fixtures'

        if (-not (Test-Path -LiteralPath $script:ToolPath)) {
            throw "Tool script not found: $script:ToolPath"
        }
    }

    BeforeEach {
        $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("delphi-clean-cfg-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:TempRoot | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'src') | Out-Null
        Set-Content -LiteralPath (Join-Path $script:TempRoot 'src\Unit1.dcu') -Value 'dummy'  # basic artifact
        Set-Content -LiteralPath (Join-Path $script:TempRoot 'src\App.exe')   -Value 'dummy'  # standard artifact
        Set-Content -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res')  -Value 'dummy'  # custom-pattern artifact
        Set-Content -LiteralPath (Join-Path $script:TempRoot 'src\App.~pas')  -Value 'dummy'  # deep artifact

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

    # -------------------------------------------------------------------------
    Context 'no config files present' {

        It 'uses basic level by default' {
            & $script:ToolPath -RootPath $script:TempRoot | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Unit1.dcu') | Should -BeFalse  # basic cleans .dcu
            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.exe')   | Should -BeTrue   # standard only
        }

        It 'built-in excluded directories are protected with no config files' {
            New-Item -ItemType Directory -Path (Join-Path $script:TempRoot '.git') | Out-Null
            Set-Content -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') -Value 'dummy'

            & $script:ToolPath -RootPath $script:TempRoot | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') | Should -BeTrue
        }
    }

    # -------------------------------------------------------------------------
    Context 'project-level config (delphi-clean.json in RootPath)' {

        It 'applies level from project config' {
            @{ level = 'standard' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.exe') | Should -BeFalse
        }

        It 'CLI -Level overrides config level' {
            @{ level = 'standard' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Unit1.dcu') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.exe')   | Should -BeTrue
        }

        It 'applies includeFilePattern from project config' {
            @{ includeFilePattern = @('*.res') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res') | Should -BeFalse
        }

        It 'CLI -IncludeFilePattern appends to config patterns' {
            @{ includeFilePattern = @('*.res') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')
            Set-Content -LiteralPath (Join-Path $script:TempRoot 'src\App.mab') -Value 'dummy'

            & $script:ToolPath -RootPath $script:TempRoot -Level basic -IncludeFilePattern '*.mab' | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.mab')  | Should -BeFalse
        }

        It 'applies excludeDirectoryPattern from project config' {
            @{ excludeDirectoryPattern = @('vendor*') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')
            New-Item -ItemType Directory -Path (Join-Path $script:TempRoot 'vendor') | Out-Null
            Set-Content -LiteralPath (Join-Path $script:TempRoot 'vendor\Lib.dcu') -Value 'dummy'

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'vendor\Lib.dcu') | Should -BeTrue
        }

        It 'config excludeDirectoryPattern does not remove built-in excludes' {
            @{ excludeDirectoryPattern = @('vendor*') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')
            New-Item -ItemType Directory -Path (Join-Path $script:TempRoot '.git') | Out-Null
            Set-Content -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') -Value 'dummy'

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot '.git\keep.dcu') | Should -BeTrue
        }
    }

    # -------------------------------------------------------------------------
    Context 'local override config (delphi-clean.local.json in RootPath)' {

        It 'local override scalar takes priority over project config scalar' {
            @{ level = 'standard' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')
            @{ level = 'basic' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.local.json')

            & $script:ToolPath -RootPath $script:TempRoot | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.exe') | Should -BeTrue
        }

        It 'local override array appends to project config array' {
            @{ includeFilePattern = @('*.res') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')
            @{ includeFilePattern = @('*.~pas') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.local.json')

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.~pas') | Should -BeFalse
        }
    }

    # -------------------------------------------------------------------------
    Context 'user-level config ($HOME/delphi-clean.json)' {

        It 'user-level config applies when no project config overrides' {
            @{ level = 'standard' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:FakeHome 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.exe') | Should -BeFalse
        }

        It 'project-level scalar overrides user-level scalar' {
            @{ level = 'standard' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:FakeHome 'delphi-clean.json')
            @{ level = 'basic' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.exe') | Should -BeTrue
        }

        It 'user-level includeFilePattern is honored' {
            @{ includeFilePattern = @('*.res') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:FakeHome 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res') | Should -BeFalse
        }

        It 'user-level and project-level includeFilePattern arrays both contribute' {
            @{ includeFilePattern = @('*.res') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:FakeHome 'delphi-clean.json')
            @{ includeFilePattern = @('*.~pas') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.~pas') | Should -BeFalse
        }
    }

    # -------------------------------------------------------------------------
    Context 'array deduplication' {

        It 'duplicate pattern across user and project config appears only once (both files still cleaned)' {
            @{ includeFilePattern = @('*.res') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:FakeHome 'delphi-clean.json')
            @{ includeFilePattern = @('*.res', '*.~pas') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot -Level basic | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\App.~pas') | Should -BeFalse
        }

        It 'duplicate pattern across config and CLI appears only once (file still cleaned)' {
            @{ includeFilePattern = @('*.res') } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:TempRoot 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:TempRoot -Level basic -IncludeFilePattern '*.res' | Out-Null

            Test-Path -LiteralPath (Join-Path $script:TempRoot 'src\Icon.res') | Should -BeFalse
        }
    }

    # -------------------------------------------------------------------------
    Context 'upward traversal (searchParentFolders)' {

        BeforeEach {
            # Three-level structure inside TempRoot:
            # TempRoot/outer/         <- has level=deep config (should be blocked by stop marker)
            #   inner/                <- stop marker: level=standard, searchParentFolders=false
            #     billing/            <- requests traversal, no level of its own
            #       src/
            #     payments/           <- requests traversal, overrides level to basic, adds *.res
            #       src/

            $script:Outer    = Join-Path $script:TempRoot 'outer'
            $script:Inner    = Join-Path $script:Outer 'inner'
            $script:Billing  = Join-Path $script:Inner 'billing'
            $script:Payments = Join-Path $script:Inner 'payments'

            foreach ($sub in @($script:Billing, $script:Payments)) {
                New-Item -ItemType Directory -Path (Join-Path $sub 'src') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $sub 'src\Unit1.dcu') -Value 'dummy'
                Set-Content -LiteralPath (Join-Path $sub 'src\App.exe')   -Value 'dummy'
            }
            Set-Content -LiteralPath (Join-Path $script:Payments 'src\Icon.res') -Value 'dummy'
            Set-Content -LiteralPath (Join-Path $script:Billing  'src\App.~pas') -Value 'dummy'

            # outer: level=deep (must NOT bleed through the stop marker)
            @{ level = 'deep' } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:Outer 'delphi-clean.json')

            # inner: stop marker with level=standard
            @{ level = 'standard'; searchParentFolders = $false } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:Inner 'delphi-clean.json')
        }

        It 'billing inherits level=standard from inner via traversal' {
            @{ searchParentFolders = $true } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:Billing 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:Billing | Out-Null

            Test-Path -LiteralPath (Join-Path $script:Billing 'src\Unit1.dcu') | Should -BeFalse  # standard cleans .dcu
            Test-Path -LiteralPath (Join-Path $script:Billing 'src\App.exe')   | Should -BeFalse  # standard cleans .exe
        }

        It 'billing without traversal does not inherit inner level and stays at basic default' {
            @{ searchParentFolders = $false } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:Billing 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:Billing | Out-Null

            Test-Path -LiteralPath (Join-Path $script:Billing 'src\Unit1.dcu') | Should -BeFalse  # basic cleans .dcu
            Test-Path -LiteralPath (Join-Path $script:Billing 'src\App.exe')   | Should -BeTrue   # basic does not clean .exe
        }

        It 'payments overrides scalar from traversed parent and adds its own include pattern' {
            # payments has level=basic (overrides inner's standard) and adds *.res
            @{ level = 'basic'; includeFilePattern = @('*.res'); searchParentFolders = $true } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:Payments 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:Payments | Out-Null

            Test-Path -LiteralPath (Join-Path $script:Payments 'src\Unit1.dcu') | Should -BeFalse  # basic cleans .dcu
            Test-Path -LiteralPath (Join-Path $script:Payments 'src\App.exe')   | Should -BeTrue   # basic, not standard
            Test-Path -LiteralPath (Join-Path $script:Payments 'src\Icon.res')  | Should -BeFalse  # includeFilePattern
        }

        It 'stop marker prevents traversal past inner; outer level=deep is never applied' {
            # billing requests traversal; traversal hits inner (stop marker, level=standard) and stops
            # outer has level=deep -- if it leaked through, .~pas would be cleaned
            @{ searchParentFolders = $true } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:Billing 'delphi-clean.json')

            & $script:ToolPath -RootPath $script:Billing | Out-Null

            # standard (from inner stop marker) cleans .exe
            Test-Path -LiteralPath (Join-Path $script:Billing 'src\App.exe') | Should -BeFalse
            # deep (from outer) must NOT apply -- .~pas must survive
            Test-Path -LiteralPath (Join-Path $script:Billing 'src\App.~pas') | Should -BeTrue
        }

        It 'searchParentFolders in HOME config does not trigger traversal' {
            # HOME says searchParentFolders=true; this must be ignored
            @{ searchParentFolders = $true } | ConvertTo-Json |
                Set-Content -LiteralPath (Join-Path $script:FakeHome 'delphi-clean.json')

            # payments has no config of its own -> no project/local triggers traversal
            & $script:ToolPath -RootPath $script:Payments | Out-Null

            # Without traversal, no inherited level -> basic default -> .exe preserved
            Test-Path -LiteralPath (Join-Path $script:Payments 'src\App.exe') | Should -BeTrue
        }
    }

    # -------------------------------------------------------------------------
    Context 'fixture files' {

        It 'monorepo-root fixture is valid JSON and contains expected keys' {
            $fixturePath = Join-Path $script:FixturesDir 'monorepo-root.json'
            Test-Path -LiteralPath $fixturePath | Should -BeTrue
            $cfg = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json
            $cfg.level               | Should -Be 'standard'
            $cfg.searchParentFolders | Should -BeFalse
        }

        It 'monorepo-billing fixture is valid JSON' {
            $fixturePath = Join-Path $script:FixturesDir 'monorepo-billing.json'
            { Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'monorepo-payments fixture has level deep and searchParentFolders true' {
            $fixturePath = Join-Path $script:FixturesDir 'monorepo-payments.json'
            $cfg = Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json
            $cfg.level               | Should -Be 'deep'
            $cfg.searchParentFolders | Should -BeTrue
        }
    }
}
