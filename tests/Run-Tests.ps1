$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$enginePath = Join-Path $projectRoot 'tools/godot/Godot_v4.5-stable_win64_console.exe'
if (!(Test-Path -LiteralPath $enginePath)) { throw 'Godot fehlt. Bitte tools/godot bereitstellen oder enginePath anpassen.' }
& $enginePath --headless --path . --log-file ./tests/integration.log --script tests/integration.gd
if ($LASTEXITCODE -ne 0) { throw 'Integrationstests fehlgeschlagen.' }
& $enginePath --headless --path . --log-file ./tests/killcam.log --script tests/killcam.gd
if ($LASTEXITCODE -ne 0) { throw 'Killcam-Tests fehlgeschlagen.' }
& $enginePath --headless --path . --log-file ./tests/redesign.log --script tests/redesign.gd
if ($LASTEXITCODE -ne 0) { throw 'Waffen- oder Bot-Schwierigkeitstest fehlgeschlagen.' }
& $enginePath --headless --path . --log-file ./tests/graphics.log --script tests/graphics.gd
if ($LASTEXITCODE -ne 0) { throw 'Grafik-Ressourcenprüfung fehlgeschlagen.' }
& $enginePath --headless --path . --log-file ./tests/operator-metrics.log --script tests/operator_metrics.gd
if ($LASTEXITCODE -ne 0) { throw 'Operator-Modellprüfung fehlgeschlagen.' }
& $enginePath --headless --path . --log-file ./tests/expansion.log --script tests/expansion.gd
if ($LASTEXITCODE -ne 0) { throw 'Etagen- oder Kartenerweiterungstest fehlgeschlagen.' }
& $enginePath --headless --path . --log-file ./tests/features.log --script tests/features.gd
if ($LASTEXITCODE -ne 0) { throw 'Neue Gameplay-Funktionen fehlgeschlagen.' }
& $enginePath --headless --path . --log-file ./tests/fps.log --script tests/fps.gd
if ($LASTEXITCODE -ne 0) { throw "FPS feature tests failed." }
& $enginePath --headless --path . --log-file ./tests/handling.log --script tests/handling.gd
if ($LASTEXITCODE -ne 0) { throw "Weapon handling tests failed." }
& $enginePath --headless --path . --log-file ./tests/war-district.log --script tests/war_district.gd
if ($LASTEXITCODE -ne 0) { throw "War district tests failed." }
foreach ($suite in @('arsenal_shield', 'skins', 'killstreaks', 'ttk_muzzle')) {
    & $enginePath --headless --path . --log-file "./tests/$suite.log" --script "tests/$suite.gd"
    if ($LASTEXITCODE -ne 0) { throw "$suite failed." }
    if (Select-String -Path "tests/$suite.log" -Pattern 'SCRIPT ERROR|FAIL ') { throw "$suite runtime error." }
}
& ./tests/Run-StreakNetwork.ps1
& ./tests/Run-FpsNetwork.ps1
& ./tests/Run-RopeNetwork.ps1
$hostProcess = Start-Process -FilePath $enginePath -ArgumentList '--headless --path . --log-file ./tests/network-host.log --script tests/network_peer.gd -- --server --killcam' -WindowStyle Hidden -PassThru
Start-Sleep -Milliseconds 900
$clientProcess = Start-Process -FilePath $enginePath -ArgumentList '--headless --path . --log-file ./tests/network-client.log --script tests/network_peer.gd -- --killcam' -WindowStyle Hidden -PassThru
$clientProcess.WaitForExit()
$hostProcess.WaitForExit()
Get-Content -LiteralPath tests/network-host.log,tests/network-client.log | Select-String 'NETWORK|JOIN|WARNING|FAIL' | Select-Object -First 20
if ($hostProcess.ExitCode -ne 0 -or $clientProcess.ExitCode -ne 0) { throw 'Netzwerktest fehlgeschlagen.' }
$scriptErrors = Select-String -Path tests/integration.log,tests/killcam.log,tests/redesign.log,tests/graphics.log,tests/operator-metrics.log,tests/expansion.log,tests/features.log,tests/fps.log,tests/handling.log,tests/war-district.log,tests/network-host.log,tests/network-client.log -Pattern 'SCRIPT ERROR|FAIL '
if ($scriptErrors) { throw 'Godot meldet Laufzeitfehler.' }
Write-Output 'Integration und Zwei-Prozess-Netzwerktest bestanden.'
