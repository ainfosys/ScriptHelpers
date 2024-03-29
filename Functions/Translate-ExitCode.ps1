﻿function Translate-ExitCode
{
	param
	(
		[parameter(Mandatory = $true,
			 ValueFromPipeline = $true,
			 HelpMessage= 'Process object created by using start-process with -passthru')]
		$Process
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
    

    # Return the information on the exit code
    Return $($ErrorInfo | ConvertTo-Json | ConvertFrom-Json)
}