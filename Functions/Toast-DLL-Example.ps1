Add-Type -Path 'E:\Resources\Microsoft.Toolkit.Uwp.Notifications.dll'
$AppLogo = "E:\ais mini logos\ais-mini-logo-white.ico"
$InlineImageURI = "E:\Resources\unnamed.png"
$AppID = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\msinfo32.exe'


$CompatMgr = [Microsoft.Toolkit.Uwp.Notifications.ToastNotificationManagerCompat]
Register-ObjectEvent -InputObject $CompatMgr -EventName OnActivated -Action {
    if ($Event.SourceArgs.Argument -eq 'PostponeButton') {
        switch ($Event.SourceArgs.UserInput.Value) {
            Item1 {
                $Text1 = 'Delaying reboot notification for 10 minutes'
            }
            Item2 {
                $Text1 = 'Delaying reboot notification for 15 minutes'
            }
            Item3 {
                $Text1 = 'Delaying reboot notification for 30 minutes'
            }
            Item4 {
                $Text1 = 'Delaying reboot notification for 1 hour'
            }
        }

        $ContentBuilder = [Microsoft.Toolkit.Uwp.Notifications.ToastContentBuilder]::new()
        $null = $ContentBuilder.AddText($Text1)
        $null = $ContentBuilder.AddAppLogoOverride($AppLogo, 'None')
        $null = $ContentBuilder.AddAudio($null, $null, $true)


        $ContentBuilder.Show()
    }
}

Register-ObjectEvent -InputObject $CompatMgr -EventName OnActivated -Action {
    if ($Event.SourceArgs.Argument -eq 'RebootButton') {

        	$oReturn = [System.Windows.Forms.MessageBox]::Show("Reboot and apply the system update now?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo)
	        switch ($oReturn)
	        {
		        "YES" {
			        Write-Host "User selected to reboot and confirmed selection. Rebooting now."
			        #Add-Content -Path $script:ResponseTxtPath -Value "Closed_$(Get-Date)" -Force
			        #Add-Content -Path $script:ResponseTxtPath -Value "Response_Reboot Now" -Force
			        #New-Item -Path "C:\Windows\Temp\" -Name "PromptComplete.txt" -ItemType File -Force | Out-Null
			        #start "C:\Windows\Temp\Rebooting-Dialog.exe"
		        }
                "NO"{
                    # Show the reboot required toast again as it will dismiss after selecting a button
                }
	        }
    }
}

Register-ObjectEvent -InputObject $CompatMgr -EventName OnDismissed -Action {
    if ($Event.SourceArgs.Argument -eq 'RebootButton') {

        	$oReturn = [System.Windows.Forms.MessageBox]::Show("Yap?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo)
	        switch ($oReturn)
	        {
		        "YES" {
			        Write-Host "User selected to reboot and confirmed selection. Rebooting now."
			        #Add-Content -Path $script:ResponseTxtPath -Value "Closed_$(Get-Date)" -Force
			        #Add-Content -Path $script:ResponseTxtPath -Value "Response_Reboot Now" -Force
			        #New-Item -Path "C:\Windows\Temp\" -Name "PromptComplete.txt" -ItemType File -Force | Out-Null
			        #start "C:\Windows\Temp\Rebooting-Dialog.exe"
		        }
                "NO"{
                    # Show the reboot required toast again as it will dismiss after selecting a button
                }
	        }
    }
}


$ContentBuilder = [Microsoft.Toolkit.Uwp.Notifications.ToastContentBuilder]::new()
$null = $ContentBuilder.AddText('Upgrade requires reboot')
$null = $ContentBuilder.AddText('An important update was installed on your computer and a reboot is required. Select reboot now or select how long you would like to delay this notification.')
$null = $ContentBuilder.AddAppLogoOverride($AppLogo, $null, "AIS", $null)


$Choices = @()
$Choices += [ValueTuple[string, string]]::new('Item1', '10 Minutes')
$Choices += [ValueTuple[string, string]]::new('Item2', '15 Minutes')
$Choices += [ValueTuple[string, string]]::new('Item3', '30 Minutes')
$Choices += [ValueTuple[string, string]]::new('Item4', '1 Hour')

#$null = $ContentBuilder.AddInlineImage($InlineImageURI, "Reboot Image", $null, $null, $null)
$null = $ContentBuilder.AddComboBox('Selection001', 'Select how long to postpone this prompt', 'Item1', $Choices)
$null = $ContentBuilder.AddButton('Postpone', 'Background', 'PostponeButton')
$null = $ContentBuilder.AddButton('Reboot Now', 'Background', 'RebootButton')
$null = $ContentBuilder.AddAttributionText("Alliance InfoSystems", 'en-us')
$null = $ContentBuilder.SetToastScenario('3')
$null = $ContentBuilder.SetToastDuration('1')
#$null = $ContentBuilder.AddAudio($null, $null, $true)
$null = $ContentBuilder.AddAppLogoOverride()
$null = $ContentBuilder.AddHeader("Reboot Prompt","Reboot Required", "Testing")

$ContentBuilder.Show()