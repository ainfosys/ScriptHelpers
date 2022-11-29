Function Translate-WindowsBuild
{
	<#
	.DESCRIPTION: Provides information on the Windows build based on the given parameter
	.AUTHOR: Ryan
	#>
	
	param
	(
		[parameter(Mandatory = $false, HelpMessage = 'Use the following to get the build number: $([System.Environment]::OSVersion.Version.Build)')]
		[ValidateSet("10240", "10586", "14393", "15063", "16299", "17134", "17763", "18362", "18363", "19041", "19042", "19043", "19044", "22000", "22621")]
		[int]$Build,
		[parameter(Mandatory = $false, HelpMessage = "The 'Friendly Name' for build numbers. EX: 20H2")]
		[ValidateSet("1507", "1511", "1607", "1703", "1709", "1803", "1809", "1903", "1909", "2004", "20H2", "21H1", "21H2", "22H2")]
		[string]$Version,
		[parameter(Mandatory = $false, HelpMessage = "Display only Windows 10 info")]
		[Switch]$Win10Only = $false,
		[parameter(Mandatory = $false, HelpMessage = "Display only Windows 11 info")]
		[Switch]$Win11Only = $false
	)
	
	if ($Win10Only -and $Win11Only)
	{
		Write-Error -Message "Only one switch parameter can be used at one time, Win11Only or Win10Only."; Throw
	}
	
	$WininfoXMLpath = "C:\Windows\Temp\WinInfo.xml"
	[xml]$WinInfoXML = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Files/Windows10-11-VersionHistory.xml" | select -expand Content
	
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
			$Info = $WinInfoXML.root.buildinfo | where {$_.version -eq $Version}	
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
		
		# Note the following may fail on devices without the proper version of .net installed
		if ([string]::IsNullOrWhiteSpace($($Info.build)))
		{
			Write-Output -InputObject "Only Windows 11 infomation found. Windows 11 information selected to be excluded so no information can be returned."; Break
		}
	}
	
	if ($Win11Only)
	{
		# Exclude windows 11 info from the return info
		$Info = $Info | where { $_.Majorversion -eq "11" }
		
		# Note the following may fail on devices without the proper version of .net installed
		if ([string]::IsNullOrWhiteSpace($($Info.build)))
		{
			Write-Output -InputObject "Only Windows 10 infomation found. Windows 10 information selected to be excluded so no information can be returned."; Break
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
	
	Return $($WindowsInfo| ConvertTo-Json | ConvertFrom-Json)
}
