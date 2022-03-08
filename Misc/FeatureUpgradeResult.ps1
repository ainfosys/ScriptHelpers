function Show-Upgrade-Result_psf {

	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Windows.Forms.DataVisualization, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form_UpgradeResult = New-Object 'System.Windows.Forms.Form'
	$Label_Error = New-Object 'System.Windows.Forms.Label'
	$label_endcontent = New-Object 'System.Windows.Forms.Label'
	$labelEndTimeIncludingRebo = New-Object 'System.Windows.Forms.Label'
	$label_startcontent = New-Object 'System.Windows.Forms.Label'
	$label_start = New-Object 'System.Windows.Forms.Label'
	$label_resultcontent = New-Object 'System.Windows.Forms.Label'
	$label_Result = New-Object 'System.Windows.Forms.Label'
	$buttonOK = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$form_UpgradeResult_Load={
		$RegKey = "HKLM:\SOFTWARE\FeatureUpgrade"
		if (Test-Path $RegKey)
		{
			[DateTime]$LastReboot = Get-CimInstance -ClassName Win32_OperatingSystem | Select -expand LastBootUpTime
			
			$PreviousRun = @{
				Start = Get-ItemProperty -Path $RegKey -Name "Start" | Select-Object -ExpandProperty "Start"
				End   = Get-ItemProperty -Path $RegKey -Name "End" | Select-Object -ExpandProperty "End"
				Method = Get-ItemProperty -Path $RegKey -Name "Method" | Select-Object -ExpandProperty "Method"
				LogLocation = Get-ItemProperty -Path $RegKey -Name "LogLocation" | Select-Object -ExpandProperty "LogLocation"
				Result = Get-ItemProperty -Path $RegKey -Name "Result" | Select-Object -ExpandProperty "Result"
			}
			
			if ($PreviousRun.result -ieq "Success")
			{
				$label_resultcontent.Text = "Success"
				$form_UpgradeResult.BackColor = 'SpringGreen'
				$label_startcontent.Text = $PreviousRun.Start
				$label_endcontent.Text = $LastReboot
			}
			else
			{
				$label_resultcontent.Text = "Failure"
				$form_UpgradeResult.BackColor = 'LightSalmon'
				$label_startcontent.Visible = $false
				$label_endcontent.Visible = $false
				$Label_Error.Visible = $true
			}
		}
		else
		{
			$label_resultcontent.Text = "Failure"
			$form_UpgradeResult.BackColor = 'LightSalmon'
			$label_startcontent.Visible = $false
			$label_endcontent.Visible = $false
			$Label_Error.Visible = $true
		}
	}
	
	$buttonOK_Click = {
		Disable-ScheduledTask -TaskName "Result-Prompt" -ErrorAction SilentlyContinue
		Unregister-ScheduledTask -TaskName "Result-Prompt" -ErrorAction SilentlyContinue
		$form_UpgradeResult.Close()
	}
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$form_UpgradeResult.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$buttonOK.remove_Click($buttonOK_Click)
			$form_UpgradeResult.remove_Load($form_UpgradeResult_Load)
			$form_UpgradeResult.remove_Load($Form_StateCorrection_Load)
			$form_UpgradeResult.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch { Out-Null <# Prevent PSScriptAnalyzer warning #> }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$form_UpgradeResult.SuspendLayout()
	#
	# form_UpgradeResult
	#
	$form_UpgradeResult.Controls.Add($Label_Error)
	$form_UpgradeResult.Controls.Add($label_endcontent)
	$form_UpgradeResult.Controls.Add($labelEndTimeIncludingRebo)
	$form_UpgradeResult.Controls.Add($label_startcontent)
	$form_UpgradeResult.Controls.Add($label_start)
	$form_UpgradeResult.Controls.Add($label_resultcontent)
	$form_UpgradeResult.Controls.Add($label_Result)
	$form_UpgradeResult.Controls.Add($buttonOK)
	$form_UpgradeResult.AutoScaleDimensions = New-Object System.Drawing.SizeF(8, 17)
	$form_UpgradeResult.AutoScaleMode = 'Font'
	$form_UpgradeResult.AutoSize = $True
	$form_UpgradeResult.ClientSize = New-Object System.Drawing.Size(389, 263)
	$form_UpgradeResult.Name = 'form_UpgradeResult'
	$form_UpgradeResult.StartPosition = 'CenterScreen'
	$form_UpgradeResult.Text = 'Upgrade Result'
	$form_UpgradeResult.add_Load($form_UpgradeResult_Load)
	#
	# Label_Error
	#
	$Label_Error.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '10.2')
	$Label_Error.Location = New-Object System.Drawing.Point(24, 75)
	$Label_Error.Margin = '4, 0, 4, 0'
	$Label_Error.Name = 'Label_Error'
	$Label_Error.Size = New-Object System.Drawing.Size(327, 113)
	$Label_Error.TabIndex = 7
	$Label_Error.Text = 'Something went wrong during the upgrade and the process will need to run again.'
	$Label_Error.TextAlign = 'MiddleCenter'
	$Label_Error.Visible = $False
	#
	# label_endcontent
	#
	$label_endcontent.AutoSize = $True
	$label_endcontent.Location = New-Object System.Drawing.Point(309, 147)
	$label_endcontent.Margin = '4, 0, 4, 0'
	$label_endcontent.Name = 'label_endcontent'
	$label_endcontent.Size = New-Object System.Drawing.Size(30, 17)
	$label_endcontent.TabIndex = 6
	$label_endcontent.Text = 'null'
	#
	# labelEndTimeIncludingRebo
	#
	$labelEndTimeIncludingRebo.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '10.2')
	$labelEndTimeIncludingRebo.Location = New-Object System.Drawing.Point(42, 145)
	$labelEndTimeIncludingRebo.Margin = '4, 0, 4, 0'
	$labelEndTimeIncludingRebo.Name = 'labelEndTimeIncludingRebo'
	$labelEndTimeIncludingRebo.Size = New-Object System.Drawing.Size(259, 29)
	$labelEndTimeIncludingRebo.TabIndex = 5
	$labelEndTimeIncludingRebo.Text = 'End time (Including reboot time):'
	#
	# label_startcontent
	#
	$label_startcontent.AutoSize = $True
	$label_startcontent.Location = New-Object System.Drawing.Point(152, 98)
	$label_startcontent.Margin = '4, 0, 4, 0'
	$label_startcontent.Name = 'label_startcontent'
	$label_startcontent.Size = New-Object System.Drawing.Size(30, 17)
	$label_startcontent.TabIndex = 4
	$label_startcontent.Text = 'null'
	#
	# label_start
	#
	$label_start.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '10.2')
	$label_start.Location = New-Object System.Drawing.Point(42, 96)
	$label_start.Margin = '4, 0, 4, 0'
	$label_start.Name = 'label_start'
	$label_start.Size = New-Object System.Drawing.Size(102, 29)
	$label_start.TabIndex = 3
	$label_start.Text = 'Start time:'
	#
	# label_resultcontent
	#
	$label_resultcontent.AutoSize = $True
	$label_resultcontent.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '12')
	$label_resultcontent.Location = New-Object System.Drawing.Point(277, 35)
	$label_resultcontent.Margin = '4, 0, 4, 0'
	$label_resultcontent.Name = 'label_resultcontent'
	$label_resultcontent.Size = New-Object System.Drawing.Size(42, 25)
	$label_resultcontent.TabIndex = 2
	$label_resultcontent.Text = 'null'
	#
	# label_Result
	#
	$label_Result.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '12', [System.Drawing.FontStyle]'Bold')
	$label_Result.Location = New-Object System.Drawing.Point(13, 19)
	$label_Result.Margin = '4, 0, 4, 0'
	$label_Result.Name = 'label_Result'
	$label_Result.Size = New-Object System.Drawing.Size(256, 56)
	$label_Result.TabIndex = 1
	$label_Result.Text = 'Results of OS Upgrade: '
	$label_Result.TextAlign = 'MiddleCenter'
	#
	# buttonOK
	#
	$buttonOK.Location = New-Object System.Drawing.Point(226, 192)
	$buttonOK.Margin = '4, 4, 4, 4'
	$buttonOK.Name = 'buttonOK'
	$buttonOK.Size = New-Object System.Drawing.Size(150, 58)
	$buttonOK.TabIndex = 0
	$buttonOK.Text = 'OK'
	$buttonOK.UseVisualStyleBackColor = $True
	$buttonOK.add_Click($buttonOK_Click)
	$form_UpgradeResult.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $form_UpgradeResult.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$form_UpgradeResult.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$form_UpgradeResult.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $form_UpgradeResult.ShowDialog()

} #End Function

[DateTime]$EndTime = Get-ItemProperty -Path $RegKey -Name "End" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "End"
[DateTime]$LastReboot = Get-CimInstance -ClassName Win32_OperatingSystem | Select -expand LastBootUpTime

if($LastReboot -lt $EndTime){
    #Call the form
    Show-Upgrade-Result_psf | Out-Null    
}