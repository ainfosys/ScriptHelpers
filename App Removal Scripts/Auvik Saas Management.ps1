# script provided by auvik, slightly modified
$programDirectory = "C:\Program Files\Saaslio"
$programLatestDirectory = "$($programDirectory)\win-latest"
$application = "$($programLatestDirectory)\Saaslio-x64.exe"

$runnableDirectory = "C:\Saaslio"

Stop-Process -Name "Saaslio-x64" -Force -ErrorAction SilentlyContinue

# Remove the current version if it exists
if (Test-Path $programLatestDirectory) {
    $process = Start-Process -FilePath $application -ArgumentList "--remove" -Wait -passthru
    Write-output "Auvik Saas Management remove process exited with exit code: $($process.exitcode)"
    $process = Start-Process -FilePath $application -ArgumentList "--clean" -Wait -passthru
    Write-output "Auvik Saas Management clean up process exited with exit code: $($process.exitcode)"
    $Running = get-process Saaslio-x64 -ErrorAction SilentlyContinue
    if([bool]$Running){
      # kill processes and try uninstall/clean again
      $Running | Stop-Process -Force -ErrorAction SilentlyContinue
      $process = Start-Process -FilePath $application -ArgumentList "--remove" -Wait -passthru
      Write-output "Auvik Saas Management remove process (run 2) exited with exit code: $($process.exitcode)"
      $process = Start-Process -FilePath $application -ArgumentList "--clean" -Wait -passthru
      Write-output "Auvik Saas Management clean up process (run 2) exited with exit code: $($process.exitcode)"
    }
    Remove-Item $programDirectory -Recurse -Force
}

if (Test-Path $runnableDirectory) {
    Remove-Item $runnableDirectory -Recurse -Force
}
exit
