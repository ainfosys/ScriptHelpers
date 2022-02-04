Function Reboot-Toast {
<#
.DESCRIPTION: Creates a toast notification with the option to snooze or reboot
.AUTHOR: Ryan
.NOTES: 
    - Stolen and modifed from https://www.cyberdrain.com/monitoring-with-powershell-notifying-users-of-windows-updates/
    - Only 5 options are allowed in a toast drop down menu. Options here refer to time permited to snooze the toast
#>

    param
(
	[parameter(Mandatory = $false)]
	$ToastTitle = "Reboot to complete updates",
    [parameter(Mandatory = $false)]
	$ToastText ="Updates have been installed on your computer at $(get-date). Please select if you'd like to reboot now, or snooze this message.",
    [parameter(Mandatory = $false)]
	$ToastHeroImageSource = 'https://media.giphy.com/media/eiwIMNkeJ2cu5MI2XC/giphy.gif',
    [parameter(Mandatory = $false)]
	$ToastAppSource = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\msinfo32.exe'
)
    
    
    $heroimage = New-BTImage -Source $ToastHeroImageSource -HeroImage
    $Text1 = New-BTText -Content  $ToastTitle
    $Text2 = New-BTText -Content $ToastText
    $Button = New-BTButton -Content "Snooze" -snooze -id 'SnoozeTime'
    $Button2 = New-BTButton -Content "Reboot now" -Arguments "ToastReboot:" -ActivationType Protocol
    $10Min = New-BTSelectionBoxItem -Id 10 -Content '10 minutes'
    $30Min = New-BTSelectionBoxItem -Id 30 -Content '30 minutes'
    $1Hour = New-BTSelectionBoxItem -Id 60 -Content '1 hour'
    $4Hour = New-BTSelectionBoxItem -Id 240 -Content '4 hours'
    $1Day = New-BTSelectionBoxItem -Id 1440 -Content '1 day'
    $Items = $10Min, $30Min, $1Hour, $4Hour, $1Day
    $SelectionBox = New-BTInput -Id 'SnoozeTime' -DefaultSelectionBoxItemId 10 -Items $Items
    $action = New-BTAction -Buttons $Button, $Button2 -inputs $SelectionBox
    $Binding = New-BTBinding -Children $text1, $text2 -HeroImage $heroimage
    $Visual = New-BTVisual -BindingGeneric $Binding
    $Content = New-BTContent -Visual $Visual -Actions $action
    Submit-BTNotification -Content $Content -AppId $ToastAppSource -UniqueIdentifier 'Reboot-Toast'
}