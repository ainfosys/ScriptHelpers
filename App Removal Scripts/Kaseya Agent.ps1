try{
    $Command = get-command Get-InstalledApps -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-InstalledApps.ps1') | iex
}
$Apps = Get-InstalledApps
$App = $Apps | where {$_.DisplayName -ilike "Kaseya Agent*"}
$UninstallExe = $App.UninstallString -replace " /.*" -replace "`""
$Process = Start-process $UninstallExe -ArgumentList "/s /norestart" -wait -PassThru
try{
    $Command = Get-Command Translate-ExitCode -ErrorAction Stop
    Translate-ExitCode -Process $Process -AutoOutput
}catch{
    Write-Output "Uninstall process exited with code: $($Process.ExitCode)"
}
