try{
    [Net.ServicePointManager]::SecurityProtocol = 15360
}
catch{
  # Fall back to tls 1.2 if error thrown
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}

# get latest vscodium
new-item -path 'c:\vscodium' -itemtype directory -force | out-null
$latest = $(irm "https://api.github.com/repos/VSCodium/vscodium/releases")[0].assets | where { $_.name -ilike "vscodium-reh-web-win32*.tar.gz" } | select -expand browser_download_url
write-host "~Downloading latest version of VSCodium web server"
curl -L $latest --output C:\vscodium\vscodium.tar.gz

# get latest powershell core
$latestPwsh = $($(IRM "https://api.github.com/repos/PowerShell/PowerShell/releases/latest")[0].assets | where { $_.name -ilike "*x64.msi" }).browser_download_url
Write-host "~Downloading latest Powershell core installer"
curl -L $latestPwsh -outfile "$ENV:Temp\pwsh.msi"
Write-host "~Installing Powershell Core"
start-process msiexec -argumentlist "/i `"$ENV:Temp\pwsh.msi`" /qn /norestart" -wait

# extract vscodium
Write-host "~Extracting VSCodium"
tar -xvf "C:\vscodium\vscodium.tar.gz" -C C:\vscodium
