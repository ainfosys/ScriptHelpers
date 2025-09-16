try{
    $Command = get-command Get-InstalledApps -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-InstalledApps.ps1') | iex
}

$Apps = Get-InstalledApps
$App = $Apps | where {$_.DisplayName -ieq "File Cache Service Agent"}
try{
    $Process = Start-process $App.UninstallString -ArgumentList "/Silent" -wait -PassThru -ErrorAction Stop
}
catch{
    # kill any process using unins000.exe
    try{
        $command = Get-FileLockProcess -ErrorAction stop
    }catch{
        (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/refs/heads/main/Functions/Get-LockedFileProcess.ps1') | iex
    }
    $Process = Get-FileLockProcess -FilePath $App.UninstallString
    if([bool]$Process){
        $Process | Stop-Process -Force
    }
    # kill any process using unins000.dat
    $Process = Get-FileLockProcess -FilePath $(Join-path $( split-path $App.UninstallString -Parent) "Unins000.dat")
    if([bool]$Process){
        $Process | Stop-Process -Force
    }

    # attempt uninstall again
    $Process = Start-process $App.UninstallString -ArgumentList "/Silent" -wait -PassThru
}

try{
    $Command = Get-Command Translate-ExitCode -ErrorAction Stop
    Translate-ExitCode -Process $Process -AutoOutput
}catch{
    Write-Output "Uninstall process exited with code: $($Process.ExitCode)"
}
Exit
