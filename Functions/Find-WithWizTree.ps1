function Find-WithWizTree {
# written by Immybot
    param(
      [string]$SearchString, 
      [switch]$IncludeFileDetails
    )
    $Filter = $SearchString
    if($IncludeFileDetails -eq $true)
    {
        $IncludeFileDetails = $true
    }

    if ($env:PROCESSOR_ARCHITECTURE -eq "amd64") 
    { 
        $FileName = "WizTree64.exe"
        $FileHash = "C7A03CF2F6FB9E94E8D406FB79A9CE97"
    }
    else 
    {
        $FileName = "WizTree.exe"
        $FileHash = "8237785900983D3A6C7FED06A9968FE6"
    }
    $SkipDownload = $false
    $WizTreePath = "$($env:windir)\temp\$FileName"
    if(Test-path $WizTreePath)
    {
        $ActualHash = Get-FileHash -alg MD5 $WizTreePath | select -expand Hash
        if($ActualHash -like $FileHash)
        {
            $SkipDownload = $true
        }
    }
    if(!$SkipDownload)
    {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
        $ToolUri = "https://immybot.blob.core.windows.net/software/Tools/$FileName"
        Write-Host "Downloading: $ToolUri..." -NoNewLine
        Start-BitsTransfer $ToolUri $WizTreePath
        Write-Host "Done."
    }
    if(Test-Path $WizTreePath)
    {
        $FoundFilesCsvPath = Join-Path "$($env:windir)\temp" "msifiles.csv"    
        $args = @"
    "$($env:SystemDrive)" /filter="$Filter" /admin=1 /export="$FoundFilesCsvPath"
"@
        Start-Process -Wait -NoNewWindow $WizTreePath -ArgumentList $args

        $FoundFiles = Get-Content $FoundFilesCsvPath | select -skip 1 | ConvertFrom-Csv
        Remove-Item $FoundFilesCsvPath -force | Out-Null
        $FoundFilesClean = $FoundFiles | %{ 
            $RetObj = New-Object psobject -Property ([ordered]@{FileName=(Split-Path $_."File Name" -Leaf);FullPath=$_."File Name";SizeMB=[double]('{0:N2}' -f ($_.Size/1MB))}) 
            if($IncludeFileDetails)
            { 
                $VersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($RetObj.FullPath)
                if($null -ne $VersionInfo)
                {
                    $RetObj | Add-Member -NotePropertyName "FileVersion" -NotePropertyValue $VersionInfo.FileVersion
                    $RetObj | Add-Member -NotePropertyName "ProductName" -NotePropertyValue $VersionInfo.ProductName
                    $RetObj | Add-Member -NotePropertyName "ProductVersion" -NotePropertyValue $VersionInfo.ProductVersion
                    $ZoneInformation = Get-Content -path $RetObj.FullPath -Stream Zone.Identifier -ErrorAction SilentlyContinue
                    if($null -ne $ZoneInformation)
                    {
                        foreach($Line in $ZoneInformation)
                        {
                            $SplitIndex = $Line.IndexOf("=")
                            if($SplitIndex -gt 0)
                            {
                                $Name = $Line.Substring(0,$SplitIndex)
                                $Value = $Line.Substring($SplitIndex + 1)
                                $RetObj | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
                            }
                        }
                    }
                }
            }
            $RetObj
        }
        $FoundFilesClean = $FoundFiles | %{ new-object psobject -Property ([ordered]@{FileName=(Split-Path $_."File Name" -Leaf);FullPath=$_."File Name";SizeMB=[double]('{0:N2}' -f ($_.Size/1MB))}) }    
        $FoundFilesClean 
    }
}
