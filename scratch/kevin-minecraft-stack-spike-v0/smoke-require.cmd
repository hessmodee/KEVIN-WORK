@echo off
setlocal
cd /d "%~dp0"
where node >nul 2>&1
if errorlevel 1 (
  echo RUNTIME_MISSING
  exit /b 2
)
node smoke-require.js
endlocal
