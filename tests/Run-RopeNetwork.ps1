$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$engine = Join-Path (Get-Location) 'tools/godot/Godot_v4.5-stable_win64_console.exe'
$server = $null
$client = $null
try {
    $server = Start-Process -FilePath $engine -ArgumentList '--headless --path . --log-file ./tests/rope-network-host.log --script tests/rope_network.gd -- --server' -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 900
    $client = Start-Process -FilePath $engine -ArgumentList '--headless --path . --log-file ./tests/rope-network-client.log --script tests/rope_network.gd' -WindowStyle Hidden -PassThru
    if (!$client.WaitForExit(25000) -or !$server.WaitForExit(25000)) { throw 'ROPE network timeout' }
    Get-Content tests/rope-network-host.log,tests/rope-network-client.log | Select-String 'ROPE NETWORK|SCRIPT ERROR|^FAIL '
    if ($client.ExitCode -ne 0 -or $server.ExitCode -ne 0) { throw 'ROPE network failed' }
    if (Select-String -Path tests/rope-network-host.log,tests/rope-network-client.log -Pattern 'SCRIPT ERROR|^FAIL ') { throw 'ROPE runtime error' }
} finally {
    foreach ($process in @($server, $client)) {
        if ($null -ne $process -and !$process.HasExited) { $process.Kill() }
    }
}
