param(
    [parameter(Mandatory)]
    [string[]]$MSINames,
    [parameter()]
    [string[]]$processNames
)
try {
    [Net.ServicePointManager]::SecurityProtocol = 15360
}
catch {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}
try {
    $Command = Get-command Remove-MSIProduct -ErrorAction Stop
}
catch {
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/refs/heads/main/Functions/Remove-MSIProduct.ps1') | iex
}
try {
    $Command = Get-command Get-MSIProducts -ErrorAction Stop
}
catch {
    (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-MSIProducts.ps1') | iex
}

$count = 0
$uninstallData = foreach ($msi in $MSInames) {
    if (![bool]$ProcessNames[0]) {
        $processName = $msi
    }
    else {
        $ProcessName = $ProcessNames[0]
    }
    [pscustomobject]@{
        msiName     = $msi
        processName = $processName
    }
    $count++
}

foreach ($Msi in $uninstallData) {
    $(get-process) | where { $_.name -like $msi.processName } | stop-process -ErrorAction SilentlyContinue
  
    $MSIS = Get-MSIProducts
    $MSIObject = $MSIS | where { $_.name -ilike $MSI.msiName }
    if ([bool]$MSIObject) {
        foreach ($Object in $MSIObject) {
            Remove-MSIProduct -MSIObject $Object
        }
    }
}
Exit
