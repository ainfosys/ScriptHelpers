function Check-PendingReboot
{
	<#
		.DESCRIPTION: Function to determine if a pending reboot is present
		.NOTES:
			- Minimum PowerShell version: 3
			- Modified from powershell module found in psgallery: https://www.powershellgallery.com/packages/PendingReboot/0.9.0.6
	#>
	$invokeWmiMethodParameters = @{
		Namespace    = 'root/default'
		Class	     = 'StdRegProv'
		Name		 = 'EnumKey'
		ComputerName = $ENV:ComputerName
		ErrorAction  = 'Stop'
	}
	
	$hklm = [UInt32] "0x80000002"
	
	## Query the Component Based Servicing Reg Key
	$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\')
	$registryComponentBasedServicing = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootPending'
	
	## Query WUAU from the registry
	$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\')
	$registryWindowsUpdateAutoUpdate = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames -contains 'RebootRequired'
	
	## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
	$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Services\Netlogon')
	$registryNetlogon = (Invoke-WmiMethod @invokeWmiMethodParameters).sNames
	$pendingDomainJoin = ($registryNetlogon -contains 'JoinDomain') -or ($registryNetlogon -contains 'AvoidSpnSet')
	
	## Query ComputerName and ActiveComputerName from the registry and setting the MethodName to GetMultiStringValue
	$invokeWmiMethodParameters.Name = 'GetMultiStringValue'
	$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\', 'ComputerName')
	$registryActiveComputerName = Invoke-WmiMethod @invokeWmiMethodParameters
	
	$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\', 'ComputerName')
	$registryComputerName = Invoke-WmiMethod @invokeWmiMethodParameters
	
	$pendingComputerRename = $registryActiveComputerName -ne $registryComputerName -or $pendingDomainJoin
	
	## Query PendingFileRenameOperations from the registry
	if (-not $PSBoundParameters.ContainsKey('SkipPendingFileRenameOperationsCheck'))
	{
		$invokeWmiMethodParameters.ArgumentList = @($hklm, 'SYSTEM\CurrentControlSet\Control\Session Manager\', 'PendingFileRenameOperations')
		$registryPendingFileRenameOperations = (Invoke-WmiMethod @invokeWmiMethodParameters).sValue
		$registryPendingFileRenameOperationsBool = [bool]$registryPendingFileRenameOperations
	}
	
	
	$isRebootPending = $registryComponentBasedServicing -or `
	$pendingComputerRename -or `
	$pendingDomainJoin -or `
	$registryPendingFileRenameOperationsBool -or `
	$systemCenterConfigManager -or `
	$registryWindowsUpdateAutoUpdate
	
	# Return the detailed information
	[PSCustomObject]@{
		ComputerName					 = $ENV:ComputerName
		ComponentBasedServicing		     = $registryComponentBasedServicing
		PendingComputerRenameDomainJoin  = $pendingComputerRename
		PendingFileRenameOperations	     = $registryPendingFileRenameOperationsBool
		PendingFileRenameOperationsValue = $registryPendingFileRenameOperations
		SystemCenterConfigManager	     = $systemCenterConfigManager
		WindowsUpdateAutoUpdate		     = $registryWindowsUpdateAutoUpdate
		IsRebootPending				     = $isRebootPending
		
	}
}