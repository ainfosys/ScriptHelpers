try{
    $Command = Get-command Remove-MSIProduct -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/refs/heads/main/Functions/Remove-MSIProduct.ps1') | iex
}
try{
    $Command = Get-command Get-MSIProducts -ErrorAction Stop
}
catch{
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-MSIProducts.ps1') | iex
}
$MSIS = Get-MSIProducts
$ControlClients = $MSIs | Where-Object {$_.name -ilike "ScreenConnect Client*" -and $_.name -ine "ScreenConnect Client (4ae1a82dea15a46e)"}
foreach($SC in $ControlClients){
    Write-Output "Starting msi uninstall of `"$($SC.name)`" version `"$($SC.version)`""
    Remove-MSIProduct -MSIObject $SC
}
Exit
