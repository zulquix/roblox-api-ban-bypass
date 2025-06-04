@echo off
setlocal EnableDelayedExpansion

fltmc >nul 2>&1 || (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\admin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\admin.vbs"
    "%temp%\admin.vbs"
    del "%temp%\admin.vbs"
    exit /b
)

set "ESC="
for /f %%c in ('echo prompt $E ^| cmd') do set "ESC=%%c"
set "gray=%ESC%[90m"
set "reset=%ESC%[0m"

cls
echo ===================================================
echo                  Roblox 403 Fix Utility
echo                 Made by Zulquix on Discord
echo    https://github.com/zulquix/roblox-api-ban-bypass/blob/main/403errorfix.bat
echo ===================================================
echo.

choice /m "Open Github?"
if errorlevel 2 goto skip_update
start https://github.com/zulquix/roblox-api-ban-bypass/blob/main/403errorfix.bat
exit /b
:skip_update

echo.
echo.
echo [1/6] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
if errorlevel 1 (
    set "status_dns=Failed"
    echo %gray%[summary] DNS flush failed.%reset%
) else (
    set "status_dns=Success"
    echo %gray%[summary] DNS cache flushed.%reset%
)

echo [2/6] Syncing system time...
w32tm /resync >nul 2>&1
if errorlevel 1 (
    echo %gray%[summary] Time sync failed. Restarting time service...%reset%
    net stop w32time >nul 2>&1
    net start w32time >nul 2>&1
    w32tm /resync >nul 2>&1
    if errorlevel 1 (
        set "status_timesync=Failed"
        echo %gray%[summary] Time sync failed after restart.%reset%
    ) else (
        set "status_timesync=Success after restart"
        echo %gray%[summary] Time sync succeeded after restart.%reset%
    )
) else (
    set "status_timesync=Success"
    echo %gray%[summary] Time sync complete.%reset%
)

echo [3/6] Clearing internet cache...
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255
if errorlevel 1 (
    set "status_cache=Failed"
    echo %gray%[summary] Internet cache clearing failed.%reset%
) else (
    set "status_cache=Success"
    echo %gray%[summary] Internet cache cleared.%reset%
)

echo [4/6] Deleting Roblox cache...
set "RobloxPath=%LOCALAPPDATA%\Roblox"
if exist "%RobloxPath%" (
    rmdir /s /q "%RobloxPath%"
    if errorlevel 1 (
        set "status_robloxcache=Failed to delete"
        echo %gray%[summary] Roblox cache delete failed.%reset%
    ) else (
        set "status_robloxcache=Deleted"
        echo %gray%[summary] Roblox cache deleted.%reset%
    )
) else (
    set "status_robloxcache=Not found"
    echo %gray%[summary] Roblox folder not found.%reset%
)

echo [5/6] Restarting DNS Client...
net stop dnscache >nul 2>&1
net start dnscache >nul 2>&1
if errorlevel 1 (
    set "status_dnscache=Failed"
    echo %gray%[summary] DNS client restart failed.%reset%
) else (
    set "status_dnscache=Success"
    echo %gray%[summary] DNS client restarted.%reset%
)

echo.
choice /m "Would you like to spoof your MAC address to get rid of API ban?"
if errorlevel 2 goto skip_mac

echo [6/6] Generating safe random MAC address...
set "hex=0123456789ABCDEF"
set "mac=02"
for /l %%i in (1,1,10) do (
    set /a r=!random! %% 16
    for %%c in (!r!) do set "mac=!mac!!hex:~%%c,1!"
)
set "status_macsafe=Generated"

for /f "tokens=2 delims==" %%A in (
  'wmic nic where "NetEnabled=true and (AdapterTypeID=0 or AdapterTypeID=9)" get Name /value ^| find "="'
) do (
    set "adapterName=%%A"
    goto apply_mac
)

set "status_adapter=Not found"
goto skip_mac

:apply_mac
set "adapterName=%adapterName:~0,-1%"
set "status_adapter=Found (%adapterName%)"
echo %gray%[summary] Adapter: %adapterName%%reset%

for /f "tokens=2 delims==" %%A in (
  'wmic nic where "NetEnabled=true and Name='%adapterName%'" get DeviceID /value ^| find "="'
) do (
    set "devID=%%A"
)

if not defined devID (
    set "status_macapply=DeviceID not found"
    goto skip_mac
)

set "regKey=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\%devID%"

echo Applying MAC to registry...
reg add "%regKey%" /v NetworkAddress /d !mac! /f >nul 2>&1
if errorlevel 1 (
    set "status_macapply=Registry update failed"
    goto skip_mac
) else (
    set "status_macapply=Registry updated"
)

echo Restarting network adapter...
wmic path win32_networkadapter where "DeviceID='%devID%'" call disable >nul
timeout /t 2 >nul
wmic path win32_networkadapter where "DeviceID='%devID%'" call enable >nul
if errorlevel 1 (
    set "status_macapply=Adapter restart failed"
) else (
    set "status_macapply=Adapter restarted"
)

:skip_mac

echo.
choice /m "Would you like to reinstall Roblox automatically?"
if errorlevel 2 goto done_summary

powershell -Command "Get-AppxPackage *Roblox* | Remove-AppxPackage" >nul 2>&1
timeout /t 5 >nul

set "robloxInstaller=%TEMP%\RobloxPlayerLauncher.exe"
powershell -Command "Invoke-WebRequest -Uri 'https://setup.rbxcdn.com/RobloxPlayerLauncher.exe' -OutFile '%robloxInstaller%'" >nul 2>&1

if exist "%robloxInstaller%" (
    start "" /wait "%robloxInstaller%" /quiet /norestart >nul 2>&1
    echo %gray%[summary] Roblox reinstall completed.%reset%
    del "%robloxInstaller%" >nul 2>&1
) else (
    echo %gray%[summary] Failed to download Roblox installer.%reset%
)

timeout /t 3 >nul

:done_summary
echo.
echo.
echo %gray%===================================================
echo Successfully completed. You can now try using Roblox.
echo ===================================================
echo %reset%
pause
exit
