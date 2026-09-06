@echo off
REM Kevin-owned Realms stay + auth_input chase. Run on HESS-PC by Matt/Kevin.
REM identity=kevinsk8erkid only. Never hessmodee. Never kill Chat/Reader/Operator.
REM CoS may restart this; CoS must NOT mid-game puppeteer in place of this process.
setlocal
cd /d "%~dp0"
echo [kevin-stay-chase] Kevin-local launcher — kevinsk8erkid stay+chase
echo [kevin-stay-chase] log capture -> logs\companion-authchase-%DATE:~-4%%DATE:~4,2%%DATE:~7,2%.log and _rejoin-companion.log

if not exist "%~dp0logs" mkdir "%~dp0logs"
set "LOGFILE=%~dp0logs\companion-authchase-%DATE:~-4%%DATE:~4,2%%DATE:~7,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.log"
set "LOGFILE=%LOGFILE: =0%"

REM Prefer rejoin-companion.cmd (preflight + smokes + node). Tee to log.
call "%~dp0rejoin-companion.cmd" > "%LOGFILE%" 2>&1
set ERR=%ERRORLEVEL%
echo [kevin-stay-chase] exit=%ERR% logfile=%LOGFILE%
exit /b %ERR%