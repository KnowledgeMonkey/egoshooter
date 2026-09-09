$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$engine = Join-Path (Get-Location) 'tools/godot/Godot_v4.5-stable_win64_console.exe'
$server = $null
$client = $null
try {
    $server = Start-Process -FilePath $engine -ArgumentList '--headless --path . --log-file ./tests/fps-network-host.log --script tests/fps_network.gd -- --server' -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 900
    $client = Start-Process -FilePath $engine -ArgumentList '--headless --path . --log-file ./tests/fps-network-client.log --script tests/fps_network.gd' -WindowStyle Hidden -PassThru
    if (!$client.WaitForExit(25000) -or !$server.WaitForExit(25000)) { throw 'FPS network timeout' }
    Get-Content tests/fps-network-host.log,tests/fps-network-client.log | Select-String 'FPS NETWORK|SCRIPT ERROR|^FAIL '
    if ($client.ExitCode -ne 0 -or $server.ExitCode -ne 0) { throw 'FPS network failed' }
    if (Select-String -Path tests/fps-network-host.log,tests/fps-network-client.log -Pattern 'SCRIPT ERROR|^FAIL ') { throw 'FPS runtime error' }
} finally {
    foreach ($process in @($server, $client)) {
        if ($null -ne $process -and !$process.HasExited) { $process.Kill() }
    }
}
