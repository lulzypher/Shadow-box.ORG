@echo off
cd /d "%~dp0"
if not exist "node_modules\vite\package.json" (
  echo Run: npm install
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Write-Host ''; Write-Host ('  ' + ('=' * 52)) -ForegroundColor DarkMagenta; Write-Host '   SHADOW-BOX' -NoNewLine -ForegroundColor Magenta; Write-Host '  |  ' -NoNewLine -ForegroundColor DarkGray; Write-Host 'VITE DEV  |  HOT RELOAD  |  :8844' -ForegroundColor White; Write-Host ('  ' + ('=' * 52)) -ForegroundColor DarkMagenta; Write-Host ''"
set SHADOW_BOX_PORT=8844
cmd /k "npm run dev"
