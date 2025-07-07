try{
    $Command = get-command Get-InstalledApps -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-InstalledApps.ps1') | iex
}
$Apps = Get-InstalledApps
$App = $Apps | where {$_.DisplayName -ilike "*Automate Control Center*"}
$UninstallExe = $App.UninstallString -replace " /.*" -replace "`""
$UninstallArgs = $app.UninstallString -replace "`"" -replace ".*$(split-path $UninstallExe -Leaf) " -replace "/l.*"
$uninstallArgs = "/s " + "$uninstallArgs"
$Process = Start-process $UninstallExe -ArgumentList $uninstallArgs -wait -PassThru
try{
    $Command = Get-Command Translate-ExitCode -ErrorAction Stop
    Translate-ExitCode -Process $Process -AutoOutput
}catch{
    Write-Output "Uninstall process exited with code: $($Process.ExitCode)"
}
