# Specify the application names
$ztacApplicationName = "ZTAC"
$snapAgentApplicationName = "SnapAgent"

# Function to uninstall an application by name
function Uninstall-Application($appName) {
    $identifyingNumber = (Get-WmiObject Win32_Product | Where-Object {$_.Name -eq $appName}).IdentifyingNumber
    if (-not [string]::IsNullOrEmpty($identifyingNumber)) {
        Start-Process -FilePath "MsiExec.exe" -ArgumentList "/X$identifyingNumber /quiet /qn" -Wait -ErrorAction ignore
        Start-Sleep -Seconds 10
    } else {
        Write-Host "$appName IdentifyingNumber not found or is empty. Please check the application installation."
    }
}

Write-output "Stopping running services"

# Stop the snapw.exe process
Get-Process -Name "snapw" -ErrorAction ignore | Stop-Process -Force -ErrorAction ignore

# Stop the snap service
Stop-Service -Name "snap" -ErrorAction ignore

# Uninstall SnapAgent
Write-output "Attempting normal uninstall of snapagent"
Uninstall-Application -appName $snapAgentApplicationName -ErrorAction ignore

# Wait for 5 seconds
Start-Sleep -Seconds 5

# Stop the ztac service
Stop-Service -Name "ztac" -ErrorAction ignore

# Uninstall ZTAC
Write-output "Attempting normal uninstall of ztac"
Uninstall-Application -appName $ztacApplicationName -ErrorAction ignore

# Define an array of registry keys to delete
$registryKeys = @(
    "HKLM:\SOFTWARE\Classes\Installer\Features\0E1D3F0C2B974FA4AA0418F12B055384",
    "HKLM:\SOFTWARE\Classes\Installer\Products\0E1D3F0C2B974FA4AA0418F12B055384",
    "HKLM:\SOFTWARE\Classes\Installer\Products\0E1D3F0C2B974FA4AA0418F12B055384\SourceList",
    "HKLM:\SOFTWARE\Classes\Installer\Products\0E1D3F0C2B974FA4AA0418F12B055384\SourceList\Media",
    "HKLM:\SOFTWARE\Classes\Installer\Products\0E1D3F0C2B974FA4AA0418F12B055384\SourceList\Net",
    "HKLM:\SOFTWARE\Classes\Installer\UpgradeCodes\7CF0653F8B24F2647B3A70510A96BEE6",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes\7CF0653F8B24F2647B3A70510A96BEE6",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\08C8C87010175A141912F6695F06EB95",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\5E3D36BBC4ADCA749AC6CC3774478B04",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\74A044CACC826754BB48542EA5681E4C",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A3129D8FE202CCF47B233E82C70367D2",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\A73F059633BC8314597EE7F81A662796",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\C0016A60CBED93E41900FCBD4BC10AB4",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\DB4ABEA1DA4832048BCCF78860ADA944",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F1AB931B4E8A02A4F8E5F828409E4DD1",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\F81ECEA5C9A7CA3409D05D38A602B11C",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\0E1D3F0C2B974FA4AA0418F12B055384",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\0E1D3F0C2B974FA4AA0418F12B055384\Features",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\0E1D3F0C2B974FA4AA0418F12B055384\InstallProperties",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\0E1D3F0C2B974FA4AA0418F12B055384\Patches",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\0E1D3F0C2B974FA4AA0418F12B055384\Usage",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\1C36F61EB5609424C81AF5A41E3C6894",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\C7BFF9AEFE6FEFB4EBC694AD37DF9C5A",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{C0F3D1E0-79B2-4AF4-AA40-811FB2503548}",
    "HKLM:\SYSTEM\CurrentControlSet\Services\ZTAC",
    "HKLM:\SYSTEM\CurrentControlSet\Services\ZtacFltr",
    "HLKM:\SOFTWARE\Classes\Installer\Features\1C36F61EB5609424C81AF5A41E3C6894",
    "HKLM:\SOFTWARE\Classes\Installer\Products\1C36F61EB5609424C81AF5A41E3C6894",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{E16F63C1-065B-4249-8CA1-5F4AE1C38649}",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EA9FFB7C-F6EF-4BFE-BE6C-49DA73FDC9A5}",
    "HKLM:\SYSTEM\ControlSet002\Services\ZTAC",
    "HKLM:\SYSTEM\ControlSet002\Services\ZtacFltr",
    "HKLM:\SYSTEM\Setup\FirstBoot\Services\Snap",
    "HKLM:\SYSTEM\Setup\FirstBoot\Services\ZTAC",
    "Registry::HKEY_CLASSES_ROOT\Installer\Products\C7BFF9AEFE6FEFB4EBC694AD37DF9C5A"
)

# Loop through each registry key and delete it
Write-output "Removing registry keys"
foreach ($key in $registryKeys) {
    Remove-Item -Path $key -force -erroraction ignore
}

# Remove the services
Write-output "Stopping and removing services"
sc stop ZTAC
sc delete ZTAC
sc stop ZtacFltr
sc delete ZtacFltr
sc stop snap
sc delete snap

# Wait for 10 seconds
Start-Sleep -Seconds 10

# Remove entire "C:\Program Files (x86)\Blackpoint\" directory
Write-output "Removing blackpoint program files directory"
Remove-Item -Path "C:\Program Files (x86)\Blackpoint\" -Force -Recurse -ErrorAction ignore
Remove-Item -Path "C:\ProgramData\Blackpoint" -force -recurse -erroraction ignore

# uninstall drivers
$AllDrivers = Get-WindowsDriver -Online
$BlackpointDriver = $AllDrivers | where {$_.providerName -ieq "Blackpoint Cyber"}
if([bool]$BlackpointDriver){
  write-output "Attempting removal of blackpoint driver"
  foreach($driver in $BlackpointDriver){
    pnputil /delete-driver $($driver.Driver) /uninstall /force
  }
}
