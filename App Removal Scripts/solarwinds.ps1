$agentPaths = $(Join-path ${Env:ProgramFiles(x86)} "Advanced Monitoring Agent GP"), $(Join-path ${Env:ProgramFiles(x86)} "Advanced Monitoring Agent")

foreach ($path in $agentPaths) {
    if (Test-Path -Path "$path\winagent.exe") {
        if(test-path "$path\settings.ini"){
            Rename-Item -Path "$path\settings.ini" -NewName "delsettings.ini"
        }
        $Process = start-process "$path\winagent.exe" -argumentlist "/removequiet" -wait -passthru
        try{
          $Command = get-command Translate-ExitCode -erroraction stop
          Translate-ExitCode -Process $Process -AutoOutput
        }
        catch{
          write-output "Uninstall process exited with code: $($Process.exitcode)"
        }
    }
}
Exit
