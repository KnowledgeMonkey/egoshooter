$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$enginePath = Join-Path (Get-Location) 'tools/godot/Godot_v4.5-stable_win64_console.exe'
$hostRun = Start-Process $enginePath -ArgumentList '--headless --path . --script tests/classes_network.gd --log-file logs/classes-host.log -- --server' -WindowStyle Hidden -PassThru
try {
    Start-Sleep -Milliseconds 800
    $clientRun = Start-Process $enginePath -ArgumentList '--headless --path . --script tests/classes_network.gd --log-file logs/classes-client.log' -WindowStyle Hidden -PassThru
    try {
        if (-not $clientRun.WaitForExit(30000)) { throw 'Klassen-Client Timeout' }
        if (-not $hostRun.WaitForExit(30000)) { throw 'Klassen-Host Timeout' }
        if ($clientRun.ExitCode -ne 0 -or $hostRun.ExitCode -ne 0) { throw 'Klassen-LAN-Test fehlgeschlagen' }
        if (Select-String -Path logs/classes-host.log,logs/classes-client.log -Pattern 'SCRIPT ERROR|ERROR:|FAIL ') { throw 'Laufzeitfehler im Klassen-LAN-Test' }
        Get-Content logs/classes-host.log,logs/classes-client.log | Select-String 'CLASSES LAN'
    } finally {
        if (-not $clientRun.HasExited) { $clientRun.Kill() }
    }
} finally {
    if (-not $hostRun.HasExited) { $hostRun.Kill() }
}
