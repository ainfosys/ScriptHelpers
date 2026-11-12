param(
    [parameter(Mandatory)]
    $applicationName,
    [parameter()]
    $processName
)

try
{
    [Net.ServicePointManager]::SecurityProtocol = 15360
}
catch
{
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
try{
    $Command = Get-command Get-InstalledApps -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-InstalledApps.ps1') | iex
}

if(!$ProcessName){
    $ProcessName = $applicationName
}

Get-process $ProcessName -ErrorAction SilentlyContinue | stop-process -Force -ErrorAction SilentlyContinue 

$apps = get-installedapps
$app = $apps | where {$_.displayname -ieq $applicationName}

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
    Write-Output "$applicationName not found on device"
}
Exit
