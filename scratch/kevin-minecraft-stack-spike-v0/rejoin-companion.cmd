@echo off
REM Stay + companion: preflight no MC UI -> JOIN_OK NetherNet -> inject -> GoalFollow Matt + hostile guard + autoEat
REM Identity: kevinsk8erkid only. Never hessmodee. Never kill Minecraft.Windows / Chat / Reader.
REM Exit 2 = READY_FOR_LIVE_INJECT (MC UI open). Exit 0 only if process exits cleanly (stay usually runs until Ctrl+C).
cd /d "%~dp0"
echo [rejoin-companion] spike stay+companion entry
echo [rejoin-companion] version default 1.26.45 / protocol 2169 path via gym NetherNet overlay
set KEVIN_MC_VERSION=1.26.45
set KEVIN_REALMS_STAY=1
set KEVIN_SPIKE_ALLOW_LIVE_JOIN=1
node rejoin-companion.js
exit /b %ERRORLEVEL%
