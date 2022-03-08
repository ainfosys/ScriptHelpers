Function Get-MostActiveUser{

<#
.DESCRIPTION: Using log in and log out event viewer logs determine who logs into the computer the most
.AUTHOR: Ryan

#>
    $UserLoginEvents = @()

    $logs =Get-WinEvent -LogName Security| Where-Object {$_.ID -eq 4634 -or $_.ID -eq 4624}

    ForEach ($log in $logs) {

    if ($log.Id -eq 4634)

    {

    $type=”SessionStop”

    $username=$log.Properties[1].Value

    }

 

    Else {

    $type=”SessionStart”

    $username=$log.Properties[5].Value

    }

      $IgnoredUsernames = "SYSTEM","LOCAL SERVICE","NETWORK SERVICE","defaultuser0"

            if ($username -ne “” -and $IgnoredUsernames -inotcontains $username) {
    
                if($username -inotlike "*DWM-*" -and $username -inotlike "UMFD-*"){
                    $UserLoginEvents += New-Object PSObject -Property @{“Time” = $log.TimeCreated; “Event” = $type; “User” = $username};
                }
            }

    }

    $MostActiveUserInfo = @()
    ForEach($user in $($UserLoginEvents.user)){
        $LogonCount = $($UserLoginEvents | where {$_.user -ieq $user -and $_.Event -ieq "SessionStart"}).count
        $LastLoginDate = $UserLoginEvents | Where {$_.User -ieq $user -and $_.Event -ieq "SessionStart"} | Select -last 1 -expand Time

        $MostActiveUserInfo += New-Object PSObject -Property @{"UserName" = $User; "LastLoginDate" = $LastLoginDate; "LogonCount" = $LogonCount}
    }
    # Return the username of the user that has logged in the most
    Return $($MostActiveUserInfo | where {$_.LogonCount -eq $($MostActiveUserInfo.LogonCount | measure -Maximum | select -expand Maximum)} | select -Unique -expand UserName)
}