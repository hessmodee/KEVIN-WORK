@echo off
REM Stay + companion: safe smokes then JOIN_OK NetherNet inject + GoalFollow/guard wire.
REM Identity: kevinsk8erkid only. Never hessmodee. Never kill Minecraft.Windows / Chat / Reader.
REM Exit 2 = BLOCKED_MC_UI / READY_FOR_LIVE_INJECT. Do not claim FOLLOW_OK/COMBAT_OK without live receipts.
setlocal
cd /d "%~dp0"
echo [rejoin-companion] identity=kevinsk8erkid spike stay+companion

call "%~dp0..\kevin-minecraft-bedrock-v0\preflight-stay.cmd"
if errorlevel 1 (
  echo READY_FOR_LIVE_INJECT=BLOCKED_MC_UI
  echo [rejoin-companion] Close Minecraft.Windows when safe, then rerun.
  echo [rejoin-companion] See READY_FOR_LIVE_INJECT.md
  exit /b 2
)

if not exist "%~dp0vendor\mineflayer-for-bedrock-main\package.json" (
  echo VENDOR_MISSING run install-deps.cmd
  exit /b 4
)
if not exist "%~dp0rejoin-companion.js" (
  echo MISSING rejoin-companion.js
  exit /b 4
)

echo [rejoin-companion] running safe smokes
call "%~dp0smoke-require.cmd"
if errorlevel 1 exit /b 5
call "%~dp0smoke-companion-wire.cmd"
if errorlevel 1 exit /b 6
call "%~dp0smoke-bridge.cmd"
if errorlevel 1 exit /b 7

echo [rejoin-companion] smokes OK - launching stay+companion inject
set KEVIN_MC_VERSION=1.26.45
set KEVIN_REALMS_STAY=1
set KEVIN_SPIKE_ALLOW_LIVE_JOIN=1
node rejoin-companion.js
exit /b %ERRORLEVEL%
