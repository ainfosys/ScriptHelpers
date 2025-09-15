try{
    $Command = get-command Get-InstalledApps -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-InstalledApps.ps1') | iex
}
$Apps = Get-InstalledApps
$App = $Apps | where {$_.DisplayName -ieq "Ecosystem Agent"} | select -first 1
$Process = Start-process $App.UninstallString -ArgumentList "/Silent" -wait -PassThru
try{
    $Command = Get-Command Translate-ExitCode -ErrorAction Stop
    Translate-ExitCode -Process $Process -AutoOutput
}catch{
    Write-Output "Uninstall process exited with code: $($Process.ExitCode)"
}
