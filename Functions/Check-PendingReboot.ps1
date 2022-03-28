function Check-PendingReboot
{
	<#
	.DESCRIPTION: Checks various registry keys to determine if there is a pending reboot
	.NOTES: 
			-Includes a lot of checks that likely aren't needed but included regardless
			-By default pending file rename operations are excludes as they typically are true
	#>
	param
	(
		[parameter(Mandatory = $false)]
		[bool]$ExcludePendingFileRenames = $true
	)
	
	#region Functions
	function Test-IsGuid
	{
		[OutputType([bool])]
		param
		(
			[Parameter(Mandatory = $true)]
			[string]$StringGuid
		)
		
		$ObjectGuid = [System.Guid]::empty
		return [System.Guid]::TryParse($StringGuid, [System.Management.Automation.PSReference]$ObjectGuid) # Returns True if successfully parsed
	}
	#endregion
	
	#region Process pending reboot checks
	# Pending filename renames
	try
	{
		$RegKey = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Ignore | select -expand PendingFileRenameOperations
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$PendingFileRenames = $true
		}
		else
		{
			$PendingFileRenames = $false
		}
	}
	Catch
	{
		$PendingFileRenames = $false
	}
	
	# Pending Updates
	try
	{
		$RegKey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Updates' -name "UpdateExeVolatile" -ErrorAction stop | Select -expand "UpdateExeVolatile"
		
		if ($RegKey -ne "0")
		{
			$PendingUpdates = $True
		}
	}
	Catch
	{
		# Error thrown so value doesn't exist.
		$PendingUpdates = $false
	}
	
	# Pending file renames (2)
	try
	{
		$RegKey = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -name "PendingFileRenameOperations2" -ErrorAction stop | Select -expand "PendingFileRenameOperations2"
		$boolCheck = [bool]$RegKey
		if ($RegKey -ne "0")
		{
			$PendingFileRenames2 = $True
		}
		else
		{
			$PendingFileRenames2 = $False
		}
	}
	Catch
	{
		# Error thrown so value doesn't exist.
		$PendingFileRenames2 = $false
	}
	
	# Win Updates reboot required flag
	if (Test-path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")
	{
		$PendingWinUpdate = $true
	}
	else
	{
		$PendingWinUpdate = $false
	}
	
	# Win Updates (2)
	try
	{
		$RegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending" -ErrorAction stop
		$VarProperties = $RegKey | Get-Member -ErrorAction Stop | Where { $_.membertype -eq "NoteProperty" }
		$FilteredProperties = $VarProperties | Where { $_.name -ine "PSDrive" -and $_.name -ine "PSParentPath" -and $_.name -ine "PSPath" -and $_.name -ine "PSProvider" -and $_.name -ine "PSChildName" }
		# loop through properties on variable and check if any values are a GUID
		foreach ($property in $FilteredProperties)
		{
			$PropertyName = $property | select -expand Name
			$GUIDCheck = Test-IsGuid -StringGuid $($RegKey.$($PropertyName))
			if ($GUIDCheck)
			{
				$PendingWinUpdate2 = $true
			}
		}
	}
	catch
	{
		$PendingWinUpdate2 = $false
	}
	
	# Win Updates (3)
	if (Test-path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting")
	{
		$PendingWinUpdate3 = $True
	}
	else
	{
		$PendingWinUpdate3 = $False
	}
	
	# DVD Reboot Signal
	try
	{
		$RegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "DVDRebootSignal" -ErrorAction Stop | select -expand DVDRebootSignal
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$DVDRebootSignal = $True
		}
		else
		{
			$DVDRebootSignal = $False
		}
	}
	Catch
	{
		$DVDRebootSignal = $False
	}
	
	# Component servicing pending reboot
	if (Test-path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")
	{
		$ComponentServicing = $true
	}
	else
	{
		$ComponentServicing = $false
	}
	
	# Component servicing pending reboot (2)
	if (Test-path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress")
	{
		$ComponentServicing2 = $true
	}
	else
	{
		$ComponentServicing2 = $false
	}
	
	# Component servicing pending packages
	if (Test-path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending")
	{
		$PendingPackages = $true
	}
	else
	{
		$PendingPackages = $false
	}
	
	# server mgr reboot attempts
	if (Test-path "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts")
	{
		$SvrMgrReboot = $true
	}
	else
	{
		$SvrMgrReboot = $false
	}
	
	# Pending Domain Join
	try
	{
		$regkey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Name "JoinDomain" -ErrorAction Stop | Select -expand JoinDomain
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$PendingDomainJoin = $True
		}
		else
		{
			$PendingDomainJoin = $false
		}
	}
	catch
	{
		$PendingDomainJoin = $false
	}
	
	# Netlogon AvoidSpnSet
	try
	{
		$regkey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Name "AvoidSpnSet" -ErrorAction Stop | Select -expand AvoidSpnSet
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$AvoidSpnSet = $True
		}
		else
		{
			$AvoidSpnSet = $false
		}
	}
	catch
	{
		$AvoidSpnSet = $false
	}
	
	# Pending computer name change
	try
	{
		$CurrentPCname = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -Name "ComputerName" -ErrorAction stop | select -expand ComputerName
		$PendingPCName = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name "ComputerName" -ErrorAction Stop | select -expand ComputerName
		
		if ($PendingPCName -ine $CurrentPCname)
		{
			$PCNameChange = $True
		}
		else
		{
			$PCNameChange = $false
		}
	}
	catch
	{
		$PCNameChange = $false
	}
	
	# consider adding SCCM reboot checks here. Maybe add automate reboot flags if any are unique
	#endregion
	
	#region Return information
	
	if ($ExcludePendingFileRenames)
	{
		$PendingReboot = $PendingUpdates -or `
		$PendingWinUpdate -or `
		$PendingWinUpdate2 -or `
		$PendingWinUpdate3 -or `
		$DVDRebootSignal -or `
		$ComponentServicing -or `
		$ComponentServicing2 -or `
		$PendingPackages -or `
		$SvrMgrReboot -or `
		$PendingDomainJoin -or `
		$AvoidSpnSet -or `
		$PCNameChange -or `
		$PendingDomainJoin
		
		[PSCustomObject]@{
			ComputerName				    = $ENV:ComputerName
			ComponentBasedServicing		    = $ComponentServicing
			ComponentBasedServicing2	    = $ComponentServicing2
			PendingComputerRenameDomainJoin = $PendingDomainJoin
			PendingWindowsUpdate		    = $PendingWinUpdate
			PendingWindowsUpdate2		    = $PendingWinUpdate2
			PendingWindowsUpdate3		    = $PendingWinUpdate3
			DVDRebootSignal				    = $DVDRebootSignal
			PendingPackages				    = $PendingPackages
			ServerManagerReboots		    = $SvrMgrReboot
			PendingDomainJoin			    = $PendingDomainJoin
			AvoidSpnSet					    = $AvoidSpnSet
			PendingNameChange			    = $PCNameChange
			PendingReboot				    = $PendingReboot
		}
	}
	else
	{
		$PendingReboot = $PendingFileRenames -or `
		$PendingUpdates -or `
		$PendingFileRenames2 -or `
		$PendingWinUpdate -or `
		$PendingWinUpdate2 -or `
		$PendingWinUpdate3 -or `
		$DVDRebootSignal -or `
		$ComponentServicing -or `
		$ComponentServicing2 -or `
		$PendingPackages -or `
		$SvrMgrReboot -or `
		$PendingDomainJoin -or `
		$AvoidSpnSet -or `
		$PCNameChange -or `
		$PendingDomainJoin
		
		[PSCustomObject]@{
			ComputerName				    = $ENV:ComputerName
			ComponentBasedServicing		    = $ComponentServicing
			ComponentBasedServicing2	    = $ComponentServicing2
			PendingComputerRenameDomainJoin = $PendingDomainJoin
			PendingFileRenameOperations	    = $PendingFileRenames
			PendingFileRenameOperations2    = $PendingFileRenames2
			PendingWindowsUpdate		    = $PendingWinUpdate
			PendingWindowsUpdate2		    = $PendingWinUpdate2
			PendingWindowsUpdate3		    = $PendingWinUpdate3
			DVDRebootSignal				    = $DVDRebootSignal
			PendingPackages				    = $PendingPackages
			ServerManagerReboots		    = $SvrMgrReboot
			PendingDomainJoin			    = $PendingDomainJoin
			AvoidSpnSet					    = $AvoidSpnSet
			PendingNameChange			    = $PCNameChange
			PendingReboot				    = $PendingReboot
		}
	}
	#endregion
}