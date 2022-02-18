Function Get-ActiveUser
{
	<#
	.DESCRIPTION: Determine if users are logged in and active, and also determine if the user has apps open if logged in
	.AUTHOR: Ryan
	.TODO: 
		- Create a parameter that allows checking either all user sessions or just active user session
	#>
	
	#region Determine logged in users
	# Code in this region shamelessly stolen from: https://stackoverflow.com/questions/39212183/easier-way-to-parse-query-user-in-powershell-or-quser
	$LoggedInUsers = @()
	$Lines = @(query user).ForEach({ $(($_) -replace ('\s{2,}', ',')) }) # REPLACES ALL OCCURENCES OF 2 OR MORE SPACES IN A ROW WITH A SINGLE COMMA
	$header = $($Lines[0].split(',').trim()) # EXTRACTS THE FIRST ROW FOR ITS HEADER LINE 
	for ($i = 1; $i -lt $($Lines.Count); $i++)
	{
		# NOTE $i=1 TO SKIP THE HEADER LINE
		$Res = "" | Select-Object $header # CREATES AN EMPTY PSCUSTOMOBJECT WITH PRE DEFINED FIELDS
		$Line = $($Lines[$i].split(',')).ForEach({ $_.trim().trim('>') }) # SPLITS AND THEN TRIMS ANOMALIES 
		if ($Line.count -eq 5) { $Line = @($Line[0], "$($null)", $Line[1], $Line[2], $Line[3], $Line[4]) } # ACCOUNTS FOR DISCONNECTED SCENARIO
		for ($x = 0; $x -lt $($Line.count); $x++)
		{
			$Res.$($header[$x]) = $Line[$x] # DYNAMICALLY ADDS DATA TO $Res
		}
		$LoggedInUsers += $Res # APPENDS THE LINE OF DATA AS PSCUSTOMOBJECT TO AN ARRAY
		Remove-Variable Res # DESTROYS THE LINE OF DATA BY REMOVING THE VARIABLE
	}
	#endregion
	
	#region Determine open apps for users logged in
	$boolCheck = [bool]$LoggedInUsers
	if ($boolCheck)
	{
		# there are users logged in so determine if there are apps open in their session
		forEach ($User in $($LoggedInUsers | Where-Object { $_.State -eq "Active" } | Select-Object -ExpandProperty UserName))
		{
			$ActiveUserApps = get-process -IncludeUserName | where { $_.Username -ieq "$ENV:COMPUTERNAME\$User" } | Sort-Object -Unique -Property ProcessName | Select-Object -ExpandProperty ProcessName
		}		
	}
	#endregion
	
	#region Return information
	$boolCheck = [bool]$LoggedInUsers
	if ($boolCheck)
	{
		$boolCheck = [bool]$ActiveUserApps
		if ($boolCheck)
		{
			$ReturnObject = @{
				"Username" = $($LoggedInUsers | Where-Object { $_.State -eq "Active" } | Select-Object -ExpandProperty USERNAME)
				"Login Time" = $($LoggedInUsers | Where-Object { $_.State -eq "Active" } | Select-Object -ExpandProperty 'LOGON TIME')
				"Open Apps" = $ActiveUserApps
			}
		}
		else
		{
			$ReturnObject = @{
				"Username" = $($LoggedInUsers | Where-Object { $_.State -eq "Active" } | Select-Object -ExpandProperty USERNAME)
				"Login Time" = $($LoggedInUsers | Where-Object { $_.State -eq "Active" } | Select-Object -ExpandProperty 'LOGON TIME')
				"Open Apps" = "None"
			}
		}
		
		Return $ReturnObject
	}
	else
	{
		Return "No active user"	
	}
	#endregion
}