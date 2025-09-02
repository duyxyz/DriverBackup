# ================= DRIVER BACKUP TOOL v2.0 ==================
# Author: DuyNguyen2k6
# Github: https://github.com/DuyNguyen2k6/Tool
# ============================================================

# ===== AUTO-ELEVATE with Windows Terminal =====
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole]::Administrator)) {

    if ($MyInvocation.MyCommand.Path) {
        $scriptPath = $MyInvocation.MyCommand.Path
        $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"

        if (Test-Path $wtPath) {
            Start-Process -FilePath $wtPath -ArgumentList "powershell -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        } else {
            Start-Process -FilePath "powershell" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        }
    }
    exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

# ===== LOGGING =====
$LogFile = Join-Path $PSScriptRoot "DriverBackup.log"
function Write-Log {
    param([string]$msg)
    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$time | $msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

function Show-Header {
    Clear-Host
    Write-Host "==========================================="
    Write-Host "           DRIVER BACKUP TOOL "
    Write-Host "==========================================="
}

function DB-Menu {
    Show-Header
    Write-Host "1. Backup drivers"
    Write-Host "2. Restore drivers"
    Write-Host "3. Check missing/faulty drivers"
    Write-Host "4. Exit"
    Write-Host "-------------------------------------------"
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
    if (!$folder) { Write-Host "No folder selected."; return }

    Write-Host "Backing up drivers to: $folder ..."
    Write-Log "Backup started to $folder"
    try {
        Start-Process -FilePath "dism.exe" -ArgumentList "/online /export-driver /destination:`"$folder`"" -Wait -NoNewWindow
        Write-Host "Backup completed."
        Write-Log "Backup completed to $folder"

        # Xuất danh sách driver ra file
        $driverListFile = Join-Path $folder "DriverList.txt"
        pnputil /enum-drivers | Out-File -FilePath $driverListFile -Encoding UTF8
        Write-Log "Driver list saved to $driverListFile"
    } catch {
        Write-Host "Backup failed: $_"
        Write-Log "Backup failed: $_"
    }
    Read-Host "Press Enter to return"
}

function DB-Restore {
    $folder = DB-PickFolder
    if (!$folder) { Write-Host "No folder selected."; return }

    Write-Host "Restoring drivers from: $folder ..."
    Write-Log "Restore started from $folder"
    try {
        Start-Process -FilePath "pnputil.exe" -ArgumentList "/add-driver `"$folder\*.inf`" /subdirs /install" -Wait -NoNewWindow
        Write-Host "Restore completed."
        Write-Log "Restore completed from $folder"
    } catch {
        Write-Host "Restore failed: $_"
        Write-Log "Restore failed: $_"
    }
    Read-Host "Press Enter to return"
}

function DB-Check {
    Write-Host "Checking for missing/faulty drivers..."
    Write-Log "Check missing/faulty drivers started"
    try {
        $drivers = Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
        if ($drivers) {
            Write-Host "`nMissing/Faulty drivers detected:"
            $drivers | ForEach-Object { Write-Host "- $($_.Name)" }
            $drivers | ForEach-Object { $_.Name } | Out-File -FilePath (Join-Path $PSScriptRoot "FaultyDrivers.txt") -Encoding UTF8
            Write-Log "Faulty drivers detected and saved to FaultyDrivers.txt"
        } else {
            Write-Host "No missing/faulty drivers detected."
            Write-Log "No missing/faulty drivers detected"
        }
    } catch {
        Write-Host "Check failed: $_"
        Write-Log "Check failed: $_"
    }
    Read-Host "Press Enter to return"
}

# ==== MAIN LOOP ====
do {
    DB-Menu
    $choice = Read-Host "Choose option [1-4]"
    switch ($choice) {
        "1" { DB-Backup }
        "2" { DB-Restore }
        "3" { DB-Check }
        "4" { break }
        default { Write-Host "Invalid option. Try again."; Read-Host }
    }
} while ($choice -ne "4")

Write-Host "Exiting Driver Backup Tool..."
Write-Log "Tool exited"
