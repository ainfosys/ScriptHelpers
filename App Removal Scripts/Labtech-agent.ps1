$LTUniversalUninstaller = "https://s3.amazonaws.com/assets-cp/assets/Agent_Uninstaller.zip"
$TempDir = "$ENV:SystemDrive\Windows\Temp"
$LTSvcPath = 'C:\Windows\ltsvc\ltsvc.exe'

if($Force -eq $true -or (Test-Path $LTSvcPath)){
    Write-Output "Downloading Universal Agent Uninstaller"
    Start-BitsTransfer -Source $LTUniversalUninstaller -Destination "$TempDir\Agent_Uninstaller.zip"
    Write-Output "Downloaded Universal Agent Uninstaller"
    Write-Output "Expanding Agent_Uninstaller.zip"
    Expand-Archive -LiteralPath "$TempDir\Agent_Uninstaller.zip" -DestinationPath "$TempDir\Agent Uninstaller"
    Write-Output "Expanded Agent_Uninstaller.zip"
    Write-Output "Starting Uninstall."
    $UninstallProcess = Start-Process -FilePath "$TempDir\Agent Uninstaller\Agent_Uninstall.exe" -Wait -PassThru
    Write-Output "Completed Uninstall. Exit Code: $($UninstallProcess.ExitCode)"
} else {
    Write-Output "$LTSvcPath Not Found. Uninstall not required"
}
