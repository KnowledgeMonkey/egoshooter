@echo off
setlocal
cd /d "%~dp0"
"%~dp0Start-Game.exe" --local %*
exit /b %errorlevel%
