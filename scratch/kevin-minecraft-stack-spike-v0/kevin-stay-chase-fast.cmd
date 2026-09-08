@echo off
REM Fast Kevin stay (skips smokes). Use when smoke already green.
setlocal
cd /d "%~dp0"
echo [kevin-stay-chase-fast] identity=kevinsk8erkid
if not defined KEVIN_ALLOW_CLOSE_MC set KEVIN_ALLOW_CLOSE_MC=1
set "LIFECYCLE=%~dp0..\kevin-desktop-app-lifecycle-v0"
if "%KEVIN_ALLOW_CLOSE_MC%"=="1" if exist "%LIFECYCLE%\kevin-app-close.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%LIFECYCLE%\kevin-app-close.ps1" -ProcessName Minecraft.Windows -Force -GraceMs 5000
)
call "%~dp0..\kevin-minecraft-bedrock-v0\preflight-stay.cmd"
if errorlevel 1 exit /b 2
set KEVIN_REALMS_STAY=1
set KEVIN_MC_VERSION=1.26.45
set KEVIN_SPIKE_ALLOW_LIVE_JOIN=1
if not exist "%~dp0logs" mkdir "%~dp0logs"
set "LOG=%~dp0logs\companion-authchase-fast.log"
node "%~dp0rejoin-companion.js" > "%LOG%" 2>&1
exit /b %ERRORLEVEL%