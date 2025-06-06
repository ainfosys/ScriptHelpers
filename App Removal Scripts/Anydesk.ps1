# check for exe version(s)
if(Test-Path 'C:\Program Files (x86)\AnyDesk\AnyDesk.exe'){
    $installPath32 = 'C:\Program Files (x86)\AnyDesk\AnyDesk.exe'
    Write-Host "Anydesk found installed at $installPath32 Uninstalling now..."
    Start-Process $installPath32 -ArgumentList "--silent --remove"
}
if(Test-Path 'C:\Program Files\AnyDesk\AnyDesk.exe'){
    $installPath64 = 'C:\Program Files\AnyDesk\AnyDesk.exe'
    Write-Host "Anydesk found installed at $installPath64 Uninstalling now..."
    Start-Process $installPath64 -ArgumentList "--silent --remove"
}

# check for msi installed version
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
$MSIObject = $MSIS | where {$_.name -ilike "AnyDesk*"}
if([bool]$MSIObject){
    Remove-MSIProduct -MSIObject $MSIObject
}
