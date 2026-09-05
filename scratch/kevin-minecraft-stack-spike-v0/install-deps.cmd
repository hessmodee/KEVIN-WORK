@echo off
setlocal
cd /d "%~dp0"
echo [kevin-minecraft-stack-spike-v0] Isolated bedrockflayer vendor install
where node >nul 2>&1
if errorlevel 1 (
  echo RUNTIME_MISSING
  exit /b 2
)
if not exist "vendor\mineflayer-for-bedrock-main\package.json" (
  echo VENDOR_MISSING
  exit /b 4
)
cd /d "%~dp0vendor\mineflayer-for-bedrock-main"
call npm.cmd install --no-fund --no-audit --omit=dev
if errorlevel 1 (
  echo INSTALL_FAILED
  exit /b 3
)
echo INSTALL_OK
endlocal
