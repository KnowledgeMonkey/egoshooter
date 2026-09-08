@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0Start-Game.exe" (
  echo Start-Game.exe fehlt. Bitte den kompletten Spielordner verwenden.
  pause
  exit /b 1
)
"%~dp0Start-Game.exe" %*
exit /b %errorlevel%
