$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$engine = Join-Path $projectRoot 'tools/godot/Godot_v4.5-stable_win64_console.exe'
$server = $null
$clients = @()
try {
    $server = Start-Process -FilePath (Join-Path $projectRoot 'Start-Server.exe') -ArgumentList '--port=27987 --bots=0 --time-limit=60 --round-delay=3 --discovery=false --run-for=76' -WindowStyle Hidden -PassThru -RedirectStandardOutput tests/dedicated-rounds-server.log -RedirectStandardError tests/dedicated-rounds-error.log
    $deadline = [DateTime]::UtcNow.AddSeconds(180)
    do {
        Start-Sleep -Milliseconds 200
        if ($server.HasExited) { throw 'Rundenserver vorzeitig beendet.' }
        $ready = Select-String -Path tests/dedicated-rounds-server.log -Pattern 'SERVER READY' -Quiet
    } until ($ready -or [DateTime]::UtcNow -gt $deadline)
    if (-not $ready) { throw 'Rundenserver wurde nicht bereit.' }
    foreach ($index in 1..2) {
        $clients += Start-Process -FilePath $engine -ArgumentList "--headless --path . --log-file ./tests/dedicated-rounds-client-$index.log --script tests/dedicated_client.gd -- --rounds" -WindowStyle Hidden -PassThru
    }
    foreach ($client in $clients) {
        if (-not $client.WaitForExit(85000) -or $client.ExitCode -ne 0) { throw 'Client-Rundenwechsel fehlgeschlagen.' }
    }
    if (-not $server.WaitForExit(20000) -or $server.ExitCode -ne 0) { throw 'Rundenserver fehlgeschlagen.' }
    if (Get-ChildItem tests -Filter 'dedicated-rounds-*.log' | Select-String 'SCRIPT ERROR|FAIL ') { throw 'Laufzeitfehler im Rundentest.' }
    Get-ChildItem tests -Filter 'dedicated-rounds-*.log' | Select-String 'DEDICATED ROUNDS|SERVER ROUND'
} finally {
    foreach ($client in $clients) { if (-not $client.HasExited) { $client.Kill() } }
    if ($server -and -not $server.HasExited) { $server.Kill() }
}
