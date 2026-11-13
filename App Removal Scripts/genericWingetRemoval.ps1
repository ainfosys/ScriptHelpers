param(
    [parameter(Mandatory)]
    $packageName
)
function Get-PwshFullPath {
    try {
        $PwshInfo = get-AppxPackage -Name "Microsoft.PowerShell" -allusers -erroraction stop
    }
    catch {
        Write-Verbose "powershell core not found"
    }
    if (test-path "$($PwshInfo.InstallLocation)\pwsh.exe") {
        return "$($PwshInfo.InstallLocation)\pwsh.exe"
    }
    else {
        Write-Verbose "powershell core not found"
    }
}
Function Get-LatestPowershell {
    $RunningAs = whoami
    $output = get-command pwsh -erroraction ignore
    $latestRelease = $(Invoke-RestMethod "https://api.github.com/repos/Powershell/Powershell/releases") | where-object { $_.prerelease -ne $true } | select-object -first 1
    $latestversion = $latestRelease.tag_name -replace "v"
    try {
        $CurrentVersion = Get-AppxPackage -Name "Microsoft.PowerShell" -allusers -erroraction stop | select -expand version
    }
    catch {
        $CurrentVersion = $null
    }
    [system.version]$latestSystemVersion = $latestversion
    [system.version]$currentSystemVersion = $CurrentVersion
    if ($(![bool]$output -and $RunningAs -ne 'nt authority\system') -or $($latestSystemVersion.Major -ne $currentSystemVersion.Major -or $latestSystemVersion.Minor -ne $currentSystemVersion.Minor -or $latestSystemVersion.Build -ne $currentSystemVersion.Build)) {
        # remove msi version of pwsh if found
        $Msis = Get-MSIProducts
        $pwshMsi = $Msis | where { $_.name -ilike "PowerShell 7-x*" }
        if ([bool]$pwshMsi) {
            $process = start-process msiexec -ArgumentList "/x $($pwshMsi.ProductCode) /qn /norestart" -wait -PassThru
            if ($Process.ExitCode -ne 0) {
                Write-Warning "⚠️ Uninstall of MSI version of pwsh exited with non zero exit code: $($process.ExitCode)"
            }
        }
        # remove all other msix/appx versions
        $pwshAppx = Get-AppxPackage -Name "Microsoft.PowerShell" -allusers -erroraction stop
        foreach ($appx in $pwshAppx) {
            $appx | Remove-AppxPackage -AllUsers
        }
		
        # download and install the latest pwsh version from github
        $dlURL = $latestRelease.assets | where-object { $_.name -ilike "*msixbundle" -and $_.name -inotlike "*-LTS-*" } | select-object -expand 'browser_download_url'
        $installer = "$ENV:SystemDrive\Windows\temp\$(split-path $dlURL -leaf)"
		
        $OUT = Invoke-FileDownload -source $dlURL -destination $installer
		
        if (test-path $installer) {
            $results = add-AppxProvisionedPackage -Online -PackagePath $installer -SkipLicense
        }
        else {
            Write-Warning "Failed to download powershell core which is required for this script. Exiting script."
            throw
        }
    }
}
function Get-WingetSoftware {
    $pwshPath = Get-PwshFullPath
    if (![bool]) {
        Get-LatestPowershell
        $pwshPath = Get-PwshFullPath
    }
    if ([bool]$pwshPath) {
        $Scriptblock = {
            function Module-ShouldBe {
                param (
                    [parameter(Mandatory)]
                    $ModuleName
                )
			
                $ProgressPreference = 'SilentlyContinue'
                $Online = Find-Module -Name $ModuleName
                $Installed = Get-module -Name $ModuleName -ListAvailable
                if ([bool]$Installed) {
                    if ($Installed.version -ne [System.Version]$Online.version) {
                        Remove-Module -Name $ModuleName -ErrorAction Ignore
                        Uninstall-Module -Name $ModuleName -AllVersions -Force
                        Install-module -Name $ModuleName -Force -allusers
                    }
                }
                else {
                    Install-module -Name $ModuleName -Force
                }
            }
            Module-ShouldBe -ModuleName "microsoft.winget.client"
            Import-module Microsoft.Winget.Client
            Get-WingetPackage
        }
        . $pwshPath -mta -command $Scriptblock
    }else{
        Write-Warning "Failed to install/find powershell core on system. Unable to run detection for some software"
    }
}

$packages = Get-WingetSoftware
$targetPackage = $packages | where {$_.name -like $packageName}
if([bool]$targetPackage){
    $ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    $FullWingetPath = Join-Path $($ResolveWingetPath[-1].Path) "winget.exe"
    start-process $FullWingetPath -ArgumentList "uninstall --id `"$($targetPackage.Id)`" -h" -Wait
    $packages = Get-WingetSoftware
    $targetPackage = $packages | where {$_.name -like $packageName}
    if([bool]$targetPackage){
        Write-Warning "Package $packageName still shows installed after attempting uninstall via winget"
    }else{
        Write-output "Package $packageName successfully removed via winget"
    }
}
