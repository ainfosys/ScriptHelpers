function Translate-ExitCode
{
	param
	(
		[parameter(Mandatory = $true,
			 ValueFromPipeline = $true,
			 HelpMessage= 'Process object created by using start-process with -passthru')]
		$Process,
		[parameter(HelpMessage = "Automatically output information for process in a human readable format")]
		[switch]$AutoOutput
	)
    
	[xml]$ErrorXml = Invoke-WebRequest -UseBasicParsing -uri "https://raw.githubusercontent.com/ainfosys/ScriptHelpers/main/Files/ms-error-codes.xml" | select -expand Content
	$SpecifiedError = $ErrorXml.Root.row | where { $_.code -eq $($Process.exitcode) }
	
	# append to psobject, add property to indicate if the exit code means failure or not
	switch ($($SpecifiedError.Code)) {
		"0" {
			$Success = $true
		}
		"1641" {
			$Success = $true
		}
		"3010" {
			$Success = $true
		}
		"3011" {
			$Success = $true
		}
		default {
			$Success = $false
		}
	}
	
	$ErrorInfo = @{
		Code = $($SpecifiedError.Code)
		Description = $($SpecifiedError.Description)
		Success = $Success
	}

	if($AutoOutput){
		if($ErrorInfo.success){
			Write-Output "Exitcode indicates success"
			Write-Output "Exit code: $($ErrorInfo.Code)"
			Write-Output "Exit code generic description: $($ErrorInfo.Description)"
		}
		else{
			Write-Output "Exitcode indicates failure"
			Write-Output "Exit code: $($ErrorInfo.Code)"
			Write-Output "Exit code generic description: $($ErrorInfo.Description)" 
		}
	}else{   
    	Return $($ErrorInfo | ConvertTo-Json | ConvertFrom-Json)
	}
}
