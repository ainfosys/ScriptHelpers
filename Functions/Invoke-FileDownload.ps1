function Invoke-FileDownload {
    param(
        [parameter(Mandatory)]
        $source,
        [parameter(Mandatory)]
        $destination
    )

    # set tls policy to tls12 and tls13
    [Net.ServicePointManager]::SecurityProtocol = 15360

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
    try{
        Write-Verbose "Invoke-FileDownload: Attempting file transfer using BITS"
        $bitsResult = Start-BitsTransfer -TransferType Download -Destination $destination -Source $source -ErrorAction stop
    }
    catch{
        try{
            Write-Verbose "Invoke-FileDownload: BITS transfer failed, attempting file transfer using IWR"
            $IWRResult = Invoke-WebRequest -UseBasicParsing -Uri $source -OutFile $destination -ErrorAction Stop
        }
        catch{
            try{
                Write-Verbose "Invoke-FileDownload: IWR transfer failed, attempting file transfer using cURL"
                Start-Process curl -ArgumentList "-sLo $destination $source" -wait -ErrorAction stop
                # double check if the file was successfully downloaded
                if(test-path $destination){
                    Write-Verbose "Invoke-FileDownload: cURL file transfer appears successful"
                }else{
                    Write-Verbose "Invoke-FileDownload: cURL file transfer appears to have failed"
                    throw
                }
            }
            catch{
                Write-Verbose "cURL transfer failed, attempting webclient object file transfer"
                (New-Object System.Net.WebClient).DownloadFile($source, $destination)
                # double check if the file was successfully downloaded
                if(test-path $destination){
                    throw "Invoke-FileDownload: All download methods have failed"
                }
            }
        }
    }
}
