param([string]$ServerDirectory = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$engine = Join-Path $projectRoot 'tools/godot/Godot_v4.5-stable_win64_console.exe'
& $engine --headless --path . --log-file ./tests/dedicated.log --script tests/dedicated.gd
if ($LASTEXITCODE -ne 0) { throw 'Dedicated-Integration fehlgeschlagen.' }
$serverExe = Join-Path $ServerDirectory 'Start-Server.exe'
$server = $null
$clients = @()
try {
    $server = Start-Process -FilePath $serverExe -WorkingDirectory $ServerDirectory -ArgumentList '--port=27988 --bots=8 --discovery=false --run-for=32' -WindowStyle Hidden -PassThru -RedirectStandardOutput tests/dedicated-server.log -RedirectStandardError tests/dedicated-server-error.log
    $deadline = [DateTime]::UtcNow.AddSeconds(180)
    do {
        Start-Sleep -Milliseconds 200
        if ($server.HasExited) { throw 'Server wurde vorzeitig beendet. Siehe tests/dedicated-server*.log.' }
        $ready = Select-String -Path tests/dedicated-server.log -Pattern 'SERVER READY' -Quiet
    } until ($ready -or [DateTime]::UtcNow -gt $deadline)
    if (-not $ready) { throw 'Server wurde nicht bereit.' }
    foreach ($index in 1..8) {
        $clients += Start-Process -FilePath $engine -ArgumentList "--headless --path . --log-file ./tests/dedicated-client-$index.log --script tests/dedicated_client.gd" -WindowStyle Hidden -PassThru
    }
    foreach ($client in $clients) {
        if (-not $client.WaitForExit(30000)) { throw 'Dedicated-Client Timeout.' }
        if ($client.ExitCode -ne 0) { throw 'Dedicated-Client fehlgeschlagen.' }
    }
    if (-not $server.WaitForExit(45000)) { throw 'Dedicated-Server Timeout.' }
    if ($server.ExitCode -ne 0) { throw 'Dedicated-Server fehlgeschlagen.' }
    if (Get-ChildItem tests -Filter 'dedicated*.log' | Select-String -Pattern 'SCRIPT ERROR|FAIL |SERVER START ERROR') { throw 'Dedicated-Protokolle enthalten Fehler.' }
    Get-ChildItem tests -Filter 'dedicated-client-*.log' | Select-String 'DEDICATED CLIENT'
    Get-Content tests/dedicated-server.log | Select-String 'SERVER READY|SERVER STATUS|SERVER STOP'
    Write-Output 'Dedicated EXE mit acht echten Clients erfolgreich getestet.'
} finally {
    foreach ($client in $clients) { if (-not $client.HasExited) { $client.Kill() } }
    if ($server -and -not $server.HasExited) { $server.Kill() }
}
