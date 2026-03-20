#requires -Version 7.0
#requires -PSEdition Core

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Set-Location (Split-Path $PSScriptRoot -Parent)

$configPath = Join-Path $PSScriptRoot 'PesterConfig.psd1'

Write-Host 'Running Pester tests...'
Write-Host ''

$config = Import-PowerShellDataFile -LiteralPath $configPath
$result = Invoke-Pester -Configuration $config

Write-Host ''
Write-Host "Tests run: $($result.TotalCount)"
Write-Host "Passed:    $($result.PassedCount)"
Write-Host "Failed:    $($result.FailedCount)"

if ($result.FailedCount -gt 0 -or $result.FailedContainersCount -gt 0) {
    exit 1
}

exit 0
