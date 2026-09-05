@echo off
REM One-shot SAFE preflight for tonight home op-test. No live Realms join. No MC kill.
setlocal
cd /d "%~dp0"
set FAIL=0
echo === KEVIN HOME OPTEST PREFLIGHT ===
echo time=%DATE% %TIME%

echo.
echo -- Ports --
netstat -ano | findstr LISTENING | findstr 18789 >NUL && echo Chat_18789=LISTEN || (echo Chat_18789=DOWN & set FAIL=1)
netstat -ano | findstr LISTENING | findstr 19001 >NUL && echo Reader_19001=LISTEN || (echo Reader_19001=DOWN & set FAIL=1)
netstat -ano | findstr LISTENING | findstr 19101 >NUL && echo Operator_19101=LISTEN || (echo Operator_19101=DOWN & set FAIL=1)

echo.
echo -- Auth --
if exist "%~dp0..\..\credentials\kevin-minecraft\6eb2d0_live-cache.json" (echo AUTH_CACHE=present) else (echo AUTH_CACHE=MISSING & set FAIL=1)

echo.
echo -- MC UI --
tasklist /FI "IMAGENAME eq Minecraft.Windows.exe" 2>NUL | find /I "Minecraft.Windows.exe" >NUL
if %ERRORLEVEL%==0 (echo MC_UI=OPEN_CLOSE_BEFORE_REJOIN) else (echo MC_UI=CLOSED_CLEAR)

echo.
echo -- Smokes --
call "%~dp0smoke-require.cmd" || set FAIL=1
call "%~dp0smoke-companion-wire.cmd" || set FAIL=1
call "%~dp0smoke-bridge.cmd" || set FAIL=1

echo.
echo -- Scripts --
if exist "%~dp0rejoin-companion.cmd" (echo rejoin-companion=OK) else (echo rejoin-companion=MISSING & set FAIL=1)
if exist "%~dp0..\kevin-minecraft-bedrock-v0\rejoin.cmd" (echo gym_rejoin=OK) else (echo gym_rejoin=MISSING & set FAIL=1)

echo.
if "%FAIL%"=="0" (
  echo HOME_OPTEST_PREFLIGHT=GO
  echo next=Close Minecraft.Windows if open, then rejoin-companion.cmd, then Xbox as hessmodee
  exit /b 0
) else (
  echo HOME_OPTEST_PREFLIGHT=NO_GO
  exit /b 1
)
