param([Parameter(Mandatory = $true)][string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$destination = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$package = Join-Path $destination 'BLOCKLINE-Server-Windows'
$archive = Join-Path $destination 'BLOCKLINE-Server-Windows.zip'
if ((Test-Path -LiteralPath $package) -or (Test-Path -LiteralPath $archive)) {
    throw 'Zielpaket existiert bereits. Bitte einen neuen Ausgabeordner verwenden.'
}
New-Item -ItemType Directory -Path $package | Out-Null
& (Join-Path $projectRoot 'launcher/Build-Server.ps1') -OutputFile (Join-Path $package 'Start-Server.exe')
foreach ($directory in @('assets', 'scenes', 'scripts')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination $package -Recurse
}
foreach ($file in @('project.godot', 'server.json', 'Start-Server.cmd')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $package
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README-SERVER.md') -Destination $package
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'third-party') -Destination $package -Recurse
New-Item -ItemType Directory -Path (Join-Path $package 'tools/godot') -Force | Out-Null
foreach ($engine in @('Godot_v4.5-stable_win64.exe', 'Godot_v4.5-stable_win64_console.exe')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot "tools/godot/$engine") -Destination (Join-Path $package 'tools/godot')
}
# Keep provenance even when the current sources are intentionally not committed yet.
$commit = & git -C $projectRoot rev-parse HEAD
$sourceHashes = foreach ($file in Get-ChildItem -LiteralPath (Join-Path $package 'scripts'),(Join-Path $package 'scenes') -File -Recurse) {
    [ordered]@{ file = $file.FullName.Substring($package.Length + 1); sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
}
[ordered]@{ built_utc = [DateTime]::UtcNow.ToString('o'); base_commit = $commit; files = @($sourceHashes) } |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $package 'BUILD-INFO.json') -Encoding UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($package, $archive, [IO.Compression.CompressionLevel]::Optimal, $true)
(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash + '  ' + [IO.Path]::GetFileName($archive) |
    Set-Content -LiteralPath ($archive + '.sha256') -Encoding ASCII
Write-Output "Serverpaket: $archive"
