# ================= TOOLKIT MENU v1.0 ==================
# Author: Nhat (DuyNguyen2k6)
# Github: https://github.com/DuyNguyen2k6/Tool
# ======================================================

# ===== AUTO-ELEVATE: Always run as ADMIN =====
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    if ($MyInvocation.MyCommand.Path) {
        $scriptPath = $MyInvocation.MyCommand.Path
        $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
        if (Test-Path $wtPath) {
            Start-Process -FilePath $wtPath -ArgumentList "powershell -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        } else {
            Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        }
    } else {
        $code = $MyInvocation.MyCommand.ScriptBlock.ToString()
        $temp = [IO.Path]::GetTempFileName() -replace '.tmp$', '.ps1'
        Set-Content -Path $temp -Value $code -Encoding UTF8
        $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
        if (Test-Path $wtPath) {
            Start-Process -FilePath $wtPath -ArgumentList "powershell -NoProfile -ExecutionPolicy Bypass -File `"$temp`"" -Verb RunAs
        } else {
            Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$temp`"" -Verb RunAs
        }
    }
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Menu {
    Clear-Host
    Write-Host "++++++++++++++ TOOLKIT MENU v1.0 +++++++++++++++" -ForegroundColor White
    Write-Host "------------------------------------------------" -ForegroundColor White
    Write-Host "             Author: (DuyNguyen2k6)"
    Write-Host "------------------------------------------------" -ForegroundColor White
    Write-Host "1. System Information" -ForegroundColor Yellow
    Write-Host "2. Defender Control" -ForegroundColor Green
    Write-Host "3. Driver Backup" -ForegroundColor Blue
    Write-Host "4. Schedule Shutdown" -ForegroundColor Magenta
    Write-Host "5. Activate Windows/Office" -ForegroundColor DarkCyan
    Write-Host "6. Clean Temp folder" -ForegroundColor Red
    Write-Host "7. Open Disk Cleanup" -ForegroundColor DarkYellow
    Write-Host "8. Speed Test " -ForegroundColor Green
    
}

function Download-And-Run-Speedtest {
    $destDir = "$env:LOCALAPPDATA\SpeedtestCLI"
    if (!(Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory | Out-Null }

    $dest = "$destDir\speedtest.exe"
    $zip = "$destDir\speedtest.zip"
    $extractDir = "$destDir\speedtest_extracted"
    $url = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip"  # Cập nhật link mới nhất nếu cần

    if (-Not (Test-Path $dest)) {
        Write-Host "Downloading Speedtest CLI from Ookla..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $zip
        Write-Host "Extracting..." -ForegroundColor Yellow
        Expand-Archive -Path $zip -DestinationPath $extractDir -Force
        $exeFile = Get-ChildItem -Path $extractDir -Filter speedtest.exe -Recurse | Select-Object -First 1
        if ($exeFile) {
            Move-Item -Path $exeFile.FullName -Destination $dest -Force
        } else {
            Write-Host "speedtest.exe not found after extracting. Please check the ZIP file." -ForegroundColor Red
            return
        }
        Remove-Item $zip -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Speedtest CLI already downloaded. Skipping download..." -ForegroundColor Green
    }
    Write-Host "Running Speedtest CLI..." -ForegroundColor Cyan
    & $dest
    Write-Host "Press Enter to return to menu..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}

function Open-DiskCleanup {
    Write-Host "Opening Disk Cleanup..." -ForegroundColor Cyan
    Start-Process "cleanmgr.exe"
    Write-Host "Disk Cleanup launched. Press Enter to return to menu..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}


function Clean-TempFolder {
    $temp = $env:TEMP
    Write-Host "Cleaning Temp folder: $temp ..." -ForegroundColor Cyan
    try {
        # Xóa tất cả file và thư mục con trong %temp%
        Get-ChildItem -Path $temp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "Temp folder cleaned successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Some files could not be deleted (may be in use)." -ForegroundColor Yellow
    }
    Write-Host "Press Enter to return to menu..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}

function Run-MAS {
    $URL = 'https://raw.githubusercontent.com/DuyNguyen2k6/Tool/main/MAS_AIO.cmd'
    $rand = [Guid]::NewGuid().Guid
    $FilePath = "$env:USERPROFILE\AppData\Local\Temp\MAS_$rand.cmd"
    Write-Host "Downloading and running MAS_AIO.cmd..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $URL -OutFile $FilePath
    Start-Process "cmd.exe" -ArgumentList "/c `"$FilePath`"" -Verb RunAs -Wait
    Remove-Item $FilePath -ErrorAction SilentlyContinue
    Write-Host "MAS_AIO finished. Press Enter to return to menu..." -ForegroundColor Yellow
    [void][System.Console]::ReadLine()
}

# ============ SHUTDOWN SCHEDULER ============
function Show-ShutdownScheduler {
    function Schedule-Action {
        param (
            [string]$action,
            [int]$minutes
        )
        if (-not ($minutes -is [int]) -or $minutes -le 0) {
            Write-Host "Minutes must be a positive integer!" -ForegroundColor Red
            return
        }
        $seconds = $minutes * 60
        Write-Host ""
        Write-Host "$action will execute after $minutes minute(s)." -ForegroundColor Cyan
        Write-Host "Press 'Q' then Enter at any time to cancel." -ForegroundColor Yellow

        for ($i = $seconds; $i -ge 0; $i--) {
            $time = [TimeSpan]::FromSeconds($i).ToString("hh\:mm\:ss")
            Write-Host "`rTime left: $time   " -NoNewline

            if ([console]::KeyAvailable) {
                $key = [console]::ReadKey($true)
                if ($key.KeyChar -eq 'q' -or $key.KeyChar -eq 'Q') {
                    Write-Host "`nCancelled by user." -ForegroundColor Green
                    return
                }
            }
            Start-Sleep -Milliseconds 950
        }

        switch ($action) {
            "shutdown" { shutdown /s /f /t 0 }
            "restart"  { shutdown /r /f /t 0 }
            "sleep"    { rundll32.exe powrprof.dll,SetSuspendState 0,1,0 }
        }
    }

    do {
        Clear-Host
        Write-Host "===============================" -ForegroundColor Magenta
        Write-Host "      POWER SCHEDULER TOOL     " -ForegroundColor Yellow
        Write-Host "===============================" -ForegroundColor Magenta
        Write-Host "1. Shutdown" -ForegroundColor Red
        Write-Host "2. Restart" -ForegroundColor Cyan
        Write-Host "3. Sleep" -ForegroundColor Green
        Write-Host "4. Cancel scheduled action" -ForegroundColor DarkYellow
        Write-Host "0. Back to main menu" -ForegroundColor Gray
        $choice = Read-Host "`nSelect an option (0-4)"

        switch ($choice) {
            "1" {
                $min = Read-Host "Shutdown after how many minutes?"
                Schedule-Action -action "shutdown" -minutes $min
            }
            "2" {
                $min = Read-Host "Restart after how many minutes?"
                Schedule-Action -action "restart" -minutes $min
            }
            "3" {
                $min = Read-Host "Sleep after how many minutes?"
                Schedule-Action -action "sleep" -minutes $min
            }
            "4" {
                shutdown /a
                Write-Host "Cancelled any scheduled shutdown/restart." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
            "0" { return }
            default {
                Write-Host "Invalid option!" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }

        if ($choice -ne "0") {
            Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
            [void][System.Console]::ReadLine()
        }

    } while ($choice -ne "0")
}

function Show-SystemInformation {
    Clear-Host
    Write-Host "=== SYSTEM INFORMATION REPORT ===" -ForegroundColor Cyan

    # OS & User
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "`n=== OS / USER INFO ===" -ForegroundColor Yellow
    Write-Host "OS: $($os.Caption) $($os.Version) ($($os.OSArchitecture))"
    Write-Host "Computer Name: $($os.CSName)"
    Write-Host "User: $env:USERNAME"

    # System Model
    $sys = Get-CimInstance Win32_ComputerSystem
    Write-Host "System Model: $($sys.Model)"

    # Windows Activation Info 
    Write-Host "`n=== WINDOWS ACTIVATION ===" -ForegroundColor Green
    try {
        $lic = Get-CimInstance -Query "SELECT PartialProductKey, LicenseStatus FROM SoftwareLicensingProduct WHERE LicenseStatus = 1 AND PartialProductKey IS NOT NULL" -ErrorAction Stop
        if ($lic) {
            Write-Host "Windows Activation: Activated (Key: ****-$($lic.PartialProductKey))"
        } else {
            Write-Host "Windows Activation: Not activated"
        }
    } catch {
        Write-Host "Activation check failed: $($_.Exception.Message)"
    }

    # Boot Time
    $bootRaw = $os.LastBootUpTime
    Write-Host "`n=== BOOT TIME ===" -ForegroundColor Magenta
    if ($bootRaw -and $bootRaw -match '^\d{14}\.\d{6}\+\d{3}$') {
        try {
            $bootTime = [Management.ManagementDateTimeConverter]::ToDateTime($bootRaw)
            Write-Host "Boot Time: $bootTime"
        } catch {
            Write-Host "Boot Time: Invalid format"
        }
    } else {
        Write-Host "Boot Time: N/A"
    }

    # CPU
    $cpu = Get-CimInstance Win32_Processor
    Write-Host "`n=== CPU INFO ===" -ForegroundColor Cyan
    Write-Host "Processor: $($cpu.Name)"
    Write-Host "Cores: $($cpu.NumberOfCores)"
    Write-Host "Logical Processors: $($cpu.NumberOfLogicalProcessors)"

    # GPU
    Write-Host "`n=== GPU INFO ===" -ForegroundColor Blue
    Get-CimInstance Win32_VideoController | ForEach-Object {
        Write-Host "$($_.Name)"
    }

    # RAM
    $ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    Write-Host "`n=== RAM INFO ===" -ForegroundColor DarkYellow
    Write-Host "Total: $ram GB"
    Write-Host "Free: $freeRam GB"

    # Disk
    Write-Host "`n=== DISK INFO ===" -ForegroundColor DarkCyan
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $size = [math]::Round($_.Size / 1GB, 2)
        $free = [math]::Round($_.FreeSpace / 1GB, 2)
        Write-Host "$($_.DeviceID) - $($_.VolumeName): $free GB free / $size GB total"
    }

    # Network
    Write-Host "`n=== NETWORK ADAPTERS ===" -ForegroundColor DarkGreen
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Write-Host "$($_.Name): $($_.InterfaceDescription) - $($_.LinkSpeed)"
    }

    Write-Host "`n=== IP CONFIGURATION ===" -ForegroundColor DarkMagenta
    Get-NetIPConfiguration | ForEach-Object {
        Write-Host "$($_.InterfaceAlias): IP = $($_.IPv4Address.IPAddress), Gateway = $($_.IPv4DefaultGateway.NextHop)"
    }

    # Mainboard & BIOS
    Write-Host "`n=== MOTHERBOARD INFO ===" -ForegroundColor Red
    $baseboard = Get-CimInstance Win32_BaseBoard
    Write-Host "Manufacturer: $($baseboard.Manufacturer)"
    Write-Host "Model: $($baseboard.Product)"

    $bios = Get-CimInstance Win32_BIOS
    Write-Host "`nBIOS Version: $($bios.SMBIOSBIOSVersion)"
    Write-Host "BIOS Vendor: $($bios.Manufacturer)"

    Write-Host "`n=== DONE ===" -ForegroundColor Cyan

    if ($Host.Name -eq "ConsoleHost") {
        Write-Host "`nScript completed. Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    Write-Host ""
    Write-Host "Press Enter to return to the main menu..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}

function Show-DefenderControl {
    function Show-Status {
        $realTime = (Get-MpPreference).DisableRealtimeMonitoring
        $tamper = (Get-CimInstance -Namespace "root\Microsoft\Windows\Defender" -ClassName MSFT_MpComputerStatus).IsTamperProtected

        Write-Host "`n===== Defender Status =====" -ForegroundColor Cyan
        Write-Host "Real-time Protection: " -NoNewline
        if ($realTime) {
            Write-Host "OFF" -ForegroundColor Red
        } else {
            Write-Host "ON" -ForegroundColor Green
        }

        Write-Host "Tamper Protection:     " -NoNewline
        if ($tamper) {
            Write-Host "ON (cannot change via script)" -ForegroundColor Yellow
        } else {
            Write-Host "OFF" -ForegroundColor Gray
        }
        Write-Host ""
    }

    function Show-Menu-Defender {
        Clear-Host
        Write-Host "=== Windows Defender Control Tool ===" -ForegroundColor Cyan
        Write-Host "1. Disable Real-time Protection"
        Write-Host "2. Enable Real-time Protection"
        Write-Host "3. Completely Disable Defender (Registry)"
        Write-Host "4. Enable Defender"
        Write-Host "0. Exit"
    }

    do {
        Show-Menu-Defender
        $choice = Read-Host "`nEnter your choice"
        switch ($choice) {
            "1" {
                Write-Host ">> Disabling Real-time Protection..." -ForegroundColor Yellow
                Set-MpPreference -DisableRealtimeMonitoring $true
                Show-Status
            }
            "2" {
                Write-Host ">> Enabling Real-time Protection..." -ForegroundColor Green
                Set-MpPreference -DisableRealtimeMonitoring $false
                Show-Status
            }
            "3" {
                Write-Host ">> Disabling Windows Defender completely..." -ForegroundColor Red
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Force
                Write-Host ">> Please restart your computer to apply changes." -ForegroundColor DarkYellow
                Show-Status
            }
            "4" {
                Write-Host ">> Enabling Windows Defender..." -ForegroundColor Green
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
                Write-Host ">> Please restart your computer to apply changes." -ForegroundColor DarkYellow
                Show-Status
            }
        }
        if ($choice -ne "0") {
            Write-Host "`nPress Enter to return to the menu..." -ForegroundColor DarkGray
            Read-Host
        }
    } while ($choice -ne "0")

    Write-Host ">> Exiting Defender Control." -ForegroundColor Gray
}

function Show-DriverBackup {
    Add-Type -AssemblyName System.Windows.Forms

    function DB-Menu {
        Clear-Host
        Write-Host "============ DRIVER BACKUP TOOL ============" -ForegroundColor Cyan
        Write-Host "1. Backup drivers"
        Write-Host "2. Restore drivers"
        Write-Host "3. Check missing/faulty drivers"
        Write-Host "4. Exit"
    }

    function DB-PickFolder {
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select folder"
        $fbd.ShowNewFolderButton = $true
        if ($fbd.ShowDialog() -eq "OK") {
            return $fbd.SelectedPath
        } else {
            return $null
        }
    }

    function DB-Backup {
        $folder = DB-PickFolder
        if (!$folder) { Write-Host "No folder selected!"; Read-Host; return }
        Write-Host "Backing up drivers to $folder ..." -ForegroundColor Yellow
        Start-Process -Verb RunAs -FilePath "dism.exe" -ArgumentList "/online /export-driver /destination:`"$folder`"" -Wait
        Write-Host "Backup completed." -ForegroundColor Green
        Read-Host
    }

    function DB-Restore {
        $folder = DB-PickFolder
        if (!$folder) { Write-Host "No folder selected!"; Read-Host; return }
        Write-Host "Restoring drivers from $folder ..." -ForegroundColor Yellow
        Start-Process -Verb RunAs -FilePath "pnputil.exe" -ArgumentList "/add-driver `"$folder\*.inf`" /subdirs /install" -Wait
        Write-Host "Restore completed." -ForegroundColor Green
        Read-Host
    }

    function DB-Check {
        Write-Host "Checking for missing/faulty drivers..." -ForegroundColor Yellow
        $drivers = Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
        if ($drivers) {
            Write-Host "List of missing/faulty drivers:" -ForegroundColor Red
            $drivers | ForEach-Object { Write-Host $_.Name }
        } else {
            Write-Host "No missing/faulty drivers detected." -ForegroundColor Green
        }
        Read-Host
    }

    do {
        DB-Menu
        $choice = Read-Host "Choose option [1-4]"
        switch ($choice) {
            "1" { DB-Backup }
            "2" { DB-Restore }
            "3" { DB-Check }
            "4" { break }
            default { Write-Host "Invalid option. Try again." -ForegroundColor Red; Read-Host }
        }
    } while ($choice -ne "4")

    Write-Host ""
    Write-Host "Press Enter to return to the main menu..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}

# ==== MAIN MENU LOOP ====
while ($true) {
    Show-Menu
    $choice = Read-Host "Select an option [1/2/3/4/m]"
    switch ($choice) {
        "1" { Show-SystemInformation }
        "2" { Show-DefenderControl }
        "3" { Show-DriverBackup }
        "4" { Show-ShutdownScheduler }
        "5" { Run-MAS }
        "6" { Clean-TempFolder }
        "7" { Open-DiskCleanup }
        "8" { Download-And-Run-Speedtest }
        default { Write-Host "Invalid selection, please try again." -ForegroundColor Red }
    }
}
