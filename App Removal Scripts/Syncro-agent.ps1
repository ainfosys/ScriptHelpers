# provided by syncro community forums
function uninstallerMSI {
  Write-Host "--"
  Write-Host "-- Removing MSI --"
  Write-Host "--"
  $productId = "{B7F56D3D-2AD3-4021-9D36-3B9E9C9FBE33}"
  Start-Process "MsiExec" -ArgumentList "/x $($productId) /qn /norestart UNINSTALL_CODE=$($env:uninstall_code)" -Wait
  Start-Sleep -Seconds 1
  Remove-Item -Recurse -Force -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($productId)"
  Remove-Item -Recurse -Force -Path "HKLM:\SOFTWARE\Classes\Installer\Products\D3D65F7B3DA21204D963B3E9C9F9EB33"
}

function stopProcesses {
    param ($name)
    Write-Host "Stopping Processes"
    Stop-Process -Name "$($name).App.Runner.exe" -Force
    Stop-Process -Name "$($name).Service.Runner.exe" -Force
    Stop-Process -Name "$($name)Live.Agent.Runner.exe" -Force
    Stop-Process -Name "$($name)Live.Agent.Service.exe" -Force
    Stop-Process -Name "$($name).Overmind.Service.exe" -Force
    Start-Sleep -Seconds 1
}

function removeLeftovers {
    param ($name)
    if ($name -like "Syncro" -or $name -like "Kabuto") {
        Write-Host "--"
        Write-Host "-- Removing $name --"
        Write-Host "--"
        removeServices $name
        Start-Sleep -Seconds 2
        removeFiles $name
        removeRegistry $name
    }
}

function removeServices {
    param ($name)
    Write-Host "Removing Services"
    Set-Service -Name "$($name)" -StartupType Disabled
    Set-Service -Name "$($name)Live" -StartupType Disabled
    Set-Service -Name "$($name)Overmind" -StartupType Disabled

    Stop-Service "$($name)"
    Stop-Service "$($name)Live"
    Stop-Service "$($name)Overmind"

    Remove-Service "$($name)" -Verbose
    Remove-Service "$($name)Live" -Verbose
    Remove-Service "$($name)Overmind" -Verbose
    Start-Sleep -Seconds 1
}

function removeFiles{
    param ($name)
    Write-Host "Removing Files"
    Remove-Item -Recurse -Force "C:\Program Files\$($name)"
    Remove-Item -Recurse -Force "C:\Program Files (x86)\$($name)"
    Remove-Item -Recurse -Force "C:\Program Files\RepairTech\$($name)"
    Remove-Item -Recurse -Force "C:\Program Files\RepairTech\LiveAgent"
    Remove-Item -Recurse -Force "C:\Program Files\RepairTech\SquirrelTemp"
    Remove-Item -Recurse -Force "C:\Program Files\RepairTech"
}
function removeRegistry {
    param ($name)
    Write-Host "Removing Registry files for App and Service"
    Remove-Item -Recurse -Force "HKLM:\Software\WOW6432Node\RepairTech"
    Remove-Item -Recurse -Force "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$($name)"
    Remove-Item -Recurse -Force "HKLM:\Software\RepairTech"
    Remove-Item -Recurse -Force "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$($name)"
    Remove-Item -Recurse -Force "HKLM:\System\CurrentControlSet\Services\$($name)"
    Remove-Item -Recurse -Force "HKLM:\System\CurrentControlSet\Services\$($name)Live"
    Remove-Item -Recurse -Force "HKLM:\System\CurrentControlSet\Services\$($name)Overmind"
}

function removeData {
    param ($name)
    Remove-Item -Recurse -Force "C:\ProgramData\$($name)"
}

Write-Host "Starting syncro agent uninstall"
$ErrorView="CategoryView"
uninstallerMSI
stopProcesses Kabuto
stopProcesses Syncro
stopProcesses WinRing0_1_2_0
removeLeftovers Kabuto
removeLeftovers Syncro
removeData Kabuto
removeData Syncro
Write-Host "Completed syncro agent uninstall"
$ErrorView="NormalView"
