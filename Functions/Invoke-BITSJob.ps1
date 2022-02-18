Function Invoke-BITSJob
{
	<#
	.DESCRIPTION: Due to insconsistencies in getting a bits job to work properly across various machines I created this function as a replacement for just using Start-BitsTransfer and then writing seperate
	              logic to wait for the transfer and take action on errors that occur.	              
	.AUTHOR: Ryan McAvoy
	.NOTES:
	    - For any BITS troubleshooting, I highly recommend using the Bits Manager tool originally made by a Microsoft employee and later improved by 2Pint (https://2pintsoftware.com/download/bits-manager/)	      
	.TODO: 
		- Allow for all parameters that Start-BitsTransfer allows
		- if transfertype is upload validate the source is local and the destination is remote
		- Allow for a specified amount of retries. Allow for option to use built in timeout limit and retry and retries on fails such as hash doesnt match
		- Add other common parameters, currently only -verbose is supported
		- Validate access to destination
	#>
	[cmdletbinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[String]$Source,
		[parameter(Mandatory = $true)]
		[String]$Destination,
		[parameter(Mandatory = $false)]
		[String]$DisplayName,
		[parameter(Mandatory = $false)]
		[String]$Priority = "Normal",
		[parameter(Mandatory = $false)]
		[String]$Description = "a BITS job created with Invoke-BITSJob",
		[parameter(Mandatory = $false)]
		[String]$TransferType = "Download",
		[parameter(Mandatory = $false)]
		[String]$FileHash,
		[parameter(Mandatory = $false)]
		[String]$FileHashAlgorithm
	)
	
	#region Parameter validation
	$AcceptedPriorityValues = "Foreground", "High", "Normal", "Low"
	$AcceptedTransferTypes = "Download", "Upload", "UploadReply"
	$AcceptedAlgorithms = "MD5", "MACTripleDES", "RIPEMD160", "SHA1", "SHA256", "SHA384", "SHA512"
	
	Write-Verbose -Message "Validating the parameters provided"
	
	if ($AcceptedPriorityValues -inotcontains $Priority)
	{
		Write-Output -InputObject "The priority parameter has been set to an unaccepted value. Please use Foreground, High, Normal or Low where Foreground is the highest priority."; Throw
	}
	else
	{
		Write-Verbose -Message "Priority parameter is valid"
	}
	
	if ($AcceptedTransferTypes -inotcontains $TransferType)
	{
		Write-Output -InputObject "The TransferType parameter has been set to an unaccepted value. Please use Download, Upload or UploadReply."; Throw
	}
	else
	{
		Write-Verbose -Message "TransferType parameter is valid"
	}
	
	$boolCheck = [bool]$FileHash
	if ($boolCheck)
	{
		# filehash parameter was provided, make sure the algorithm was provided
		$boolCheck = [bool]$FileHashAlgorithm
		if (!($boolCheck))
		{
			Write-Output -InputObject "A file hash was provided but not the algorithm used to get the file hash. Please provide both when providing a file hash."; Throw
		}
		else
		{
			if ($AcceptedAlgorithms -inotcontains $FileHashAlgorithm)
			{
				Write-Output -InputObject "Unaccepted file hash algorithm entered. Please use MD5, MACTripleDES, RIPEMD168, SHA1, SHA256, SHA384, or SHA512"
			}
			else
			{
				Write-Verbose -Message "FileHash and FileHashAlgorithm were provided and are valid. The trasfer file will be validated against the hash once the transfer completes."
			}
		}
	}
	else
	{
		Write-Verbose -Message "FileHash parameter is not provided so the transfered file will not be validated against a hash"
	}
	
	#endregion
	
	#region Pre-Checks
	
	# verify that there isn't a job with the desired displayname, also set default if displayname is not provided
	$boolCheck = [bool]$DisplayName
	if ($boolCheck -eq $false)
	{
		Write-Verbose -Message "The DisplayName parameter was not provided so the value will be set now"
		# the value of displayname was not provided, create it now
		$DefaultDisplayName = "Invoke-BITSJob Job #"
		$CurrentBitJobTitles = Get-BitsTransfer | Select-Object -ExpandProperty DisplayName
		$CurrentBitJobTitlesCount = $CurrentBitJobTitles.count
		if ($CurrentBitJobTitles -ilike "$DefaultDisplayName*")
		{
			$CurrentBitJobTitlesCount++
			$DisplayName = $($DefaultDisplayName + "$CurrentBitJobTitlesCount")
			Write-Verbose "The DisplayName will be $DisplayName"
		}
		else
		{
			$DisplayName = $($DefaultDisplayName + "1")
			Write-Verbose "The DisplayName will be $DisplayName"
		}
	}
	
	#endregion
	
	#region Process
	
	try
	{
		# first attempt non-asynchronous transfer
		if ($VerbosePreference -eq 'Continue')
		{
			Write-Verbose -Message "Importing BITS module and attempting BITS transfer non-asynchronous"
			Import-Module -Name BitsTransfer -ErrorAction Stop -Verbose
			Start-BitsTransfer -Source $Source -Destination $Destination -DisplayName $DisplayName -Description $Description -Priority $Priority -transfertype $TransferType -ErrorAction Stop -Verbose
		}
		else
		{
			Import-Module -Name BitsTransfer -ErrorAction Stop
			Start-BitsTransfer -Source $Source -Destination $Destination -DisplayName $DisplayName -Description $Description -Priority $Priority -transfertype $TransferType -ErrorAction Stop
		}

	}
	Catch
	{
		# determine what caused the error
		$lastErrorCmd = $error[0].InvocationInfo.Line
		if ($lastErrorCmd -ilike "Get-bitstransfer*")
		{
			Write-Output -InputObject "An error was thrown when attempting to get the BITS job. Error: $($Error[0])"; Throw
		}
		elseif($lastErrorCmd -ilike "*asynchronous*")
		{
			# asynchonous failed, try without
			Start-BitsTransfer -Source $Source -Destination $Destination -DisplayName $DisplayName -Description $Description -Priority $Priority -transfertype $TransferType -Asynchronous -ErrorAction Stop
			$BitsJob = Get-BitsTransfer -Name $DisplayName -ErrorAction Stop
			$boolCheck = [bool]$BitsJob
			if ($BitsJob)
			{
				# Bits job started succesfully and was identified
				While ($BitsJob.JobState -eq "Transferring" -or $BitsJob.JobState -eq "Connecting" -or $BitsJob.JobState -eq "Queued")
				{
					Start-Sleep -Seconds 1
				}
				$BitsJob | Complete-BitsTransfer -ErrorAction Stop # throw exception here if unable to complete as this will prevent the file showing in the destination
			}
			else
			{
				Write-Output -InputObject "Failed both asynchronous and non-asynchronous BITS jobs"
				$BitsJob | Complete-BitsTransfer -ErrorAction SilentlyContinue; Throw
			}
		}
		elseif ($lastErrorCmd -ilike "Import-Module*")
		{
			Write-Output -InputObject "Failed to import the BITS powershell module."; Throw
		}
		else
		{
			Write-Output "An error occured: $($error[0] | Format-List)"
		}
	}
	
	#endregion
	
	#region Validate
	
	if (Test-Path $Destination)
	{
		# file found in destination
		$boolCheck = [bool]$FileHash
		if ($boolCheck)
		{
			# File hash was provided so the file will be validated against the hash
			$localFileHash = Get-FileHash -Path $Destination -Algorithm $FileHashAlgorithm | Select-Object -ExpandProperty Hash
			if ($localFileHash -ne $FileHash)
			{
				Write-Output -InputObject "The provided file hash does not match the file hash of the transfered file", "Provided file hash: $FileHash", "Destination file hash: $localFileHash", "Destination file: $Description", "File hash algorithm: $FileHashAlgorithm"
				Get-BitsTransfer -Name $DisplayName | Complete-BitsTransfer; Throw
			}
			else
			{
				Write-Output -InputObject "The file hash provided matches the file hash of the transfered file"
				# dont show errors as 
				Get-BitsTransfer -Name $DisplayName -ErrorAction SilentlyContinue | Complete-BitsTransfer -ErrorAction SilentlyContinue
			}
		}
	}
	
	#endregion
}