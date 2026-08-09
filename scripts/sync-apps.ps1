# Build sibling little-projects into public/apps/<slug>/ for shadow-box.org
$ErrorActionPreference = "Stop"
$Hub = Split-Path -Parent $PSScriptRoot
$ProjectsRoot = Split-Path -Parent $Hub
$Apps = Join-Path $Hub "public\apps"

$Catalog = @(
  @{
    Id = "ship"
    Source = Join-Path $ProjectsRoot "bambu-ship-kit"
    Base = "/apps/ship/"
  },
  @{
    Id = "printers"
    Source = Join-Path $ProjectsRoot "voron-trident-350-configurator"
    Base = "/apps/printers/"
  },
  @{
    Id = "manufacturing"
    Source = Join-Path $ProjectsRoot "manufacturing-map"
    Base = "/apps/manufacturing/"
  },
  @{
    Id = "dns"
    Source = Join-Path $ProjectsRoot "dns-root-map"
    Base = "/apps/dns/"
  },
  @{
    Id = "skills"
    Source = Join-Path $ProjectsRoot "3dEST\3dExhaustiveSkillTree"
    Base = "/apps/skills/"
    Builder = "next"
  }
)

function Ensure-Dir([string]$Path) {
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

Write-Host "Shadow-box hub sync → $Apps" -ForegroundColor Magenta
Ensure-Dir $Apps

foreach ($app in $Catalog) {
  if (-not (Test-Path -LiteralPath $app.Source)) {
    Write-Error "Missing project: $($app.Source)"
  }
  $dest = Join-Path $Apps $app.Id
  Write-Host ("Building {0} (base {1})..." -f $app.Id, $app.Base) -ForegroundColor Cyan
  Push-Location $app.Source
  try {
    if (-not (Test-Path "node_modules")) { npm install }
    $env:BASE_PATH = $app.Base
    $env:NEXT_PUBLIC_BASE_PATH = $app.Base.TrimEnd("/")
    if ($app.Builder -eq "next") {
      npm run build
      $outDir = Join-Path $app.Source "out"
      if (-not (Test-Path (Join-Path $outDir "index.html"))) {
        Write-Error "Next build produced no out/index.html for $($app.Id)"
      }
    } else {
      npm run build
      $outDir = Join-Path $app.Source "dist"
      if (-not (Test-Path (Join-Path $outDir "index.html"))) {
        Write-Error "Build produced no dist/index.html for $($app.Id)"
      }
    }
  } finally {
    Pop-Location
    Remove-Item Env:BASE_PATH -ErrorAction SilentlyContinue
    Remove-Item Env:NEXT_PUBLIC_BASE_PATH -ErrorAction SilentlyContinue
  }

  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  Ensure-Dir $dest
  Copy-Item -Path (Join-Path $outDir "*") -Destination $dest -Recurse -Force
  Write-Host ("  → {0}" -f $dest) -ForegroundColor Green
}

# Keep Fluke helper under apps/fluke (and legacy /fluke/)
$flukeSrc = Join-Path $Hub "fluke\index.html"
if (-not (Test-Path $flukeSrc)) {
  $flukeSrc = Join-Path $Hub "public\apps\fluke\index.html"
}
if (Test-Path $flukeSrc) {
  Ensure-Dir (Join-Path $Apps "fluke")
  Copy-Item $flukeSrc (Join-Path $Apps "fluke\index.html") -Force
  Ensure-Dir (Join-Path $Hub "public\fluke")
  Copy-Item $flukeSrc (Join-Path $Hub "public\fluke\index.html") -Force
  Write-Host "  → apps/fluke + public/fluke (legacy URL)" -ForegroundColor Green
}

# Static Cult of Saturn / FalseProphet field guide
$saturnSrc = Join-Path $Hub "cult-of-saturn\index.html"
if (-not (Test-Path $saturnSrc)) {
  $saturnSrc = Join-Path $Hub "public\apps\cult-of-saturn\index.html"
}
if (Test-Path $saturnSrc) {
  Ensure-Dir (Join-Path $Apps "cult-of-saturn")
  Copy-Item $saturnSrc (Join-Path $Apps "cult-of-saturn\index.html") -Force
  Write-Host "  → apps/cult-of-saturn" -ForegroundColor Green
}

Write-Host "Done. Registry: public/projects.json" -ForegroundColor Green
