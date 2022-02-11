Function Translate-WindowsBuild
{
	<#
	.DESCRIPTION: Provides information on the Windows build based on the given parameter
	.AUTHOR: Ryan
	#>
	
	param
	(
		[parameter(Mandatory = $false)]
		$Build,
		[parameter(Mandatory = $false)]
		$Version
	)
	
	if ([string]::IsNullOrWhiteSpace($Build) -and [string]::IsNullOrWhiteSpace($Version))
	{
		Write-Host "At least one parameter is required (build or version)"; Break
	}
	
	$WininfoXMLpath = "C:\Windows\Temp\WinInfo.xml"
	Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Files/Windows10-11-VersionHistory.xml" -OutFile $WininfoXMLpath
	
	[xml]$WinInfoXML = Get-Content $WininfoXMLpath
	
	if (![string]::IsNullOrWhiteSpace($Build) -and ![string]::IsNullOrWhiteSpace($Version))
	{
		$Info = $WinInfoXML | where { $_.Windows.info.build -eq $Build }
		
		if ($Info.windows.info.version -ne $Version)
		{
			Write-Host "Both parameters are provided but the values do not match expected values."
			Write-Host "Provided build: $Build"
			Write-Host "Provided version: $Version"
			Write-Host "Expected version: $($Info.windows.info.version)"; Break
		}
	}
	elseif (![string]::IsNullOrWhiteSpace($Build) -and [string]::IsNullOrWhiteSpace($Version))
	{
		$Info = $WinInfoXML | where { $_.Windows.info.build -eq $Build }
	}
	elseif ([string]::IsNullOrWhiteSpace($Build) -and ![string]::IsNullOrWhiteSpace($Version))
	{
		$Info = $WinInfoXML | where { $_.Windows.info.version -eq $Version }
	}
	
	$WindowsInfo = @{
		Build = $Info.windows.info.Build
		Version = $Info.windows.info.version
		ReleaseDate = $Info.windows.info.release_Date
		Standard_EOL = $Info.windows.info.GAC_EOL
		Enterprise_EOL = $Info.windows.info.GAC_Enterprise_EOL
		LTSC_EOL = $Info.windows.info.LTSC_EOL
		MajorVersion = $Info.windows.info.Major_version
	}
	
	Return $($WindowsInfo| ConvertTo-Json | ConvertFrom-Json)
}