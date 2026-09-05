@echo off
setlocal
cd /d "%~dp0"
echo [kevin-minecraft-bedrock-v0] Installing bedrock-protocol + prismarine-auth ...
where node >nul 2>&1
if errorlevel 1 (
  echo NODE_MISSING
  exit /b 2
)
call npm.cmd install --no-fund --no-audit
if errorlevel 1 (
  echo INSTALL_FAILED
  exit /b 3
)
call node scripts\check-deps.js
echo Done.
endlocal
