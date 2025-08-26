@echo off
setlocal EnableDelayedExpansion
title Roblox 403 Fix Utility
:: ===================================================
:: Roblox 403 Fix Utility
:: Made by Zulquix
:: GitHub: https://github.com/zulquix/roblox-api-ban-bypass/blob/main/403errorfix.bat
:: ===================================================
fltmc >nul 2>&1 || (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\\admin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0""", "", "runas", 1 >> "%temp%\\admin.vbs"
    "%temp%\\admin.vbs"
    del "%temp%\\admin.vbs"
    exit /b
)

set "remoteUrl=https://raw.githubusercontent.com/zulquix/roblox-api-ban-bypass/main/403errorfix.bat"
set "tempRemote=%TEMP%\403errorfix_remote.bat"
set "tempCurrent=%TEMP%\403errorfix_local.bat"
set "scriptPath=%~f0"

:: Download latest script version to temp file silently
powershell -Command "Invoke-WebRequest -Uri '%remoteUrl%' -OutFile '%tempRemote%'" >nul 2>&1

:: Copy current running script to temp
copy /y "%scriptPath%" "%tempCurrent%" >nul 2>&1

:: Compare current and remote files, if different errorlevel=1
fc "%tempCurrent%" "%tempRemote%" >nul

if %errorlevel%==1 (
    echo New version detected. Updating script...
    timeout /t 2 >nul

    :: Overwrite the running script file with the downloaded newest version
    copy /y "%tempRemote%" "%scriptPath%" >nul 2>&1

    echo Update finished. Restarting...
    timeout /t 2 >nul

    :: Start the updated script and exit current instance
    start "" "%scriptPath%"
    exit /b
)

:: Clean up temp files
del "%tempRemote%" >nul 2>&1
del "%tempCurrent%" >nul 2>&1

for /f %%c in ('echo prompt $E ^| cmd') do set "ESC=%%c"
set "green=%ESC%[92m"
set "red=%ESC%[91m"
set "yellow=%ESC%[93m"
set "gray=%ESC%[90m"
set "reset=%ESC%[0m"
set "ok=[ OK ]"
set "fail=[FAIL]"
set "warn=[WARN]"

cls
echo %gray%===================================================%reset%
echo       %yellow%Roblox 403 Error Fix Utility%reset%
echo        Made by Zulquix
echo  GitHub: https://github.com/zulquix/roblox-api-ban-bypass
echo %gray%===================================================%reset%
echo.
echo [1/6] Flushing DNS cache...
ipconfig /flushdns >nul 2>&1
if errorlevel 1 (echo %red%%fail%%reset% DNS flush failed.) else (echo %green%%ok%%reset% DNS cache flushed.)

echo [2/6] Syncing system time...
w32tm /resync >nul 2>&1
if errorlevel 1 (
    echo %yellow%%warn%%reset% Time sync failed, restarting service...
    net stop w32time >nul 2>&1
    net start w32time >nul 2>&1
    w32tm /resync >nul 2>&1
    if errorlevel 1 (echo %red%%fail%%reset% Time sync failed after restart.) else (echo %green%%ok%%reset% Time sync succeeded.)
) else (echo %green%%ok%%reset% Time sync completed.)

echo [3/6] Clearing Internet cache...
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255 >nul 2>&1
if errorlevel 1 (echo %red%%fail%%reset% Failed to clear internet cache.) else (echo %green%%ok%%reset% Internet cache cleared.)

echo [4/6] Deleting Roblox cache...
set "RobloxPath=%LOCALAPPDATA%\Roblox"
if exist "%RobloxPath%" (
    rmdir /s /q "%RobloxPath%" >nul 2>&1
    if errorlevel 1 (echo %red%%fail%%reset% Roblox cache deletion failed.) else (echo %green%%ok%%reset% Roblox cache deleted.)
) else (echo %yellow%%warn%%reset% Roblox cache not found.)

echo [5/6] Restarting DNS Client...
net stop dnscache >nul 2>&1
net start dnscache >nul 2>&1
if errorlevel 1 (
    echo %red%%fail%%reset% DNS client restart failed. Applying Winsock/IP reset...
    netsh winsock reset >nul 2>&1
    netsh int ip reset >nul 2>&1
    ipconfig /flushdns >nul 2>&1
    echo %yellow%%warn%%reset% Fallback applied. Restart your PC.
) else (echo %green%%ok%%reset% DNS client restarted.)

echo.
choice /c YN /n /m "Do you want to spoof your MAC address? [Y/N]: "
if errorlevel 2 goto skip_mac
if errorlevel 1 goto do_mac

:do_mac
echo [6/6] Generating random spoofed MAC...
set vendors=021A2B 061122 0A1B2C 58EF68
set /a pick=!random! %% 4
for /f "tokens=%pick% delims= " %%a in ("%vendors%") do set "prefix=%%a"
set "hex=0123456789ABCDEF"
set "mac=%prefix%"
for /l %%i in (1,1,6) do (
    set /a r=!random! %% 16
    set "mac=!mac!!hex:~%r%,1!"
)
for /f "tokens=2 delims==" %%A in (
    'wmic nic where "NetEnabled=true and (AdapterTypeID=0 or AdapterTypeID=9)" get DeviceID /value ^| find "="'
) do (
    set "devID=%%A"
    goto mac_adapter_found
)
echo %red%%fail%%reset% No active network adapter found.
goto skip_mac

:mac_adapter_found
set "regKey=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\%devID%"
reg add "%regKey%" /v NetworkAddress /d !mac! /f >nul 2>&1
if errorlevel 1 (echo %red%%fail%%reset% Failed to write MAC to registry.) else (echo %green%%ok%%reset% MAC set to !mac!)
wmic path win32_networkadapter where "DeviceID='%devID%'" call disable >nul
timeout /t 2 >nul
wmic path win32_networkadapter where "DeviceID='%devID%'" call enable >nul
if errorlevel 1 (echo %red%%fail%%reset% Failed to restart adapter.) else (echo %green%%ok%%reset% Network adapter restarted.)

:skip_mac
echo.
choice /c YN /n /m "Do you want to reinstall Roblox automatically? [Y/N]: "
if errorlevel 2 goto final_exit
if errorlevel 1 goto reinstall_roblox

:reinstall_roblox
powershell -Command "Get-AppxPackage *Roblox* | Remove-AppxPackage" >nul 2>&1
timeout /t 3 >nul
set "robloxInstaller=%TEMP%\RobloxPlayerLauncher.exe"
powershell -Command "Invoke-WebRequest -Uri 'https://setup.rbxcdn.com/RobloxPlayerLauncher.exe' -OutFile '%robloxInstaller%'" >nul 2>&1
if exist "%robloxInstaller%" (
    start "" "%robloxInstaller%"
    if errorlevel 1 (echo %red%%fail%%reset% Roblox reinstall failed.) else (echo %green%%ok%%reset% Roblox installer launched.)
    del "%robloxInstaller%" >nul
) else (echo %red%%fail%%reset% Failed to download installer.)

:final_exit
echo.
echo Press any key to exit...
pause >nul
exit
