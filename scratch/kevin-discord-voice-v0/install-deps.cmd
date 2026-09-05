@echo off
setlocal
cd /d "%~dp0"
echo [kevin-discord-voice-v0] Node:
node -v
if errorlevel 1 exit /b 1
echo Installing packages...
call npm install --no-fund --no-audit
if errorlevel 1 exit /b 1
call npm run smoke
if errorlevel 1 exit /b %ERRORLEVEL%
call npm run smoke:text
exit /b %ERRORLEVEL%
