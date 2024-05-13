function Get-LockedFileProcess {
    param(
        $FileName
    )
    $URL = "https://www.nirsoft.net/utils/ofview-x64.zip"
    $Zip = "$($ENV:SystemDrive)\Windows\Temp\ofview-x64.zip"
    $Exe = "$($ENV:SystemDrive)\Windows\Temp\OpenedFilesView.exe"
    $ResultCsv = "$($ENV:SystemDrive)\Windows\Temp\results.csv"

    if(test-path $ResultCsv){
        Remove-item $ResultCsv -Force
    }

    # Force TLS 1.2 for this powershell session
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # download the required application
    Try{
        Invoke-WebRequest -UseBasicParsing -Uri $URL -OutFile $Zip -ErrorAction stop
    }
    catch{
        Write-Warning "Failed to download required files. Error message follows:"
        $Error[0]; Throw
    }

    $expand = Expand-Archive -Path $Zip -DestinationPath "$($ENV:SystemDrive)\Windows\Temp\" -Force

    Start-process $Exe -ArgumentList "/scomma $ResultCsv" -wait
    #Write-output "Information may get cut off, view full results here: $ResultCSV"
    $CSV = Import-Csv $ResultCsv -Header File,FilePath,ProcessHandle,CreatedTime,ModifiedTime,Attributes,FileSize,ReadAccess,WriteAccess,DeleteAccess,SharedRead,SharedWrite,SharedDelete,GrantedAccess,FilePosition,ProcessID,ProcessName,ProcessPath

    $result = $CSV | where {$_.file -ieq $FileName}
    if(![bool]$result){
        try{
            $result = $CSV | where {$_.file -ieq $($filename -replace "\..*")}
        }
        catch{

        }
    }
    return $result
}
