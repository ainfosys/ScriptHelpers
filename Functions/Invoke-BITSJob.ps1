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
		X if transfertype is upload validate the source is local and the destination is remote
		- Allow for a specified amount of retries. Allow for option to use built in timeout limit and retry and retries on fails such as hash doesnt match
		- Add other common parameters, currently only -verbose is supported
		X Validate access to destination
	#>
	[cmdletbinding()]
	param
	(
		[parameter(Mandatory = $true, HelpMessage = "The source location of the file to be transfered. Can be a local path, network path, or URL")]
		[String]$Source,
		[parameter(Mandatory = $true, HelpMessage = "The desired destination of the transfer file. For uploads this must be remote path the computer has access to.")]
		[String]$Destination,
		[parameter(Mandatory = $false, HelpMessage = "Name for the BITS job that will be created")]
		[String]$DisplayName,
		[parameter(Mandatory = $false, HelpMessage = "The priority dictates the speed of the transfer")]
		[ValidateSet("Foreground", "High", "Normal", "Low")]
		[String]$Priority = "Normal",
		[parameter(Mandatory = $false, HelpMessage = "The description of the BITS job that will be created")]
		[String]$Description = "a BITS job created with Invoke-BITSJob",
		[parameter(Mandatory = $false)]
		[ValidateSet("Download", "Upload", "UploadReply")]
		[String]$TransferType = "Download",
		[parameter(Mandatory = $false, HelpMessage = "Expected hash of the file being transfered")]
		[String]$FileHash,
		[parameter(Mandatory = $false, HelpMessage = "Algorithm to be used when a file hash parameter is provided")]
		[ValidateSet("MD5", "MACTripleDES", "RIPEMD160", "SHA1", "SHA256", "SHA384", "SHA512")]
		[String]$FileHashAlgorithm
	)
	
	#region Parameter validation
	$boolCheck = [bool]$FileHash
	if ($boolCheck)
	{
		# filehash parameter was provided, make sure the algorithm was provided
		$boolCheck = [bool]$FileHashAlgorithm
		if (!($boolCheck))
		{
			Write-Output -InputObject "A file hash was provided but not the algorithm used to get the file hash. Please provide both when providing a file hash."; Throw
		}
	}
	else
	{
		Write-Verbose -Message "FileHash parameter is not provided so the transfered file will not be validated against a hash"
	}
	
	if ($TransferType -ieq "Upload")
	{
		# validate that the destination parameter provided is a remote destination
		# Unsure of best way to do this, currently just checking for leading double backslashes
		if ($Destination -inotlike "\\*")
		{
			Write-Output -InputObject "TransferType set to Upload but Destination is not a remote path"
		}
		else
		{
			# test the destination is accessible
			if (!(Test-Path $Destination))
			{
				Write-Output -InputObject "Failed to validate access to remote path. Make sure the path provided is accessible."	
			}
		}	
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