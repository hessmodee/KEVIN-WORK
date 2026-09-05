@echo off
REM Kevin Realms rejoin (kevinsk8erkid) - stay in-world for play loop
REM Never hessmodee. Fail-closed if no auth cache.
cd /d "%~dp0"
set KEVIN_REALMS_STAY=1
set KEVIN_MC_VERSION=1.26.45
echo [rejoin] stay=1 version=%KEVIN_MC_VERSION% gamertag=kevinsk8erkid
node scripts\realms-join.js
exit /b %ERRORLEVEL%
