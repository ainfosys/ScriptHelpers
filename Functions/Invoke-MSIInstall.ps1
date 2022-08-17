Function Invoke-MSIInstall{
    param(
        [parameter(Mandatory = $True)]
        [String]$URL
    )

    $InstallerFile = "C:\Windows\temp\installer.msi"

    try{
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -uri $url -outfile $InstallerFile
    }
    Catch{
        # IE first run workaround
        $keyPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main'
        if (!(Test-Path $keyPath)) { New-Item $keyPath -Force | Out-Null }
        Set-ItemProperty -Path $keyPath -Name "DisableFirstRunCustomize" -Value 1

        Invoke-WebRequest -uri $url -outfile $InstallerFile -UseBasicParsing
    }

    if(test-path $InstallerFile){
        $Process = start-process msiexec -ArgumentList "/i $installerfile /qn /norestart" -wait -PassThru -ErrorAction stop
        $process.exitcode
    }
}