@echo off
cd /d "%~dp0"
"%~dp0Start-Server.exe" %*
if errorlevel 1 (
  echo Serverstart fehlgeschlagen. Details siehe oben und im Ordner logs.
  pause
  exit /b 1
)
