try{
    $Command = Get-command Get-InstalledApps -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-InstalledApps.ps1') | iex
}
$apps = get-installedapps
$app = $apps | where {$_.displayname -ieq "Parsec"}

if([bool]$app){
    $UninstallExe = $App.UninstallString -replace " /.*" -replace "`""
    $process = Start-Process $UninstallExe -ArgumentList "/S /norestart" -Wait -PassThru
    try{
        $Command = Get-Command Translate-ExitCode -ErrorAction Stop
        Translate-ExitCode -Process $Process -AutoOutput
    }catch{
        Write-Output "Uninstall process exited with code: $($Process.ExitCode)"
    }
}else{
    Write-Output "Parsec not found on device"
}
Exit
