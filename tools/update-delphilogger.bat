@echo off
setlocal
pushd "%~dp0"
pwsh -NoProfile -File "C:\code\delphi-logger\tools\Inject-CDHostLog.ps1" -TargetFile "%~dp0..\source\delphi-clean.ps1"
set "EXITCODE=%ERRORLEVEL%"
pause
popd
endlocal & exit /b %EXITCODE%
