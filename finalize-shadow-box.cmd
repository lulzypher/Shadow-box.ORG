@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0finalize-shadow-box.ps1"
set ERR=%ERRORLEVEL%
pause
exit /b %ERR%
