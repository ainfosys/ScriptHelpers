function Invoke-FileDownload {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, HelpMessage = "URL or File share path")]
        $source,
        [parameter(Mandatory, HelpMessage = "Full path to file destination including file name")]
        $destination,
        [parameter(HelpMessage = "Determines if progress bars are shown for Invoke-Webrequest and Start-BitsTransfer")]
        #https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1#progresspreference
        [validateset("SilentlyContinue","Continue","Stop","Ignore")]
        $ProgressPreference = 'SilentlyContinue' # SilentlyContinue will speed up download speeds
    )

    try{
        # set tls policy to tls12 and tls13
        [Net.ServicePointManager]::SecurityProtocol = 15360
    }
    Catch{
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    }

    # validate the parent directory of the destination
    $parentpath = Split-path $destination -parent
    if(!(test-path $parentpath)){
        throw "Invoke-FileDownload: Parent path of provided destination does not exist"
    }

    # validate the provided destination file name
    $IndexOfInvalidChar = $destination.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars())
    if($IndexOfInvalidChar -eq -1){
        throw "Invoke-FileDownload: Invalid file name provided with destination path"
    }

    # attempt download
    try{
        # BITS
        Write-Verbose "Invoke-FileDownload: Attempting file transfer using BITS"
        $stopwatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'
        $stopwatch.Start()
        Start-BitsTransfer -TransferType Download -Destination $destination -Source $source -ErrorAction stop
        $stopwatch.Stop()
        $return = @{
            "Download_Function" = "BITS"
            "Total_Time" = $stopwatch.Elapsed
            "Output" = $destination
        }
        return $return
    }
    catch{
        try{
            # IWR
            Write-Verbose "Invoke-FileDownload: BITS transfer failed, attempting file transfer using Invoke-WebRequest"
            $stopwatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'
            $stopwatch.Start()
            $IWRResult = Invoke-WebRequest -UseBasicParsing -Uri $source -OutFile $destination -ErrorAction Stop
            $stopwatch.Stop()
            $return = @{
                "Download_Function" = "Invoke-WebRequest"
                "Total_Time" = $stopwatch.Elapsed
                "Output" = $destination
            }
            return $return
        }
        catch{
            try{
                # cURL
                Write-Verbose "Invoke-FileDownload: Invoke-WebRequest transfer failed, attempting file transfer using cURL"
                $stopwatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'
                $stopwatch.Start()
                $process = Start-Process curl -ArgumentList "-sLo $destination $source" -wait -ErrorAction stop
                $stopwatch.Stop()
                # double check if the file was successfully downloaded
                if(!(test-path $destination)){
                    Throw "Invoke-FileDownload: cURL file transfer appears to have failed"
                }
                $return = @{
                    "Download_Function" = "cURL"
                    "Total_Time" = $stopwatch.Elapsed
                    "Output" = $destination
                }
                return $return
            }
            catch{
                # Webclient object
                Write-Verbose "Invoke-FileDownload: cURL transfer failed, attempting webclient object file transfer"
                $stopwatch = New-Object -TypeName 'System.Diagnostics.Stopwatch'
                $stopwatch.Start()
                (New-Object System.Net.WebClient).DownloadFile($source, $destination)
                $stopwatch.Stop()
                # double check if the file was successfully downloaded
                if(!(test-path $destination)){
                    throw "Invoke-FileDownload: All download methods have failed"
                }
                $return = @{
                    "Download_Function" = "WebClient Object"
                    "Total_Time" = $stopwatch.Elapsed
                    "Output" = $destination
                }
                return $return
            }
        }
    }
}
