@echo off
setlocal

set "HAS_PROFILE="

for %%A in (%*) do (
    if /I "%%~A"=="-Level" set "HAS_PROFILE=1"
)

if defined HAS_PROFILE (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0delphi-clean.ps1" %*
) else (
    rem default to basic mode and pause after completion
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0delphi-clean.ps1" -Level basic %*
    pause
)

exit /b %ERRORLEVEL%
