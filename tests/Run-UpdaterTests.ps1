$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$testOutput = Join-Path $env:TEMP ('blockline-updater-tests-' + [guid]::NewGuid().ToString('N') + '.exe')
try {
    & $compiler /nologo /target:exe /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll "/out:$testOutput" (Join-Path $PSScriptRoot 'UpdaterTests.cs') (Join-Path $PSScriptRoot '../launcher/Updater.cs')
    if ($LASTEXITCODE -ne 0) { throw 'Test-Kompilierung fehlgeschlagen.' }
    & $testOutput
    if ($LASTEXITCODE -ne 0) { throw 'Updater-Tests fehlgeschlagen.' }
} finally {
    if (Test-Path -LiteralPath $testOutput) { Remove-Item -LiteralPath $testOutput }
}
