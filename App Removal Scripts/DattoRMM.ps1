try{
    $Command = Get-command Translate-ExitCode -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Translate-ExitCode.ps1') | iex
}
$Uninstallers = Resolve-Path "$($env:ProgramFiles)*\CentraStage\uninst.exe"
$Arguments = @"
/VERYSILENT /NORESTART
"@
foreach($Uninstaller in $Uninstallers) {
    $Process = Start-Process "$Uninstaller" -ArgumentList $Arguments -Passthru -wait
    Translate-ExitCode -process $Process -AutoOutput
}
Exit
