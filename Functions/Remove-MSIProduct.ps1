function Remove-MSIProduct {
    param(
        [parameter(ParameterSetName="MSIObj", Mandatory)]
        $MSIObject,
        [parameter(ParameterSetName="MSIName", Mandatory)]
        $MSIName
    )

    if([bool]$MSIName){
        try{
            $Command = get-command Get-MSIProducts -ErrorAction Stop
        }catch{
            (new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Functions/Get-MSIProducts.ps1') | iex
        }
        $MSIS = Get-MSIProducts
        $MSI = $MSIS | where {$_.name -ilike $MSIName}
        if([bool]$MSI){
            $Process = start-process msiexec -ArgumentList "/X $($MSI.ProductCode) /qn /norestart" -Wait -PassThru
            try{
                $Command = get-command Translate-ExitCode -ErrorAction stop
                Translate-ExitCode -Process $Process -AutoOutput
                if($process.exitcode -eq "1618"){
                    write-output "Killing msiexec processes and trying again"
                    get-process msiexec | stop-process -force
                    Remove-MSIProduct -MSIName $MsiName
                }
            }catch{
                Write-Output "Uninstall process exited with code: $($Process.ExitCode)"
                if($process.exitcode -eq "1618"){
                    write-output "Killing msiexec processes and trying again"
                    get-process msiexec | stop-process -force
                    Remove-MSIProduct -MSIName $MsiName
                }
            }
        }else{
            Write-Warning "MSI with name `"$MSIName`" not found on system"
        }
    }

    if([Bool]$MSIObject){
        # expected properties must at least include productcode
        $Process = start-process msiexec -ArgumentList "/X $($MSIObject.ProductCode) /qn /norestart" -Wait -PassThru
        try{
            $Command = get-command Translate-ExitCode -ErrorAction stop
            Translate-ExitCode -Process $Process -AutoOutput
            if($process.exitcode -eq "1618"){
                write-output "Killing msiexec processes and trying again"
                get-process msiexec | stop-process -force
                Remove-MSIProduct -MSIObject $MsiObject
            }
        }catch{
            Write-Output "Uninstall process exited with code: $($Process.ExitCode)"
            if($process.exitcode -eq "1618"){
                write-output "Killing msiexec processes and trying again"
                get-process msiexec | stop-process -force
                Remove-MSIProduct -MSIObject $MsiObject
            }
        }
    }
}
