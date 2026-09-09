param([string]$ServerDirectory = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$executable = Join-Path $ServerDirectory 'Start-Server.exe'
$launched = [Collections.Generic.List[Diagnostics.Process]]::new()
function Launch([string]$Arguments) {
    $info = [Diagnostics.ProcessStartInfo]::new($executable, $Arguments)
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($info)
    $launched.Add($process)
    return $process
}
function Ready([Diagnostics.Process]$Process) {
    $deadline = [DateTime]::UtcNow.AddSeconds(90)
    while ([DateTime]::UtcNow -lt $deadline) {
        $line = $Process.StandardOutput.ReadLineAsync()
        if (-not $line.Wait(90000)) { throw 'Server READY timeout.' }
        if ($null -eq $line.Result) { throw 'Server ended before READY: ' + $Process.StandardError.ReadToEnd() }
        if ($line.Result.Contains('SERVER READY')) { return }
    }
    throw 'Server READY timeout.'
}
try {
    $invalid = Launch '--port=oops --bots=0'
    if (-not $invalid.WaitForExit(20000) -or $invalid.ExitCode -ne 2) { throw 'Invalid config did not return code 2.' }
    if (-not $invalid.StandardError.ReadToEnd().Contains('SERVER CONFIG ERROR')) { throw 'Missing configuration error.' }
    Write-Output 'PASS invalid configuration fails with clear error and exit code 2'
    $first = Launch '--port=27986 --bots=0 --discovery=false'
    Ready $first
    $busy = Launch '--port=27986 --bots=0 --discovery=false --run-for=2'
    if (-not $busy.WaitForExit(20000) -or $busy.ExitCode -ne 1) { throw 'Occupied port did not return code 1.' }
    Write-Output 'PASS occupied UDP port fails with exit code 1'
    $first.StandardInput.WriteLine('stop')
    if (-not $first.WaitForExit(15000) -or $first.ExitCode -ne 0) { throw 'Console stop command failed.' }
    if (-not $first.StandardOutput.ReadToEnd().Contains('SERVER STOP')) { throw 'Graceful shutdown not observed.' }
    Write-Output 'PASS stop command shuts down engine and launcher cleanly'
    $existingEngines = @(Get-Process -Name 'Godot_v4.5-stable_win64' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
    $crash = Launch '--port=27986 --bots=0 --discovery=false'
    Ready $crash
    $newEngines = @(Get-Process -Name 'Godot_v4.5-stable_win64' -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $existingEngines })
    if ($newEngines.Count -ne 1) { throw 'Expected exactly one new engine process; run this test without concurrent graphical launches.' }
    $childProcess = $newEngines[0]
    $crash.Kill()
    $crash.WaitForExit()
    if (-not $childProcess.WaitForExit(10000)) { throw 'Engine survived termination of launcher.' }
    Write-Output 'PASS Windows job stops engine when launcher is terminated'
} finally {
    foreach ($process in $launched) { if (-not $process.HasExited) { $process.Kill() } }
}
