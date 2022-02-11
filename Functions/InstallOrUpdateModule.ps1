Function InstallOrUpdateModule {
    param
    (
	    [parameter(Mandatory = $true)]
        [String]
	    $ModuleName
    )
    # this function is a simple way of making sure the desired module is installed and up to date
    # Enter the module name as found in the ps gallery as the parameter. Ex: RunAsUser (not case sensitive)
    # TODO: Provide the option to allow verbose output via parameter

    # Set TLS to 1.2 for this Powershell session. This will not work on Windows 7 or lower.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Make sure package providers are up to date
    $LocalNugetVersion = Get-PackageProvider -Name nuget | select -expand Version
    $LocalPowershellGetVersion = Get-PackageProvider -name PowershellGet | select -expand Version
    $LatestNugetVersion = Find-PackageProvider -Name nuget | select -expand Version
    $LatestPowershellGetVersion = Find-PackageProvider -name PowershellGet | select -expand Version

    if($LocalNugetVersion -lt $LatestNugetVersion){
        Install-PackageProvider -Name NuGet -Force -Confirm:$False | Out-Null
    }

    if($LocalPowershellGetVersion -lt $LatestPowershellGetVersion){
        Install-Module -Name PowerShellGet -Force -Confirm:$False | Out-Null
    }

    if ($(Get-Module -ListAvailable | select -expand Name) -inotcontains $ModuleName)
    {
        # if the module isn't found to be installed it will install it here
	    Install-Module -Name $ModuleName -Force -Confirm:$False | Out-Null
    }
    elseif($(Get-Module -ListAvailable | Where {$_.name -eq $ModuleName} | select -expand Version) -lt $(Find-Module -name $ModuleName | select -expand Version)){
    
        # The local version is out of date, update it here
        Update-module -Name $ModuleName -Force -Confirm:$False | Out-Null
    }
    Import-Module -name $ModuleName
}