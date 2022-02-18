﻿#------------------------------------------------------------------------
# Source File Information (DO NOT MODIFY)
# Source ID: cea1290e-995e-4cba-a05b-c35063cb5322
# Source File: G:\ps-studios-forms\Reboot-Required-Prompt.psf
#------------------------------------------------------------------------

<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.191
     Generated on:       2/18/2022 12:39 PM
     Generated by:       Ryan
    --------------------------------------------------------------------------------
    .DESCRIPTION
        GUI script generated by PowerShell Studio 2021
#>


#----------------------------------------------
#region Application Functions
#----------------------------------------------

#endregion Application Functions

#----------------------------------------------
# Generated Form Function
#----------------------------------------------
function Show-Reboot-Required-Prompt_psf {

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
		
	}
	#region Control Helper Functions
	function Update-ComboBox
	{
	<#
		.SYNOPSIS
			This functions helps you load items into a ComboBox.
		
		.DESCRIPTION
			Use this function to dynamically load items into the ComboBox control.
		
		.PARAMETER ComboBox
			The ComboBox control you want to add items to.
		
		.PARAMETER Items
			The object or objects you wish to load into the ComboBox's Items collection.
		
		.PARAMETER DisplayMember
			Indicates the property to display for the items in this control.
			
		.PARAMETER ValueMember
			Indicates the property to use for the value of the control.
		
		.PARAMETER Append
			Adds the item(s) to the ComboBox without clearing the Items collection.
		
		.EXAMPLE
			Update-ComboBox $combobox1 "Red", "White", "Blue"
		
		.EXAMPLE
			Update-ComboBox $combobox1 "Red" -Append
			Update-ComboBox $combobox1 "White" -Append
			Update-ComboBox $combobox1 "Blue" -Append
		
		.EXAMPLE
			Update-ComboBox $combobox1 (Get-Process) "ProcessName"
		
		.NOTES
			Additional information about the function.
	#>
		
		param
		(
			[Parameter(Mandatory = $true)]
			[ValidateNotNull()]
			[System.Windows.Forms.ComboBox]
			$ComboBox,
			[Parameter(Mandatory = $true)]
			[ValidateNotNull()]
			$Items,
			[Parameter(Mandatory = $false)]
			[string]$DisplayMember,
			[Parameter(Mandatory = $false)]
			[string]$ValueMember,
			[switch]
			$Append
		)
		
		if (-not $Append)
		{
			$ComboBox.Items.Clear()
		}
		
		if ($Items -is [Object[]])
		{
			$ComboBox.Items.AddRange($Items)
		}
		elseif ($Items -is [System.Collections.IEnumerable])
		{
			$ComboBox.BeginUpdate()
			foreach ($obj in $Items)
			{
				$ComboBox.Items.Add($obj)
			}
			$ComboBox.EndUpdate()
		}
		else
		{
			$ComboBox.Items.Add($Items)
		}
		
		if ($DisplayMember)
		{
			$ComboBox.DisplayMember = $DisplayMember
		}
		
		if ($ValueMember)
		{
			$ComboBox.ValueMember = $ValueMember
		}
	}
	
	
	#endregion
	
	
	$form_SystemUpdate_FormClosed=[System.Windows.Forms.FormClosedEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.FormClosedEventArgs]
		
		#Write-Host $_.CloseReason
		
	}
	
	$button_RebootNow_Click={
		$oReturn = [System.Windows.Forms.MessageBox]::Show("Reboot and apply the system update now?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo)
		switch ($oReturn)
		{
			"YES" {
				Write-Host "User selected to reboot and confirmed selection. Rebooting now."
				Restart-Computer			
			}
		}
	}
	
	$buttonDelayReboot_Click={
		Write-Host "User selected to delay reboot prompt. Delayed $($combobox_delaytime.Text)"
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
			$form_SystemUpdate.remove_FormClosed($form_SystemUpdate_FormClosed)
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

	$form_SystemUpdate.Icon = $null
	$Formatter_binaryFomatter = $null
	$System_IO_MemoryStream = $null
	$form_SystemUpdate.MaximizeBox = $False
	$form_SystemUpdate.MinimizeBox = $False
	$form_SystemUpdate.Name = 'form_SystemUpdate'
	$form_SystemUpdate.SizeGripStyle = 'Hide'
	$form_SystemUpdate.StartPosition = 'Manual'
	$form_SystemUpdate.Text = 'System Update'
	$form_SystemUpdate.TopMost = $True
	$form_SystemUpdate.add_FormClosed($form_SystemUpdate_FormClosed)
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
	$labelAnImportantUpdateHas.Text = 'An important update has been applied to your computer. Please save an close any open work and press the "Reboot now" button to restart the computer. If now isn''t a good time select how long you would like to delay the reboot prompt and press the "Delay Reboot" button.'
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
Show-Reboot-Required-Prompt_psf | Out-Null