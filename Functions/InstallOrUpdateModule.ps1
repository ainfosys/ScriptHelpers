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

    # Disable confirmation for installing modules and packages
    # more or less this is not needed when used with -Force
    Set-Variable -Name 'ConfirmPreference' -Value 'None' -Scope Script

    if($ParamCheck){
        Write-Verbose -Message "Provided module name is: $ModuleName"
    }
    else{
        Write-Verbose -Message "No module name is provided so only nuget and powershellget will be updated"
    }

    # Set TLS to 1.2 for this Powershell session. This will not work on Windows 7 or lower.
    Write-Verbose "Setting TLS protocol to 1.2 for this session. This may fail on older operating systems"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Determine if PackageManagement needs to be updated
    try{
       $LocalPackageMgmtVersion = Get-Package -Name PackageManagement -ErrorAction Stop | Select-Object -ExpandProperty Version
       $LatestPackageMgmtVersion = Find-Package -Name PackageManagement | Select-Object -ExpandProperty Version

       if($LocalPackageMgmtVersion -lt $LatestPackageMgmtVersion){
            Write-Verbose -Message "PackageManagement Version is out of date, updating it now"
            if($VerbosePreference -eq "Continue"){
                Install-Package -Name PackageManagement -Force -ErrorAction Stop -Verbose
            }
            else{
                Install-Package -Name PackageManagement -Force -ErrorAction Stop | Out-Null
            }
        }
    }
    Catch{
        # Reaching this part most likely caused by PackageManagent not being installed
        Write-Verbose -Message "PackageManagement not installed, installing it now"
        if($VerbosePreference -eq "Continue"){
             Install-Package -Name PackageManagement -Force -ErrorAction Stop -Verbose
         }
         else{
             Install-Package -Name PackageManagement -Force -ErrorAction Stop | Out-Null
         }
        
    }

    try{
        # Make sure package providers are up to date
        Write-Verbose "Checking local versions of PackageManagement, Nuget and PowershellGet against latest available"
        
        $LocalNugetVersion = Get-PackageProvider -Name nuget | Select-Object -ExpandProperty Version
        $LocalPowershellGetVersion = Get-PackageProvider -name PowershellGet | Select-Object -ExpandProperty Version
        $LatestNugetVersion = Find-PackageProvider -Name nuget -ErrorAction Stop | Select-Object -ExpandProperty Version
        $LatestPowershellGetVersion = Find-PackageProvider -name PowershellGet -ErrorAction Stop | Select-Object -ExpandProperty Version


        if($LocalNugetVersion -lt $LatestNugetVersion){
            
            Write-Verbose -Message "NuGet version is out of date, updating it now"
            if($VerbosePreference -eq "Continue"){
                Install-PackageProvider -Name NuGet -Force -ErrorAction Stop -Verbose
            }
            else{
                Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
            }
        }
    }
    Catch{
        Write-Output "Nuget or PackageManagement installation or check failed, consider rebooting and trying again or manually updating nuget/packagemanagement"
    }

    if($LocalPowershellGetVersion -lt $LatestPowershellGetVersion){
        Write-Verbose -Message "Attempting to update PowershellGet now"
        if($VerbosePreference -eq "Continue"){ 
            Install-Module -Name PowerShellGet -Force -Verbose
        }
        else{
            Install-Module -Name PowerShellGet -Force | Out-Null 
        }
    }

    if($ParamCheck){
            Write-Verbose -Message "Checking local system for desired module. Update if found out of date"
            if ($(Get-Module -ListAvailable | Select-Object -ExpandProperty Name) -inotcontains $ModuleName)
            {
                Write-Verbose -Message "Module not found on local system, installing it now"
                # if the module isn't found to be installed it will install it here
                if($VerbosePreference -eq "Continue"){
	                Install-Module -Name $ModuleName -Force -Verbose
                }
                else{
                    Install-Module -Name $ModuleName -Force | Out-Null
                }
            }
            elseif($(Get-Module -ListAvailable | Where-Object {$_.name -eq $ModuleName} | Select-Object -ExpandProperty Version) -lt $(Find-Module -name $ModuleName | Select-Object -ExpandProperty Version)){
                Write-Verbose -Message "Module found on local system but out of date, updating it now"
                if($VerbosePreference -eq "Continue"){
                    # The local version is out of date, update it here
                    Update-module -Name $ModuleName -Force -Verbose
                }
                else{
                    Update-module -Name $ModuleName -Force | Out-Null
                }
            }
            elseif($(Get-Module -ListAvailable | Where-Object {$_.name -eq $ModuleName} | Select-Object -ExpandProperty Version) -eq $(Find-Module -name $ModuleName | Select-Object -ExpandProperty Version)){
                Write-Output "Module already installed and on latest version"
                Write-Output "Local version: $(Get-Module -ListAvailable | Where-Object {$_.name -eq $ModuleName} | Select-Object -ExpandProperty Version)"
                Write-Output "Online version: $(Find-Module -name $ModuleName | Select-Object -ExpandProperty Version)"
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