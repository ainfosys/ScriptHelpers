$Uninstaller = "C:\Program Files (x86)\MspPlatform\FileCacheServiceAgent\unins000.exe"
if(test-path $Uninstaller){
    $process = Start-Process $Uninstaller -ArgumentList "/removequiet" -wait -PassThru
    try{
        $Command = get-command Translate-ExitCode -erroraction stop
        Translate-ExitCode -Process $Process -AutoOutput
    }
    catch{
        write-output "Uninstall process exited with code: $($Process.exitcode)"
    }
}else{
    Write-Warning "Uninstaller for N-Able FileCacheServiceAgent not found"
}
