Function InstallOrUpdateModule {
<#
.DESCRIPTION: Updates NuGet and PowershellGet if out of date and installs the provided module name if a module name is provided
.AUTHOR: Ryan
.NOTES:
    - This function was written to support the Powershell common parameter '-verbose'
    - If a module name is not provided only NuGet and PowershellGet will update if they are out of date
#>
    [cmdletbinding()]
    param
    (
	    [parameter(Mandatory = $false)]
        [String]
	    $ModuleName
    )
    # Variable used to check if the parameter was provided or not. $True means it contains something
    $ParamCheck = [bool]$ModuleName

    if($ParamCheck){
        Write-Verbose -Message "Provided module name is: $ModuleName"
    }
    else{
        Write-Verbose -Message "No module name is provided so only nuget and powershellget will be updated"
    }

    # Set TLS to 1.2 for this Powershell session. This will not work on Windows 7 or lower.
    Write-Verbose "Setting TLS protocol to 1.2 for this session. This may fail on older operating systems"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    try{
        # Make sure package providers are up to date
        Write-Verbose "Checking local versions of Nuget and PowershellGet against latest available"
        $LocalNugetVersion = Get-PackageProvider -Name nuget | select -expand Version
        $LocalPowershellGetVersion = Get-PackageProvider -name PowershellGet | select -expand Version
        $LatestNugetVersion = Find-PackageProvider -Name nuget -ErrorAction Stop | select -expand Version
        $LatestPowershellGetVersion = Find-PackageProvider -name PowershellGet -ErrorAction Stop | select -expand Version

        if($LocalNugetVersion -lt $LatestNugetVersion){
            
            Write-Verbose -Message "Attempting to update NuGet now"
            if($VerbosePreference -eq "Continue"){
                Install-PackageProvider -Name NuGet -Force -Confirm:$False -ErrorAction Stop -Verbose
            }
            else{
                Install-PackageProvider -Name NuGet -Force -Confirm:$False -ErrorAction Stop | Out-Null
            }
        }
    }
    Catch{
        Write-Output "Nuget installation or check failed, consider rebooting and trying again or manually updating nuget/packageprovider"
    }

    if($LocalPowershellGetVersion -lt $LatestPowershellGetVersion){
        Write-Verbose -Message "Attempting to update PowershellGet now"
        if($VerbosePreference -eq "Continue"){ 
            Install-Module -Name PowerShellGet -Force -Confirm:$False -Verbose
        }
        else{
            Install-Module -Name PowerShellGet -Force -Confirm:$False | Out-Null 
        }
    }

    if($ParamCheck){
            Write-Verbose -Message "Checking local system for desired module. Update if found out of date"
            if ($(Get-Module -ListAvailable | select -expand Name) -inotcontains $ModuleName)
            {
                Write-Verbose -Message "Module not found on local system, installing it now"
                # if the module isn't found to be installed it will install it here
                if($VerbosePreference -eq "Continue"){
	                Install-Module -Name $ModuleName -Force -Confirm:$False -Verbose
                }
                else{
                    Install-Module -Name $ModuleName -Force -Confirm:$False | Out-Null
                }
            }
            elseif($(Get-Module -ListAvailable | Where {$_.name -eq $ModuleName} | select -expand Version) -lt $(Find-Module -name $ModuleName | select -expand Version)){
                Write-Verbose -Message "Module found on local system but out of date, updating it now"
                if($VerbosePreference -eq "Continue"){
                    # The local version is out of date, update it here
                    Update-module -Name $ModuleName -Force -Confirm:$False -Verbose
                }
                else{
                    Update-module -Name $ModuleName -Force -Confirm:$False | Out-Null
                }
            }
            elseif($(Get-Module -ListAvailable | Where {$_.name -eq $ModuleName} | select -expand Version) -eq $(Find-Module -name $ModuleName | select -expand Version)){
                Write-Output "Module already installed and on latest version"
                Write-Output "Local version: $(Get-Module -ListAvailable | Where {$_.name -eq $ModuleName} | select -expand Version)"
                Write-Output "Online version: $(Find-Module -name $ModuleName | select -expand Version)"
            }
            Write-Verbose -Message "Importing module now"
            if($VerbosePreference -eq "Continue"){
                Import-Module -name $ModuleName -Verbose
            }
            else{
                Import-Module -Name $ModuleName | Out-Null
            }
    }
}