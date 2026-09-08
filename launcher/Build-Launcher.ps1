$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$output = Join-Path $projectRoot 'Start-Game.exe'
$source = Join-Path $PSScriptRoot 'Launcher.cs'
& $compiler /nologo /target:winexe /reference:System.Windows.Forms.dll "/out:$output" $source
if ($LASTEXITCODE -ne 0) { throw 'Launcher-Kompilierung fehlgeschlagen.' }
