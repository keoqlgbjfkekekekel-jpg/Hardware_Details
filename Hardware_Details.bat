@echo off
if "%1"=="TIMER" goto TIMER
title Hardware Informations
setlocal EnableDelayedExpansion

:CHECKADMIN
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Demande des droits administrateur...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

mode con: cols=120 lines=3000
powershell -NoProfile -Command "$c=(Get-Host).UI.RawUI; $b=$c.BufferSize; $b.Width=120; $b.Height=3000; $c.BufferSize=$b" >nul 2>&1

set "PSFILE=%TEMP%\hwscan_%RANDOM%.ps1"

:KEYSYSTEM
cls
color 0D
echo ================================================================================
echo                         REQUIRED KEY SYSTEM
echo ================================================================================
echo.
echo                         [1] Verify Key
echo                         [2] Get Key
echo                         [3] Exit
echo.

choice /c 123 /n /m "Select an option: "

if errorlevel 3 goto EXIT
if errorlevel 2 goto GETKEY
if errorlevel 1 goto VERIFYKEY


:VERIFYKEY
cls
echo ================================================================================
echo                         VERIFY KEY
echo ================================================================================
echo.

set /p "USERKEY=Enter your key: "

echo.
echo Checking key...

powershell -NoProfile -Command "try { $body=@{key='%USERKEY%'} | ConvertTo-Json; $r=Invoke-RestMethod -Uri 'https://hardware-details-api.maelpct18.workers.dev/verify' -Method POST -ContentType 'application/json' -Body $body; if($r.success -eq $true){Set-Content -Path '%TEMP%\remaining.txt' -Value $r.remaining; exit 0}else{exit 1} } catch { exit 1 }"


if errorlevel 1 (
    echo.
    echo Invalid key.
    pause
    goto KEYSYSTEM
)


set /p REMAINING=<"%TEMP%\remaining.txt"

echo.
echo Key accepted!
echo Remaining: %REMAINING% seconds

set "TIMELEFT=%REMAINING%"

start "" /b "%~f0" TIMER

goto SCAN


:GETKEY
cls
echo ================================================================================
echo                         GET KEY
echo ================================================================================
echo.
echo Opening key page...
timeout /t 1 /nobreak >nul

start https://loot-link.com/s?qmEXkpfc

pause
goto KEYSYSTEM


:SCAN
cls

call :BUILDPS

powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%"

del "%PSFILE%" >nul 2>&1

echo.
pause
goto KEYSYSTEM


:BUILDPS
(
echo $ErrorActionPreference = 'SilentlyContinue'
echo $global:NACount = 0
echo function Show-Val^($label, $value, $suffix = ""^) {
echo     $isEmpty = $false
echo     if ^($null -eq $value^) { $isEmpty = $true }
echo     elseif ^($value -is [array] -and $value.Count -eq 0^) { $isEmpty = $true }
echo     elseif ^("$value".Trim^(^) -eq ""^) { $isEmpty = $true }
echo     if ^($isEmpty^) {
echo         $global:NACount++
echo         Write-Host "$label : " -NoNewline
echo         Write-Host "N/A" -ForegroundColor Red
echo     } else {
echo         Write-Host "$label : $value$suffix"
echo     }
echo }
echo.
echo Write-Host "================================================================================"
echo Write-Host "                              HARDWARE SCAN"
echo Write-Host "================================================================================"
echo Write-Host "Genere le : $(Get-Date)"
echo Write-Host ""
echo.
echo $os = Get-CimInstance Win32_OperatingSystem
echo $cpu = Get-CimInstance Win32_Processor
echo $gpus = Get-CimInstance Win32_VideoController
echo $rams = Get-CimInstance Win32_PhysicalMemory
echo $board = Get-CimInstance Win32_BaseBoard
echo $bios = Get-CimInstance Win32_BIOS
echo $disks = Get-CimInstance Win32_DiskDrive
echo $nics = Get-CimInstance Win32_NetworkAdapter ^| Where-Object { $_.NetEnabled -eq $true }
echo $nicconfigs = Get-CimInstance Win32_NetworkAdapterConfiguration ^| Where-Object { $_.IPEnabled -eq $true }
echo $sysprod = Get-CimInstance Win32_ComputerSystemProduct
echo $compsys = Get-CimInstance Win32_ComputerSystem
echo $enclosure = Get-CimInstance Win32_SystemEnclosure
echo.
echo Write-Host "========================= WINDOWS ========================="
echo Show-Val "OS" $os.Caption
echo Show-Val "Version" $os.Version
echo Write-Host ""
echo.
echo Write-Host "========================= CPU ========================="
echo Show-Val "Model" $cpu.Name
echo Show-Val "Manufacturer" $cpu.Manufacturer
echo Show-Val "Cores" $cpu.NumberOfCores
echo Show-Val "Threads" $cpu.NumberOfLogicalProcessors
echo Show-Val "Frequency" $cpu.MaxClockSpeed " MHz"
echo Show-Val "Processor ID" $cpu.ProcessorId
echo Write-Host ""
echo.
echo Write-Host "========================= GPU ========================="
echo if ^($gpus^) {
echo     foreach ^($g in $gpus^) {
echo         Show-Val "GPU" $g.Name
echo         Show-Val "VRAM" $g.AdapterRAM " bytes"
echo         Show-Val "Driver" $g.DriverVersion
echo         Write-Host "---"
echo     }
echo } else {
echo     Show-Val "GPU" $null
echo }
echo Write-Host ""
echo.
echo Write-Host "========================= RAM ========================="
echo if ^($rams^) {
echo     foreach ^($r in $rams^) {
echo         Show-Val "Manufacturer" $r.Manufacturer
echo         Show-Val "Capacity" $r.Capacity " bytes"
echo         Show-Val "Speed" $r.Speed " MHz"
echo         Show-Val "Serial Number" $r.SerialNumber
echo         Write-Host "---"
echo     }
echo } else {
echo     Show-Val "RAM" $null
echo }
echo Write-Host ""
echo.
echo Write-Host "========================= MOTHERBOARD ========================="
echo Show-Val "Manufacturer" $board.Manufacturer
echo Show-Val "Model" $board.Product
echo Show-Val "Serial Number" $board.SerialNumber
echo Show-Val "Version" $board.Version
echo Show-Val "Tag" $board.Tag
echo Show-Val "Slots RAM" $board.NumberOfSlots
echo Write-Host ""
echo.
echo Write-Host "========================= BIOS ========================="
echo Show-Val "Manufacturer" $bios.Manufacturer
echo Show-Val "Version" $bios.SMBIOSBIOSVersion
echo Show-Val "Serial Number" $bios.SerialNumber
echo Show-Val "Release Date" $bios.ReleaseDate
echo Show-Val "Version SMBIOS" $bios.SMBIOSMajorVersion","$bios.SMBIOSMinorVersion
echo Show-Val "Mode" $bios.BIOSVersion
echo Show-Val "Statut" $bios.Status
echo Write-Host ""
echo.
echo Write-Host "========================= STORAGE ========================="
echo if ^($disks^) {
echo     foreach ^($d in $disks^) {
echo         Show-Val "Model" $d.Model
echo         Show-Val "Serial Number" $d.SerialNumber
echo         Show-Val "Size" $d.Size " bytes"
echo         Write-Host "---"
echo     }
echo } else {
echo     Show-Val "Storage" $null
echo }
echo Write-Host ""
echo.
echo Write-Host "========================= NETWORK ========================="
echo if ^($nics^) {
echo     foreach ^($n in $nics^) {
echo         Show-Val "Adapter" $n.Name
echo         Show-Val "MAC" $n.MACAddress
echo         Show-Val "Vitesse" $n.Speed " bps"
echo         Show-Val "Fabricant" $n.Manufacturer
echo         Show-Val "Type" $n.AdapterType
echo         Show-Val "Statut connexion" $n.NetConnectionStatus
echo         $cfg = $nicconfigs ^| Where-Object { $_.MACAddress -eq $n.MACAddress } ^| Select-Object -First 1
echo         if ^($cfg^) {
echo             Show-Val "Adresse IP" ^($cfg.IPAddress -join ", "^)
echo             Show-Val "Masque sous-reseau" ^($cfg.IPSubnet -join ", "^)
echo             Show-Val "Passerelle" ^($cfg.DefaultIPGateway -join ", "^)
echo             Show-Val "DNS" ^($cfg.DNSServerSearchOrder -join ", "^)
echo             Show-Val "DHCP active" $cfg.DHCPEnabled
echo             Show-Val "Serveur DHCP" $cfg.DHCPServer
echo         } else {
echo             Show-Val "Adresse IP" $null
echo             Show-Val "Masque sous-reseau" $null
echo             Show-Val "Passerelle" $null
echo             Show-Val "DNS" $null
echo             Show-Val "DHCP active" $null
echo             Show-Val "Serveur DHCP" $null
echo         }
echo         Write-Host "---"
echo     }
echo } else {
echo     Show-Val "Network" $null
echo }
echo Write-Host ""
echo.
echo Write-Host "========================= SYSTEM ========================="
echo Show-Val "UUID" $sysprod.UUID
echo Show-Val "Fabricant systeme" $compsys.Manufacturer
echo Show-Val "Modele systeme" $compsys.Model
echo Show-Val "Nom machine" $compsys.Name
echo Show-Val "Utilisateur connecte" $compsys.UserName
echo Show-Val "Domaine" $compsys.Domain
echo Show-Val "RAM totale" $compsys.TotalPhysicalMemory " bytes"
echo Show-Val "Type boitier" $enclosure.ChassisTypes
echo Show-Val "Numero serie boitier" $enclosure.SerialNumber
echo Write-Host ""
echo Write-Host "================================================================================"
echo Write-Host "Scan completed."
echo Write-Host "Some information about your components remains unexposed by the manufacturer, and is therefore displayed as N/A ($global:NACount)" -ForegroundColor Red
echo Write-Host "================================================================================"
) > "%PSFILE%"
exit /b

:TIMER

:COUNTDOWN

set /a MIN=TIMELEFT/60
set /a SEC=TIMELEFT%%60

if %SEC% LSS 10 set SEC=0%SEC%

title Hardware Details - KEY EXPIRATION %MIN%:%SEC%

timeout /t 1 /nobreak >nul

set /a TIMELEFT-=1

if %TIMELEFT% LEQ 0 (
    title Hardware Details - KEY EXPIRED
    exit
)

goto COUNTDOWN

:EXIT
exit