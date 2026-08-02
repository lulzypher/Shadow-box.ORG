$ErrorActionPreference = "Stop"

function Show-ShadowBoxToolsBanner {
  Write-Host ""
  Write-Host ("  " + ("=" * 52)) -ForegroundColor DarkMagenta
  Write-Host "   SHADOW-BOX" -NoNewline -ForegroundColor Magenta
  Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
  Write-Host "TOOLS  |  cloudflared fetch" -ForegroundColor White
  Write-Host ("  " + ("=" * 52)) -ForegroundColor DarkMagenta
  Write-Host ""
}

$Root = $PSScriptRoot
Show-ShadowBoxToolsBanner
$OutDir = Join-Path $Root "tools"
$OutExe = Join-Path $OutDir "cloudflared.exe"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$rel = Invoke-RestMethod -Uri "https://api.github.com/repos/cloudflare/cloudflared/releases/latest" -Headers @{ "User-Agent" = "Shadow-box-ORG-update" }
$asset = $rel.assets | Where-Object { $_.name -eq "cloudflared-windows-amd64.exe" } | Select-Object -First 1
if (-not $asset) {
  Write-Error "Release asset cloudflared-windows-amd64.exe not found."
}

Write-Host "Latest tag: $($rel.tag_name)" -ForegroundColor Cyan
Write-Host "Downloading..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $OutExe -UseBasicParsing
Unblock-File -LiteralPath $OutExe -ErrorAction SilentlyContinue
Write-Host "Installed:" $OutExe -ForegroundColor Green
& $OutExe --version
