#Bitdefender Endpoint Security Tools
$URL = "https://download.bitdefender.com/SMB/Hydra/release/bst_win/uninstallTool/BEST_uninstallTool.exe"
$UninstallTool = "$ENV:SystemDrive\Windows\temp\$(split-path $URL -Leaf)"
Invoke-WebRequest -UseBasicParsing -Uri $URL -OutFile $UninstallTool -ErrorAction Stop
$process = start-process $UninstallTool -ArgumentList "/bruteForce /destructive /noWait" -Wait -PassThru
Write-Output "Bitdefender EST removal tool exited with code: $($Process.ExitCode)"
Exit
