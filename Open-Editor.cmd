@echo off
cd /d "%~dp0"
start "BLOCKLINE Editor" "tools\godot\Godot_v4.5-stable_win64.exe" --editor --path "%~dp0."
