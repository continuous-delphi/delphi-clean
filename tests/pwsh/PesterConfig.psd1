@{
    Run = @{
        Path = @(
            './tests'
        )
        Exit = $false
        PassThru = $true
    }

    Filter = @{
        Tag = @()
        ExcludeTag = @()
    }

    CodeCoverage = @{
        Enabled = $false
        Path = @(
            './source/delphi-clean.ps1'
        )
        OutputFormat = 'JaCoCo'
        OutputPath = './tests/pwsh/results/coverage.xml'
    }

    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnitXml'
        OutputPath = './tests/pwsh/results/pester-results.xml'
    }

    Output = @{
        Verbosity = 'Detailed'
        CIFormat = 'Auto'
    }

    Should = @{
        ErrorAction = 'Stop'
    }
}

