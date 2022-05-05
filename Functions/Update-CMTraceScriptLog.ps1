function Update-CMTraceScriptLog
{
	<#
	.DESCRIPTION: Create and append log information to a cmtrace compatible log file
    .AUTHOR: Ryan
    .PARAMETERS:
        - Message (Required): The log message that gets apppended to the end of the log

        - Component: The source of the log message. This is optional and allows for better organization of the log file.

        - Type: Info, warning, or error. Info is the default value. Warning lines in CMTrace log files show as yellow, errors show as red.
        Note that any message containing the word "Error" will also be highlighted in red.

        - ScriptLogFullName: The location of the logfile including the name. Default is "$ENV:SystemDrive\Windows\temp\CMTrace-ScriptLog.log"

        - DeleteOldLog: Use this to remove an old log file, create a new log file in its place and then append the message to that log file. Only
        Use this at the start of a script or if the log file needs to be deleted mid script for some reason.
	#>
	param
	(
		[parameter(Mandatory = $true)]
		[String]$Message,
		[parameter(Mandatory = $false)]
		[String]$Component,
		[Parameter(Mandatory = $false)]
		[ValidateSet("Info", "Warning", "Error")]
		[String]$Type = "Info",
        [parameter()]
        [String]$ScriptLogFullName = "$ENV:SystemDrive\Windows\temp\CMTrace-ScriptLog.log",
        [parameter()]
        [switch]$DeleteOldLog = $false
	)
	if ($null -eq $Component) { $Component = "" }
	
	switch ($Type)
	{
		"Info" { [int]$Type = 1 }
		"Warning" { [int]$Type = 2 }
		"Error" { [int]$Type = 3 }
	}
	
	# Create a log entry
	$Format = "<![LOG[$Message]LOG]!>" +`
	"<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
	"date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
	"component=`"$Component`" " +`
	"context=`"`" " +`
	"type=`"$Type`" " +`
	"thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
	"file=`"MDT-Wizard-V3`">"
	
	# set the contents of the log to this prior to removing and adding the real contents (only on creation)
	# Its stupid but CMTrace wont load the log content unless I do this
	$InitialContent = '<![LOG[TSHOST: Script completed with return code 0]LOG]!><time="11:29:36.000 + 000" date="04 - 22 - 2022" component="TaskSequencePSHost" context="" type="1" thread="" file="TaskSequencePSHost">'
	
    if($DeleteOldLog){

        if(Test-path $ScriptLogFullName){

            Remove-Item -Path $ScriptLogFullName -Force | Out-Null
            New-Item -Path $ScriptLogFullName -Value $InitialContent -Force | Out-Null
            Set-Content -Path $ScriptLogFullName -Value $Format -Force
        }
        else{

            Write-Warning "Previous log file not found in provided location"
            New-Item -Path $ScriptLogFullName -Value $InitialContent -Force | Out-Null
            Set-Content -Path $ScriptLogFullName -Value $Format -Force
        }
    }
    else{
        if(Test-path $ScriptLogFullName){

            Add-Content -Path $ScriptLogFullName -Value $Format -Force
        }
        else{
            New-Item -Path $ScriptLogFullName -Value $InitialContent -Force | Out-Null
            Set-Content -Path $ScriptLogFullName -Value $Format -Force
        }
    }
}