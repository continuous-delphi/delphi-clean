# tests/pwsh/delphi-clean.Version.Tests.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Describe 'delphi-clean.ps1 -Version' {

    BeforeAll {
        $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../')).Path
        $script:ToolPath = Join-Path $script:RepoRoot 'source' 'delphi-clean.ps1'

        if (-not (Test-Path -LiteralPath $script:ToolPath)) {
            throw "Tool script not found: $script:ToolPath"
        }
    }

    Context 'text format (default)' {

        It 'exits with code 0' {
            & $script:ToolPath -Version
            $LASTEXITCODE | Should -Be 0
        }

        It 'outputs a single line' {
            $output = @(& $script:ToolPath -Version)
            $output.Count | Should -Be 1
        }

        It 'output contains the tool name' {
            $output = & $script:ToolPath -Version
            $output | Should -BeLike '*delphi-clean*'
        }

        It 'output contains the version number' {
            $output = & $script:ToolPath -Version
            $output | Should -Match '\d+\.\d+\.\d+'
        }

        It 'produces the same output with -Format text' {
            $default = & $script:ToolPath -Version
            $explicit = & $script:ToolPath -Version -Format text
            $explicit | Should -Be $default
        }

    }

    Context 'json format' {

        It 'exits with code 0' {
            & $script:ToolPath -Version -Format json
            $LASTEXITCODE | Should -Be 0
        }

        It 'output is valid JSON' {
            $output = & $script:ToolPath -Version -Format json
            { $output | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'ok field is true' {
            $result = & $script:ToolPath -Version -Format json | ConvertFrom-Json
            $result.ok | Should -Be $true
        }

        It 'command field is version' {
            $result = & $script:ToolPath -Version -Format json | ConvertFrom-Json
            $result.command | Should -Be 'version'
        }

        It 'tool.name is delphi-clean' {
            $result = & $script:ToolPath -Version -Format json | ConvertFrom-Json
            $result.tool.name | Should -Be 'delphi-clean'
        }

        It 'tool.version matches a semver pattern' {
            $result = & $script:ToolPath -Version -Format json | ConvertFrom-Json
            $result.tool.version | Should -Match '^\d+\.\d+\.\d+$'
        }

    }

    Context 'mutual exclusion with clean parameters' {

        It 'does not accept -Level with -Version' {
            { & $script:ToolPath -Version -Level build } | Should -Throw
        }

        It 'does not accept -RootPath with -Version' {
            { & $script:ToolPath -Version -RootPath 'C:\Fake' } | Should -Throw
        }

    }

}
