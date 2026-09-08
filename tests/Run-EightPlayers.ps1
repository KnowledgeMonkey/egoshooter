$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$enginePath = Join-Path $projectRoot 'tools/godot/Godot_v4.5-stable_win64_console.exe'
$hostProcess = Start-Process -FilePath $enginePath -ArgumentList '--headless --path . --log-file ./tests/eight-host.log --script tests/network_peer.gd -- --server --eight' -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 800
$clients = @()
foreach ($clientIndex in 1..7) {
  $clientArguments = '--headless --path . --log-file ./tests/eight-client-' + $clientIndex + '.log --script tests/network_peer.gd -- --eight'
  $clients += Start-Process -FilePath $enginePath -ArgumentList $clientArguments -WindowStyle Hidden -PassThru
}
foreach ($clientProcess in $clients) { $clientProcess.WaitForExit() }
$hostProcess.WaitForExit()
Get-Content tests/eight-*.log | Select-String 'NETWORK|WARNING|FAIL' | Select-Object -First 20
foreach ($clientProcess in $clients) {
  if ($clientProcess.ExitCode -ne 0) { throw 'Ein Client hat den Acht-Spieler-Test nicht bestanden.' }
}
if ($hostProcess.ExitCode -ne 0) { throw 'Der Host hat den Acht-Spieler-Test nicht bestanden.' }
if (Select-String -Path tests/eight-*.log -Pattern 'SCRIPT ERROR|FAIL ') { throw 'Laufzeitfehler im Acht-Spieler-Test.' }
Write-Output 'Ein Host und sieben echte Clientprozesse erfolgreich getestet.'
