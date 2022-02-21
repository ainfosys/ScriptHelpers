function Show-Reboot-Required-Prompt_psf {
    
    param
    (
	    [parameter(Mandatory = $false)]
        [String]
	    $PromptTitle = 'System Update',
        [parameter(Mandatory = $false)]
        [String]
	    $PromptMessage = 'An important update has been applied to your computer. Please save an close any open work and press the "Reboot now" button to restart the computer. If now isn''t a good time select how long you would like to delay the reboot prompt and press the "Delay Reboot" button.'
    )

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form_SystemUpdate = New-Object 'System.Windows.Forms.Form'
	$combobox_delaytime = New-Object 'System.Windows.Forms.ComboBox'
	$buttonDelayReboot = New-Object 'System.Windows.Forms.Button'
	$button_RebootNow = New-Object 'System.Windows.Forms.Button'
	$labelAnImportantUpdateHas = New-Object 'System.Windows.Forms.Label'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$form_SystemUpdate_Load = {
		
		# Set the initial location of the powershell form to the bottom right hand corner of the primary monitor
		# Idea is to mimic toast notifications
		$PrimaryDisplayBounds = [System.Windows.Forms.Screen]::AllScreens | Where { $_.Primary -eq $True } | select -expand Bounds
		$XPos = $PrimaryDisplayBounds.Right - "451"
		$YPos = $PrimaryDisplayBounds.Bottom - "235"
		$formWidth = $form_SystemUpdate.Width
		$FormHeight = $form_SystemUpdate.Height
		$form_SystemUpdate.SetBounds($XPos, $YPos, $formWidth, $FormHeight)
		
		# set the default reboot delay time selection
		$combobox_delaytime.SelectedIndex = 3
		
		# Disallow form closing through means other than the provided buttons
		$form_SystemUpdate.add_Closing({ $_.Cancel = $true })
		
		# Check the registry for key properties tracking user response and last time the prompt was opened/closed
		$script:Key = "HKLM:\SOFTWARE\RebootPrompt"
		if (Test-Path $Key)
		{
			# key already exists, get values of properties if they exist
			$script:PreviousPromptInfo = @{
				Open = $(Get-ItemProperty -Path $Key -Name "Open" -ErrorAction SilentlyContinue)
				Close = $(Get-ItemProperty -Path $Key -Name "Close" -ErrorAction SilentlyContinue)
				Response = $(Get-ItemProperty -Path $Key -Name "Response" -ErrorAction SilentlyContinue)
			}
			
			# record the time the prompt was opened on the computer
			Set-ItemProperty -Path $Key -Name "Open" -Value "$(Get-date)" -Force
		}
		else
		{
			# the key doesn't exist so create it now
			New-Item -Path $($key | Split-Path -Parent) -Name $($Key | Split-Path -Leaf) -Force
			
			# record the time the prompt was opened on the computer
			New-ItemProperty -Path $Key -Name "Open" -Value "$(Get-date)" -PropertyType String -Force
			
			# create empty key properties to be filled on form close
			New-ItemProperty -Path $Key -Name "Close" -PropertyType String -Force
			New-ItemProperty -Path $Key -Name "Response" -PropertyType String -Force
		}
		
	}

	$button_RebootNow_Click={
		$oReturn = [System.Windows.Forms.MessageBox]::Show("Reboot and apply the system update now?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo)
		switch ($oReturn)
		{
			"YES" {
				Write-Host "User selected to reboot and confirmed selection. Rebooting now."
				Set-ItemProperty -Path $script:Key -Name "Close" -Value $(Get-date) -Force
				Set-ItemProperty -Path $script:Key -Name "Response" -Value "Reboot" -Force
				Restart-Computer			
			}
		}
	}
	
	$buttonDelayReboot_Click={
		Write-Host "User selected to delay reboot prompt. Delayed $($combobox_delaytime.Text)"
		Set-ItemProperty -Path $script:Key -Name "Close" -Value $(Get-date) -Force
		Set-ItemProperty -Path $script:Key -Name "Response" -Value "Delayed $($combobox_delaytime.Text)" -Force
		$form_SystemUpdate.add_Closing({ $_.Cancel = $False })
		$form_SystemUpdate.Close()	
	}
	
	$combobox_delaytime_SelectedIndexChanged={
		
		if ($combobox_delaytime.Text -eq $null)
		{
			if ($buttonDelayReboot.Enabled -eq $true)
			{
				$buttonDelayReboot.Enabled = $false
			}
			
		}
		else
		{
			if ($buttonDelayReboot.Enabled -eq $false)
			{
				$buttonDelayReboot.Enabled = $true
			}		
		}
	}
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$form_SystemUpdate.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$combobox_delaytime.remove_SelectedIndexChanged($combobox_delaytime_SelectedIndexChanged)
			$buttonDelayReboot.remove_Click($buttonDelayReboot_Click)
			$button_RebootNow.remove_Click($button_RebootNow_Click)
			$form_SystemUpdate.remove_Load($form_SystemUpdate_Load)
			$form_SystemUpdate.remove_Load($Form_StateCorrection_Load)
			$form_SystemUpdate.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch { Out-Null <# Prevent PSScriptAnalyzer warning #> }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$form_SystemUpdate.SuspendLayout()
	#
	# form_SystemUpdate
	#
	$form_SystemUpdate.Controls.Add($combobox_delaytime)
	$form_SystemUpdate.Controls.Add($buttonDelayReboot)
	$form_SystemUpdate.Controls.Add($button_RebootNow)
	$form_SystemUpdate.Controls.Add($labelAnImportantUpdateHas)
	$form_SystemUpdate.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
	$form_SystemUpdate.AutoScaleMode = 'Dpi'
	$form_SystemUpdate.AutoSize = $True
	$form_SystemUpdate.BackColor = [System.Drawing.Color]::FromArgb(255, 224, 224, 224)
	$form_SystemUpdate.ClientSize = New-Object System.Drawing.Size(442, 162)
	$form_SystemUpdate.ControlBox = $False
	#region Binary Data
	$Formatter_binaryFomatter = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter
	$System_IO_MemoryStream = New-Object System.IO.MemoryStream (,[byte[]][System.Convert]::FromBase64String('
AAEAAAD/////AQAAAAAAAAAMAgAAAFFTeXN0ZW0uRHJhd2luZywgVmVyc2lvbj00LjAuMC4wLCBD
dWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWIwM2Y1ZjdmMTFkNTBhM2EFAQAAABNTeXN0
ZW0uRHJhd2luZy5JY29uAgAAAAhJY29uRGF0YQhJY29uU2l6ZQcEAhNTeXN0ZW0uRHJhd2luZy5T
aXplAgAAAAIAAAAJAwAAAAX8////E1N5c3RlbS5EcmF3aW5nLlNpemUCAAAABXdpZHRoBmhlaWdo
dAAACAgCAAAAAAEAAAABAAAPAwAAAHknAAACAAABAAEAAAAAAAEAIABjJwAAFgAAAIlQTkcNChoK
AAAADUlIRFIAAAEAAAABAAgGAAAAXHKoZgAAJypJREFUeNrt3XmQHNWd4PFvZtZ9V/ahbnW3pNZ9
ovtCt9B9IaGz1d0ChDgk1BJrT9jszoxjbM/MrgcveGNivZ6YDe8fMzGeWO94PGYM2GCby9jGYLAH
G7ANBnMahBCidbW6KvePJ81wtFSvuyoz6/h9IhSOcLyiX2ZV/jLzvd/7PRBCCCGEEEIIIYQQQggh
hBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQQgghhBBCCCGEEEIIIYQQ
QgghhBBCCKHJuPBP1CD54muLCTQBVwDTgFFACnCAd4HfAT8HngGOXfj/hRAVzgJmA3cCzwJnUBf3
QP9OAU8BnwMmIjcJISpaM/BfgTe59EV/qX+/Az4FZAEMCQVCVJQ5wMNAnsFf/Bf/9QPfBMb5fTBC
CH1LUY/7Q73wP/rvR8BUvw9KCFHYVNRAXqku/ov/HgJa/T44IcSlhYCvUvqL/+K/P/P7AIUQl7YO
eA/3AsDLqGlEIUSZSQP34d7Ff/HfV4CA3wcrhPiw/UAfg7iYTRPHNAYdAN4BVvh9sKJ4EsWrRyvQ
AwR1Grc1Bdm5NsW8qVH6cw4PP3mabzxwkmPv5nQ+bl/4W4+jEoeEED77DJp38AmjQs5jf9/u5H85
2XGem+I4z01xcs9Mdr71123OsLqA7lPAaWCX3wctimP53QFRElcAd6DGAC4rYBl89nAj29amMPKo
FKG8yvcdPzrMseP9/PCpMzp/M4jKMrwbFQxEBTL97oAoWhA4DIzQabxkdozd61OQ//g6H8OAG3dm
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'))
	#endregion
	$form_SystemUpdate.Icon = $Formatter_binaryFomatter.Deserialize($System_IO_MemoryStream)
	$Formatter_binaryFomatter = $null
	$System_IO_MemoryStream = $null
	$form_SystemUpdate.MaximizeBox = $False
	$form_SystemUpdate.MinimizeBox = $False
	$form_SystemUpdate.Name = 'form_SystemUpdate'
	$form_SystemUpdate.SizeGripStyle = 'Hide'
	$form_SystemUpdate.StartPosition = 'Manual'
	$form_SystemUpdate.Text = $PromptTitle
	$form_SystemUpdate.TopMost = $True
	$form_SystemUpdate.add_Load($form_SystemUpdate_Load)
	#
	# combobox_delaytime
	#
	$combobox_delaytime.BackColor = [System.Drawing.Color]::WhiteSmoke 
	$combobox_delaytime.Cursor = 'Hand'
	$combobox_delaytime.DropDownStyle = 'DropDownList'
	$combobox_delaytime.FormattingEnabled = $True
	[void]$combobox_delaytime.Items.Add('5 Minutes')
	[void]$combobox_delaytime.Items.Add('10 Minutes')
	[void]$combobox_delaytime.Items.Add('15 Minutes')
	[void]$combobox_delaytime.Items.Add('30 Minutes')
	[void]$combobox_delaytime.Items.Add('1 Hour')
	[void]$combobox_delaytime.Items.Add('2 Hours')
	$combobox_delaytime.Location = New-Object System.Drawing.Point(12, 129)
	$combobox_delaytime.Name = 'combobox_delaytime'
	$combobox_delaytime.Size = New-Object System.Drawing.Size(204, 21)
	$combobox_delaytime.TabIndex = 5
	$combobox_delaytime.add_SelectedIndexChanged($combobox_delaytime_SelectedIndexChanged)
	#
	# buttonDelayReboot
	#
	$buttonDelayReboot.BackColor = [System.Drawing.Color]::WhiteSmoke 
	$buttonDelayReboot.Cursor = 'Hand'
	$buttonDelayReboot.Location = New-Object System.Drawing.Point(222, 116)
	$buttonDelayReboot.Name = 'buttonDelayReboot'
	$buttonDelayReboot.Size = New-Object System.Drawing.Size(106, 44)
	$buttonDelayReboot.TabIndex = 4
	$buttonDelayReboot.Text = 'Delay Reboot'
	$buttonDelayReboot.UseVisualStyleBackColor = $False
	$buttonDelayReboot.add_Click($buttonDelayReboot_Click)
	#
	# button_RebootNow
	#
	$button_RebootNow.BackColor = [System.Drawing.Color]::WhiteSmoke 
	$button_RebootNow.Cursor = 'Hand'
	$button_RebootNow.Location = New-Object System.Drawing.Point(334, 116)
	$button_RebootNow.Name = 'button_RebootNow'
	$button_RebootNow.Size = New-Object System.Drawing.Size(106, 44)
	$button_RebootNow.TabIndex = 3
	$button_RebootNow.Text = 'Reboot Now'
	$button_RebootNow.UseVisualStyleBackColor = $False
	$button_RebootNow.add_Click($button_RebootNow_Click)
	#
	# labelAnImportantUpdateHas
	#
	$labelAnImportantUpdateHas.BackColor = [System.Drawing.Color]::FromArgb(255, 224, 224, 224)
	$labelAnImportantUpdateHas.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '11.25')
	$labelAnImportantUpdateHas.ForeColor = [System.Drawing.Color]::Black 
	$labelAnImportantUpdateHas.Location = New-Object System.Drawing.Point(12, 13)
	$labelAnImportantUpdateHas.Name = 'labelAnImportantUpdateHas'
	$labelAnImportantUpdateHas.Size = New-Object System.Drawing.Size(418, 100)
	$labelAnImportantUpdateHas.TabIndex = 2
	$labelAnImportantUpdateHas.Text = $PromptMessage
	$labelAnImportantUpdateHas.TextAlign = 'MiddleCenter'
	$form_SystemUpdate.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $form_SystemUpdate.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$form_SystemUpdate.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$form_SystemUpdate.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $form_SystemUpdate.ShowDialog()

} #End Function

#Call the form
Show-Reboot-Required-Prompt_psf *> "C:\Windows\temp\rebootprompt.txt"
