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
$MSIObject = $MSIS | where {$_.name -ieq "MSP Core Agent"}
if([bool]$MSIObject){
    foreach($obj in $MSIObject){
        Remove-MSIProduct -MSIObject $Obj
    }
}

$MSIObject = $MSIS | where {$_.name -ieq "Windows Agent"}
if([bool]$MSIObject){
    Remove-MSIProduct -MSIObject $MSIObject
}
Exit
