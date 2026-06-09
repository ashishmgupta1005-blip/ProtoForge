# ProtoForge installer (Windows / PowerShell)
# Copies the skill into your user skills dir and seeds the config if missing.
$ErrorActionPreference = "Stop"
$repo   = Split-Path -Parent $MyInvocation.MyCommand.Path
$claude = Join-Path $env:USERPROFILE ".claude"
$skills = Join-Path $claude "skills\protoforge"

New-Item -ItemType Directory -Force -Path $skills | Out-Null
Copy-Item -Recurse -Force (Join-Path $repo "skills\protoforge\*") $skills
Write-Host "Installed skill -> $skills"

$cfg = Join-Path $claude "protoforge.config"
if (-not (Test-Path $cfg)) {
    Copy-Item (Join-Path $repo "config\protoforge.config.example") $cfg
    Write-Host "Seeded config  -> $cfg  (edit it with your tool paths)"
} else {
    Write-Host "Config exists  -> $cfg  (left untouched)"
}
Write-Host ""
Write-Host "Next: 1) edit $cfg   2) register the MCP servers (see SETUP.md)   3) run /protoforge in Claude Code"
