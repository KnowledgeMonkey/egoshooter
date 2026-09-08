$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$enginePath = Join-Path $projectRoot 'tools/godot/Godot_v4.5-stable_win64_console.exe'
$hostProcess = Start-Process -FilePath $enginePath -ArgumentList '--headless --path . --log-file ./tests/vertical-host.log --script tests/network_peer.gd -- --server --vertical' -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 900
$clientProcess = Start-Process -FilePath $enginePath -ArgumentList '--headless --path . --log-file ./tests/vertical-client.log --script tests/network_peer.gd -- --vertical' -WindowStyle Hidden -PassThru
$clientProcess.WaitForExit()
$hostProcess.WaitForExit()
Get-Content tests/vertical-host.log,tests/vertical-client.log | Select-String 'NETWORK|VERTICAL|FAIL'
if ($hostProcess.ExitCode -ne 0 -or $clientProcess.ExitCode -ne 0) { throw 'Vertikaler LAN-Test fehlgeschlagen.' }
if (Select-String -Path tests/vertical-host.log,tests/vertical-client.log -Pattern 'SCRIPT ERROR|FAIL ') { throw 'Laufzeitfehler im Etagen-LAN-Test.' }
Write-Output 'Client-Treppenaufstieg auf dem Host simuliert und als Obergeschossposition synchronisiert.'
