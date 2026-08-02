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
$useVite = $env:SHADOW_BOX_USE_VITE -eq "1"

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

Show-ShadowBoxBanner "START  |  tunnel + local server  |  port $Port"
if ($useVite) {
  Write-Host "Mode: Vite (SHADOW_BOX_USE_VITE=1)" -ForegroundColor DarkYellow
} else {
  Write-Host "Mode: static server (recommended for Cloudflare Tunnel)" -ForegroundColor Green
}

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

if (Test-Listen $Port) {
  $listenPid = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | Where-Object { $_ })[0]
  $detail = ""
  if ($listenPid) {
    $wp = Get-CimInstance Win32_Process -Filter "ProcessId = $listenPid" -ErrorAction SilentlyContinue
    if ($wp) { $detail = " (PID ${listenPid}: $($wp.Name) - $($wp.CommandLine))" }
    else { $detail = " (PID ${listenPid})" }
  }
  Write-Host "Port $Port is already in use$detail" -ForegroundColor Green
  Write-Host "Leaving that server running. Tunnel was started above (or was already running)." -ForegroundColor Green
  Write-Host "Local: http://127.0.0.1:$Port/  Public: https://shadow-box.org/" -ForegroundColor Green
  Start-Sleep -Seconds 4
  return
}

if ($useVite) {
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm not found. Install Node.js, or run without SHADOW_BOX_USE_VITE to use static-server.mjs only."
  }
  if (-not (Test-Path -LiteralPath (Join-Path $Root "node_modules\vite\package.json"))) {
    Write-Host "Installing dependencies (npm install)..." -ForegroundColor Yellow
    Push-Location $Root
    try {
      npm install
    } finally {
      Pop-Location
    }
  }
  Write-Host "Starting Vite (npm run dev)..." -ForegroundColor Yellow
  $viteCmd = ('cd /d "' + $Root + '" && set SHADOW_BOX_PORT=' + $Port + '&& npm run dev')
  Start-Process -FilePath "cmd.exe" -ArgumentList @("/k", $viteCmd)
  Write-Host "Note: Legacy /xo URLs redirect to DreamSystemz (SHADOW_BOX_XO_REDIRECT). XO Publish uses DreamSystemz DREAMSYSTEMZ_ADMIN_TOKEN + POST /xo/api/catalog." -ForegroundColor DarkGray
} else {
  Write-Host "Starting static file server (Node static-server.mjs)..." -ForegroundColor Yellow
  Write-Host "Tip: `$env:SHADOW_BOX_XO_REDIRECT=http://127.0.0.1:8845/xo/` sends legacy /xo URLs to local DreamSystemz." -ForegroundColor DarkGray
  $serverCmd = ('cd /d "' + $Root + '" && set SHADOW_BOX_PORT=' + $Port +
    '&& node static-server.mjs')
  Start-Process -FilePath "cmd.exe" -ArgumentList @("/k", $serverCmd)
}

Write-Host "Done. Public: https://shadow-box.org/" -ForegroundColor Green
Write-Host "Tip: Vite is for local build tooling. For tunnel traffic use this default (static). Optional: dev-vite-shadow-box.cmd" -ForegroundColor DarkGray
Start-Sleep -Seconds 4
