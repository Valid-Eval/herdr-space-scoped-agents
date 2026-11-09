# Install-time build step for Windows (run by Herdr at `plugin install`).
#
# Builds the binary from source with `go`. There is deliberately no prebuilt
# download: the binary is always compiled from the code you installed, so
# nothing is fetched from a GitHub release at install time (see
# specs/006-build-from-source.md).
$ErrorActionPreference = 'Stop'
$u = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $u; $OutputEncoding = $u

$bin = 'herdr-space-scoped-agents'

$root = $env:HERDR_PLUGIN_ROOT
if (-not $root) { $root = Split-Path -Parent $PSScriptRoot }
if ($root.StartsWith('\\?\')) { $root = $root.Substring(4) }

$manifest = Join-Path $root 'herdr-plugin.toml'
$version = (Select-String -Path $manifest -Pattern '^version\s*=\s*"([^"]*)"').Matches[0].Groups[1].Value
if (-not $version) { Write-Error "cannot read version from $manifest" }

if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
  Write-Error "Go is required to build $bin (https://go.dev/dl/)"
}

$binDir = Join-Path $root 'bin'
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
$out = Join-Path $binDir "$bin.exe"

Write-Host "building $bin v$version from source with go..."
Push-Location $root
try {
  & go build -trimpath -ldflags "-s -w -X main.version=$version" -o $out .
  if ($LASTEXITCODE -ne 0) { Write-Error "go build failed (exit $LASTEXITCODE)" }
}
finally { Pop-Location }
Write-Host "built -> $out"
