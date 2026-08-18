$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvironmentRoot = Split-Path -Parent (Split-Path -Parent $ProjectRoot)
$StudioPort = if ($env:MOONROBOTS_PORT) { $env:MOONROBOTS_PORT } else { "8877" }
$MoonCommand = Get-Command moon.exe -ErrorAction SilentlyContinue
$MoonExecutable = if ($MoonCommand) {
  $MoonCommand.Source
}
else {
  Join-Path $EnvironmentRoot "moonbit-toolchain\bin\moon.exe"
}
$NodeCommand = Get-Command node.exe -ErrorAction SilentlyContinue
$NodeExecutable = if ($NodeCommand) {
  $NodeCommand.Source
}
else {
  Join-Path $EnvironmentRoot "node.exe"
}

if (-not (Test-Path -LiteralPath $MoonExecutable)) {
  throw "MoonBit was not found. Expected it on PATH or at: $MoonExecutable"
}
if (-not (Test-Path -LiteralPath $NodeExecutable)) {
  throw "Node.js was not found. Expected it on PATH or at: $NodeExecutable"
}

Push-Location $ProjectRoot
try {
  & $MoonExecutable build --target js
  & $MoonExecutable build --target native cmd/crawler
  Write-Host ""
  Write-Host "MoonRobots Studio is available at:" -ForegroundColor Green
  Write-Host "http://127.0.0.1:$StudioPort/web/index.html" -ForegroundColor Cyan
  Write-Host "Press Ctrl+C to stop the local server." -ForegroundColor DarkGray
  & $NodeExecutable tools/studio_server.mjs
}
finally {
  Pop-Location
}
