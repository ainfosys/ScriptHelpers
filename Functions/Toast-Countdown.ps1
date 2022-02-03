Function Toast-Countdown {
<#
.DESCRIPTION: Creates a persistent (unless dismissed by the end user) toast notification that displays a progress bar with a countdown to a specified time.
.AUTHOR: Ryan
.NOTES:
    - For the ProgressBarText parameter, the remaining time will show following the text provided.
    - The only required parameter is the timeoutlimit (How long you want the countdown to last in minutes, ex: entering '5' is 5 minutes)
#>


param
(
	[parameter(Mandatory = $true)]
	$TimeoutLimit,
	[parameter(Mandatory = $false)]
	$ToastTitle = "Rebooting soon",
	[parameter(Mandatory = $false)]
	$ToastMessage = "Please save and close your work",
	[parameter(Mandatory = $False)]
	$ToastID = "Reboot Countdown",
	[parameter(Mandatory = $false)]
	$ProgressBarTitle = "Reboot to complete update",
	[parameter(Mandatory = $false)]
	$ProgressBarText = "Time remaining in: ",
	[parameter(Mandatory = $false)]
	$ToastAppSource = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\msinfo32.exe',
	[parameter(Mandatory = $False)]
	$ToastLogo = "https://aisdownload.s3.amazonaws.com/Branding/Alliance-Logo-white4.ico"
)

$TimeoutTime = $(Get-Date).AddMinutes($TimeOutLimit)

$TimeDifference = $TimeoutTime - $(get-date)
$TimeDifferenceDecimal = "{0:N2}" -f $(1 - ($("$($TimeDifference.Minutes)" + "." + "$($TimeDifference.Seconds)")/$TimeOutLimit))
$TimeFormated = "$($TimeDifference.Minutes)" + ":" + "$($TimeDifference.Seconds | % tostring 00)"

if($($TimeDifference.Minutes) -gt "0"){
    $ProgressBarTrailingText = " minutes"
}
else{
   $ProgressBarTrailingText = " seconds" 
}


$MainProgressBar = New-BTProgressBar -title 'ProgressTitle' -status 'ProgressStatus' -value 'ProgressValue'
$ToastID = "Reboot Countdown"

$DataBinding = @{
    'ProgressTitle'  = $ProgressBarTitle
    'ProgressStatus' = '$($ProgressBarText + $TimeFormated + $ProgressBarTrailingText)'
    'ProgressValue'  = $TimeDifferenceDecimal
}

$BTText = $ToastTitle, $ToastMessage
$Applogo = $ToastLogo
$AppID = $ToastAppSource

## CALL UNDER CURRENT USER NAMESPACE ##
New-BurntToastNotification -Text $BTText -UniqueIdentifier $ToastID -ProgressBar $MainProgressBar -DataBinding $DataBinding -AppId $AppID -AppLogo "https://aisdownload.s3.amazonaws.com/Branding/Alliance-Logo-white4.ico"

do{
    
    $TimeDifference = $TimeoutTime - $(get-date)
    $TimeDifferenceDecimal = "{0:N2}" -f $(1 - ($("$($TimeDifference.Minutes)" + "." + "$($TimeDifference.Seconds)")/$TimeOutLimit))
    $TimeFormated = "$($TimeDifference.Minutes)" + ":" + "$($TimeDifference.Seconds | % tostring 00)"

    if($($TimeDifference.Minutes) -gt "0"){
        $ProgressBarTrailingText = " minutes"
    }
    else{
        $ProgressBarTrailingText = " seconds" 
    }

    $DataBinding['ProgressStatus'] = $($ProgressBarText + $TimeFormated + $ProgressBarTrailingText)
    $DataBinding['ProgressValue'] = $TimeDifferenceDecimal

    $Null = Update-BTNotification -UniqueIdentifier $ToastID -DataBinding $DataBinding -AppId $AppID

}Until($TimeDifference -le '0')
}