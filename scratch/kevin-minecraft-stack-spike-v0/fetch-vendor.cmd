@echo off
setlocal
cd /d "%~dp0"
curl.exe -L -o vendor-mineflayer-for-bedrock.zip https://github.com/torzodmc/mineflayer-for-bedrock/archive/refs/heads/main.zip
if errorlevel 1 exit /b 5
powershell -NoProfile -Command "Expand-Archive -Force vendor-mineflayer-for-bedrock.zip vendor"
echo VENDOR_FETCH_OK
endlocal
