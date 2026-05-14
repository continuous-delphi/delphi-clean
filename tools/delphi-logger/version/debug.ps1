Import-Module ContinuousDelphi.Logger
Initialize-CDLogger -Source 'delphi-clean' -OutputMode Silent -MinimumLevel Trace -CaptureOutput $true

& "$PSScriptRoot\..\..\..\source\delphi-clean.ps1" `
    -Version `
    -Format text

. "$PSScriptRoot\..\Write-CDDebugLog.ps1"
