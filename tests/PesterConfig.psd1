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
        OutputPath = './tests/results/coverage.xml'
    }

    TestResult = @{
        Enabled = $false
        OutputFormat = 'NUnitXml'
        OutputPath = './tests/results/pester-results.xml'
    }

    Output = @{
        Verbosity = 'Detailed'
        CIFormat = 'Auto'
    }

    Should = @{
        ErrorAction = 'Stop'
    }
}

