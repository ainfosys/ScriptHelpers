function Invoke-FileDownload {
    param(
        [parameter(Mandatory)]
        $source,
        [parameter(Mandatory)]
        $destination
    )
    $transferFail = $false

    # set tls policy to tls12 and tls13
    [Net.ServicePointManager]::SecurityProtocol = 15360

    # if the destination doesnt have a file name at the end, add it
    if($destination -inotlike "*.*"){
        $lastChar = $destination.replace($($destination.substring(0,$($destination.length - 1))), $null)
        if($lastChar -ne "\"){
            $destination = "$destination" + "\" + "$(split-path $source -Leaf)"
        }else{
            $destination = "$destination" + "$(split-path $source -Leaf)"
        }    
    }

    # attempt transfer using BITS if possible
    $BITSModule = get-module BITS -ListAvailable
    if([bool]$BITSModule){
        Write-Verbose "Attempting file transfer using BITS"
        try{
            $bitsResult = Start-BitsTransfer -TransferType Download -Destination $destination -Source $source -ErrorAction stop
            $transferFail = $false
        }
        catcH{
            Write-Verbose "BITS transfer failed"
            $transferFail = $true
        }
    }else{
        Write-Verbose "No BITS module found, cannot attempt BITS transfer."
    }

    if(!$transferFail){
        # attempt using invoke-webrequest
        try{
            Write-Verbose "Attempting file transfer using IWR"
            $IWRResult = Invoke-WebRequest -UseBasicParsing -Uri $source -OutFile $destination -ErrorAction Stop
            $transferFail = $false
        }catch{
            Write-Verbose "IWR transfer failed"
            $transferFail = $true
        }
    }

    if(!$transferFail){
        # attempt using cURL
        try{
            Write-Verbose "Attempting file transfer using cURL"
            $scriptblock = {curl -sLo $destination $source}
            $curlJob = Start-Job -name "curl download" -ScriptBlock $scriptblock
            $curlJob | Wait-Job
            $curlresult = $curlJob | Receive-Job
            $curlJob | Remove-Job

            if($curlresult  -ilike "*error*" -or $curlresult -ilike "*try 'curl --help' for more information*"){
                Write-Verbose "cURL file transfer appears to have failed"
                $transferFail = $true
            }else{
                # double check if the file was successfully downloaded
                if(test-path $destination){
                    Write-Verbose "cURL file transfer appears successful"
                    $transferFail = $false
                }else{
                    Write-Verbose "cURL file transfer appears to have failed"
                    $transferFail = $true
                }
            }
        }catch{
            Write-Verbose "cURL file transfer appears to have failed"
            $transferFail = $true
        }
    }

    if(!$transferFail){
        # attempt using old posh2/3 methods
        try{
            Write-Verbose "Attempting webclient object file transfer"
            $WCObjectResult = (New-Object System.Net.WebClient).DownloadFile($source, $destination)
            # double check if the file was successfully downloaded
            if(test-path $destination){
                Write-Verbose "WebClient object file transfer appears successful"
                $transferFail = $false
            }else{
                Write-Verbose "WebClient object file transfer appears to have failed"
                $transferFail = $true
            }
        }
        catch{
            Write-Verbose "WebClient object file transfer appears to have failed"
            $transferFail = $true
        }
    }

    $transferResults = @{
        'BITS Result' = $bitsResult
        'IWR Result' = $IWRResult
        'cURL Result' = $curlresult
        'WebClient Result' = $WCObjectResult
    }

    if(!$transferFail){
        Write-Warning "File transfer failed on four different download types"
        $transferResults
        throw
    }
}
