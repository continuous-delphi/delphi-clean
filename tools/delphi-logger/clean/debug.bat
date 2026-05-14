@echo off
pushd "%~dp0"
pwsh -NoProfile -File "%~dp0debug.ps1"
pause
popd
