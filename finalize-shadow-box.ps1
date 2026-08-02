$ErrorActionPreference = "Stop"
function Show-ShadowBoxBanner {
  param([string]$Mode)
  Write-Host ""
  Write-Host ("  " + ("=" * 52)) -ForegroundColor DarkMagenta
  Write-Host "   SHADOW-BOX" -NoNewline -ForegroundColor Magenta
  Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
  Write-Host $Mode -ForegroundColor White
  Write-Host ("  " + ("=" * 52)) -ForegroundColor DarkMagenta
  Write-Host ""
}

$Root = $PSScriptRoot
$Port = if ($env:SHADOW_BOX_PORT) { [int]$env:SHADOW_BOX_PORT } else { 8844 }
$Cfg = Join-Path $env:USERPROFILE ".cloudflared\config.yml"

$Candidates = @(
  (Join-Path $Root "tools\cloudflared.exe"),
  "C:\Program Files (x86)\cloudflared\cloudflared.exe",
  "C:\Program Files\cloudflared\cloudflared.exe"
)
$Cloudflared = $Candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

function Test-Listen([int]$p) {
  $c = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
  return $null -ne $c
}

Show-ShadowBoxBanner "FINALIZE  |  npm build + serve dist/  |  port $Port"

if (-not (Test-Path -LiteralPath $Cfg)) {
  Write-Error "Missing tunnel config: $Cfg"
}

if (-not $Cloudflared) {
  Write-Error "cloudflared.exe not found. Install from Cloudflare docs (cloudflared install)."
}

$cf = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
if (-not $cf) {
  Write-Host "Starting cloudflared tunnel..." -ForegroundColor Yellow
  Start-Process -FilePath $Cloudflared -ArgumentList @("tunnel", "--config", $Cfg, "run") -WindowStyle Minimized
  Start-Sleep -Seconds 2
} else {
  Write-Host "cloudflared already running (PID $($cf.Id)). If you edited config.yml, restart that process to pick up changes." -ForegroundColor DarkYellow
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Error "npm not found. Install Node.js from https://nodejs.org/"
}

Push-Location $Root
try {
  if (-not (Test-Path -LiteralPath (Join-Path $Root "node_modules\vite\package.json"))) {
    Write-Host "Installing dependencies (npm install)..." -ForegroundColor Yellow
    npm install
  }
  Write-Host "Running production build (npm run build)..." -ForegroundColor Yellow
  npm run build
} finally {
  Pop-Location
}

if (Test-Listen $Port) {
  Write-Host "Port $Port is already in use. Stop the other server on this port, then run this script again." -ForegroundColor Red
  Write-Host "Tunnel is running; preview was not started." -ForegroundColor Yellow
  exit 1
}

Write-Host "Starting static server from dist/ (no Vite preview / no Host blocking)..." -ForegroundColor Green

Write-Host 'Note: XO moved to DreamSystemz /xo/ — set $env:DREAMSYSTEMZ_ADMIN_TOKEN on 8845 for catalog POST. Legacy /xo here redirects (see $env:SHADOW_BOX_XO_REDIRECT).' -ForegroundColor DarkGray

# Build cmd.exe command line via string concatenation.
$serverCmd = ('cd /d "' + $Root + '" && set SHADOW_BOX_PORT=' + $Port +
  '&& set SHADOW_BOX_STATIC_ROOT=dist&& node static-server.mjs')
Start-Process -FilePath "cmd.exe" -ArgumentList @("/k", $serverCmd)

Write-Host ('Done. Local: http://127.0.0.1:{0}/  Public: https://shadow-box.org/' -f $Port) -ForegroundColor Green
Start-Sleep -Seconds 3
