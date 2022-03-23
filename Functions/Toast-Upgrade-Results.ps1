<#
.DESCRIPTION: Provide a toast notification which shows the results of the feature upgrade
.AUTHOR: Ryan
.NOTES: 
	- Requires the BurntToast ps module
#>

#region Functions
Function Translate-WindowsBuild
{
	<#
	.DESCRIPTION: Provides information on the Windows build based on the given parameter
	.AUTHOR: Ryan
	#>
	
	param
	(
		[parameter(Mandatory = $false, HelpMessage = 'Use the following to get the build number: $([System.Environment]::OSVersion.Version.Build)')]
		[int]$Build,
		[parameter(Mandatory = $false, HelpMessage = "The 'Friendly Name' for build numbers. EX: 20H2")]
		[string]$Version,
		[parameter(Mandatory = $false)]
		[Switch]$Win10Only = $false
	)
	
	$WininfoXMLpath = "C:\Windows\Temp\WinInfo.xml"
	Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Files/Windows10-11-VersionHistory.xml" -OutFile $WininfoXMLpath
	
	[xml]$WinInfoXML = Get-Content $WininfoXMLpath
	
	$boolCheck = [bool]$Build
	if (!($boolCheck))
	{
		$boolCheck = [bool]$Version
		if (!($boolCheck))
		{
			Write-Host "At least one parameter is required (build or version)"; Break
		}
		else
		{
			# just version provided
			$Info = $WinInfoXML.root.buildinfo | where { $_.version -eq $Version }
		}
	}
	else
	{
		$boolCheck = [bool]$Version
		if ($boolCheck)
		{
			# Build and version provided
			$Info = $WinInfoXML.root.buildinfo | where { $_.build -eq $Build }
			
			if ($Info.windows.info.version -ne $Version)
			{
				Write-Host "Both parameters are provided but the values do not match expected values."
				Write-Host "Provided build: $Build"
				Write-Host "Provided version: $Version"
				Write-Host "Expected version: $($Info.version)"; Break
			}
		}
		else
		{
			# just build provided
			$Info = $WinInfoXML.root.buildinfo | where { $_.build -eq $Build }
		}
	}
	
	if ($Win10Only)
	{
		# Exclude windows 11 info from the return info
		$Info = $Info | where { $_.Majorversion -ne "11" }
		
		if ([string]::IsNullOrWhiteSpace($($Info.build)))
		{
			Write-Output -InputObject "Only Windows 11 infomation found. Windows 11 information selected to be excluded so no information can be returned."; Break
		}
	}
	
	$WindowsInfo = @{
		Build = $Info.Build
		Version = $Info.version
		ReleaseDate = $Info.releaseDate
		Standard_EOL = $Info.GACEOL
		Enterprise_EOL = $Info.GACEnterpriseEOL
		LTSC_EOL = $Info.LTSCEOL
		MajorVersion = $Info.Majorversion
	}
	
	Return $($WindowsInfo | ConvertTo-Json | ConvertFrom-Json)
}
#endregion

#region Variables
$ToastID = "Upgrade Results"
$AppID = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\msinfo32.exe'
$FeatureUpgradeKey = "HKLM:\SOFTWARE\FeatureUpgrade"
$OSBuild = [System.Environment]::OSVersion.Version.Build
#endregion

#region Pre-Checks
if (Test-path $FeatureUpgradeKey)
{
	$FeatureUpdateInfo = @{
		Start = Get-ItemProperty -Path $FeatureUpgradeKey -Name "Start" | Select-Object -ExpandProperty "Start"
		End   = Get-ItemProperty -Path $FeatureUpgradeKey -Name "End" | Select-Object -ExpandProperty "End"
		Method = Get-ItemProperty -Path $FeatureUpgradeKey -Name "Method" | Select-Object -ExpandProperty "Method"
		LogLocation = Get-ItemProperty -Path $FeatureUpgradeKey -Name "LogLocation" | Select-Object -ExpandProperty "LogLocation"
		OSBeforeUpgrade = Get-ItemProperty -Path $FeatureUpgradeKey -Name "OSBeforeUpgrade" | Select-Object -ExpandProperty "OSBeforeUpgrade"
		Result = Get-ItemProperty -Path $FeatureUpgradeKey -Name "Result" | Select-Object -ExpandProperty "Result"
	}
}

if ($(Get-Module -ListAvailable).name -inotcontains "BurntToast")
{
	Write-Output -InputObject "Required module is not installed, installing it now"
	
	try
	{
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		Install-Module -Name BurntToast -Force -ErrorAction Stop
	}
	Catch
	{
		Write-Output -InputObject "Required module failed to install. Script will not continue"; Throw
	}
}

try
{
	Import-Module BurntToast -ErrorAction Stop	
}
Catch
{
	Write-Output -InputObject "Failed to import required module"
}
New-BTAppId -AppId $AppID
$AppLogo = New-BTImage -AlternateText AIS -Source "https://aisdownload.s3.amazonaws.com/Branding/Alliance-Logo-white4.ico" -AppLogoOverride
#endregion

#region Create Toast
# Setup the content of the toast notification
if ($FeatureUpdateInfo.Result -ieq "Success")
{
	$PreviousBuildInfo = Translate-WindowsBuild -Build $($FeatureUpdateInfo.OSBeforeUpgrade) -Win10Only
	$CurrentBuildInfo = Translate-WindowsBuild -Build $OSBuild -Win10Only
	$ToastMessageContent = @"
Update was successful
Previous OS Build: $($PreviousBuildInfo.Version)
Current OS Build: $($CurrentBuildInfo.Version)

"@
	
	$ToastTitle = New-BTText -Content "Upgrade Results"
	$ToastMessage = New-BTText -Content $ToastMessageContent
}
else
{
	$ToastTitle = New-BTText -Content "Upgrade Results"
	$ToastMessage = New-BTText -Content "Update Failed. The feature upgrade will need to run again."
}

$BTVisualBinding = New-BTBinding -Children $ToastTitle, $ToastMessage -AppLogoOverride $AppLogo
$BTVisual = New-BTVisual -BindingGeneric $BTVisualBinding
$BTContent = New-BTContent -Visual $BTVisual
Submit-BTNotification -Content $BTContent -AppId $AppID

Disable-ScheduledTask -TaskName "Result-Prompt" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Result-Prompt" -confirm:$false -ErrorAction SilentlyContinue
#endregion