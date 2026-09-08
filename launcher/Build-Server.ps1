param([string]$OutputFile)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not $OutputFile) { $OutputFile = Join-Path $projectRoot 'Start-Server.exe' }
& $compiler /nologo /target:exe /platform:x64 ("/out:" + $OutputFile) (Join-Path $PSScriptRoot 'ServerLauncher.cs')
if ($LASTEXITCODE -ne 0) { throw 'Server-Kompilierung fehlgeschlagen.' }
