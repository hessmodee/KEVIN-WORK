@echo off
cd /d "%~dp0"
echo [smoke-companion-wire] fake/unit inject ? no Realms
node smoke-companion-wire.js
exit /b %ERRORLEVEL%
