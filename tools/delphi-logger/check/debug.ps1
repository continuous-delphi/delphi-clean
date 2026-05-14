Import-Module ContinuousDelphi.Logger
Initialize-CDLogger -Source 'delphi-clean' -OutputMode Silent -MinimumLevel Trace -CaptureOutput $true

& "$PSScriptRoot\..\..\..\source\delphi-clean.ps1" `
    -Level deep `
    -RootPath 'C:\code\delphi-lexer' `
    -OutputLevel detailed `
    -Check

. "$PSScriptRoot\..\Write-CDDebugLog.ps1"
