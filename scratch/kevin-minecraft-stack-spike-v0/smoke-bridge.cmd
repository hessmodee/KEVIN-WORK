@echo off
cd /d "%~dp0"
echo [smoke-bridge] dry inject — no Realms
node smoke-bridge.js
exit /b %ERRORLEVEL%
