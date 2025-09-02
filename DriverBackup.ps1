# ================= DRIVER BACKUP TOOL v3.3 ==================
# Author: duyxyz
# Github: https://github.com/duyxyz/DriverBackup
# ============================================================

# ==== AUTO-ELEVATE with Windows Terminal ====
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltinRole]::Administrator)) {

    $scriptPath = $MyInvocation.MyCommand.Path
    $wtPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
    $args = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    if (Test-Path $wtPath) {
        Start-Process -FilePath $wtPath -ArgumentList $args -Verb RunAs
    } else {
        Start-Process -FilePath "powershell" -ArgumentList $args -Verb RunAs
    }
    return
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms

# ==== LOGGING ====
$LogFile = Join-Path $PSScriptRoot "DriverBackup.log"
function Write-Log($msg) {
    "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') | $msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# ==== HELPERS ====
function Pick-Folder($title="Select folder") {
    $fbd = New-Object Windows.Forms.FolderBrowserDialog
    $fbd.Description = $title
    $fbd.ShowNewFolderButton = $true
    if ($fbd.ShowDialog() -eq "OK") { return $fbd.SelectedPath } else { return $null }
}

# ==== ACTIONS ====
function Backup-Drivers {
    $folder = Pick-Folder "Select folder to save drivers"; if (!$folder) { return }
    Write-Host "Backing up drivers to $folder ..."
    Write-Log "Backup started to $folder"
    try {
        dism /online /export-driver /destination:"$folder" | Out-Null
        pnputil /enum-drivers | Out-File "$folder\DriverList.txt" -Encoding UTF8
        Write-Host "Backup completed. Driver list saved."
        Write-Log "Backup completed to $folder"
    } catch { Write-Log "Backup failed: $_"; Write-Error $_ }
    Read-Host "Press Enter to continue"
}

function Restore-Drivers {
    $folder = Pick-Folder "Select folder to restore drivers from"; if (!$folder) { return }
    Write-Host "Restoring drivers from $folder ..."
    Write-Log "Restore started from $folder"
    try {
        pnputil /add-driver "$folder\*.inf" /subdirs /install | Out-Null
        Write-Host "Restore completed."
        Write-Log "Restore completed from $folder"
    } catch { Write-Log "Restore failed: $_"; Write-Error $_ }
    Read-Host "Press Enter to continue"
}

function Check-Drivers {
    Write-Host "Checking for missing/faulty drivers..."
    Write-Log "Check drivers started"
    try {
        $drivers = Get-WmiObject Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
        if ($drivers) {
            Write-Host "`nMissing/Faulty drivers:"
            $drivers | ForEach-Object { Write-Host "- $($_.Name)" }
            $drivers | ForEach-Object Name | Out-File "$PSScriptRoot\FaultyDrivers.txt" -Encoding UTF8
            Write-Log "Faulty drivers detected and saved to FaultyDrivers.txt"
        } else {
            Write-Host "No issues detected."
            Write-Log "No faulty drivers"
        }
    } catch { Write-Log "Check failed: $_"; Write-Error $_ }
    Read-Host "Press Enter to continue"
}

# ==== MENU ====
do {
    Clear-Host
    Write-Host "==========================================="
    Write-Host "         DRIVER BACKUP TOOL v3.3"
    Write-Host "==========================================="
    Write-Host "1. Backup drivers"
    Write-Host "2. Restore drivers"
    Write-Host "3. Check missing/faulty drivers"
    Write-Host "4. Exit"
    Write-Host "-------------------------------------------"

    switch (Read-Host "Choose option [1-4]") {
        "1" { Backup-Drivers }
        "2" { Restore-Drivers }
        "3" { Check-Drivers }
        "4" { break }
        default { Write-Host "Invalid option."; Start-Sleep 1 }
    }
} while ($true)

Write-Host "Exiting Driver Backup Tool..."
Write-Log "Tool exited"
