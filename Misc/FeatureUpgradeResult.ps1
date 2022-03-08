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
	$labelEndTime = New-Object 'System.Windows.Forms.Label'
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
		#Disable-ScheduledTask -TaskName "Result-Prompt" -ErrorAction SilentlyContinue
		#Unregister-ScheduledTask -TaskName "Result-Prompt" -ErrorAction SilentlyContinue
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
	$form_UpgradeResult.Controls.Add($labelEndTime)
	$form_UpgradeResult.Controls.Add($label_startcontent)
	$form_UpgradeResult.Controls.Add($label_start)
	$form_UpgradeResult.Controls.Add($label_resultcontent)
	$form_UpgradeResult.Controls.Add($label_Result)
	$form_UpgradeResult.Controls.Add($buttonOK)
	$form_UpgradeResult.AutoScaleDimensions = New-Object System.Drawing.SizeF(8, 17)
	$form_UpgradeResult.AutoScaleMode = 'Font'
	$form_UpgradeResult.AutoSize = $True
	$form_UpgradeResult.ClientSize = New-Object System.Drawing.Size(352, 263)
	$form_UpgradeResult.FormBorderStyle = 'Fixed3D'
	$form_UpgradeResult.MaximizeBox = $False
	$form_UpgradeResult.MinimizeBox = $False
	$form_UpgradeResult.Name = 'form_UpgradeResult'
	$form_UpgradeResult.ShowIcon = $False
	$form_UpgradeResult.SizeGripStyle = 'Hide'
	$form_UpgradeResult.StartPosition = 'CenterScreen'
	$form_UpgradeResult.Text = 'Upgrade Results'
	$form_UpgradeResult.add_Load($form_UpgradeResult_Load)
	#
	# Label_Error
	#
	$Label_Error.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '10.2')
	$Label_Error.Location = New-Object System.Drawing.Point(13, 75)
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
	$label_endcontent.Location = New-Object System.Drawing.Point(152, 149)
	$label_endcontent.Margin = '4, 0, 4, 0'
	$label_endcontent.Name = 'label_endcontent'
	$label_endcontent.Size = New-Object System.Drawing.Size(30, 17)
	$label_endcontent.TabIndex = 6
	$label_endcontent.Text = 'null'
	#
	# labelEndTime
	#
	$labelEndTime.Font = [System.Drawing.Font]::new('Microsoft Sans Serif', '10.2')
	$labelEndTime.Location = New-Object System.Drawing.Point(42, 147)
	$labelEndTime.Margin = '4, 0, 4, 0'
	$labelEndTime.Name = 'labelEndTime'
	$labelEndTime.Size = New-Object System.Drawing.Size(102, 27)
	$labelEndTime.TabIndex = 5
	$labelEndTime.Text = 'End time:'
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
	$label_resultcontent.Location = New-Object System.Drawing.Point(263, 35)
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
	$buttonOK.Location = New-Object System.Drawing.Point(190, 206)
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

Function InstallOrUpdateModule {
<#
.DESCRIPTION: Updates NuGet and PowershellGet if out of date and installs the provided module name if a module name is provided
.AUTHOR: Ryan
.NOTES:
    - This function was written to support the Powershell common parameter '-verbose'
    - If a module name is not provided only NuGet and PowershellGet will update if they are out of date
#>
    [cmdletbinding()]
    param
    (
	    [parameter(Mandatory = $false)]
        [String]
	    $ModuleName
    )
    # Variable used to check if the parameter was provided or not. $True means it contains something
    $ParamCheck = [bool]$ModuleName

    # Disable confirmation for installing modules and packages
    # more or less this is not needed when used with -Force
    Set-Variable -Name 'ConfirmPreference' -Value 'None' -Scope Script

    if($ParamCheck){
        Write-Verbose -Message "Provided module name is: $ModuleName"
    }
    else{
        Write-Verbose -Message "No module name is provided so only nuget and powershellget will be updated"
    }

    # Set TLS to 1.2 for this Powershell session. This will not work on Windows 7 or lower.
    Write-Verbose "Setting TLS protocol to 1.2 for this session. This may fail on older operating systems"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Determine if PackageManagement needs to be updated
    try{
       $LocalPackageMgmtVersion = Get-Package -Name PackageManagement -ErrorAction Stop | Select-Object -ExpandProperty Version
       $LatestPackageMgmtVersion = Find-Package -Name PackageManagement | Select-Object -ExpandProperty Version

       if($LocalPackageMgmtVersion -lt $LatestPackageMgmtVersion){
            Write-Verbose -Message "PackageManagement Version is out of date, updating it now"
            if($VerbosePreference -eq "Continue"){
                Install-Package -Name PackageManagement -Force -ErrorAction Stop -Verbose
            }
            else{
                Install-Package -Name PackageManagement -Force -ErrorAction Stop | Out-Null
            }
        }
    }
    Catch{
        # Reaching this part most likely caused by PackageManagent not being installed
        Write-Verbose -Message "PackageManagement not installed, installing it now"
        if($VerbosePreference -eq "Continue"){
             Install-Package -Name PackageManagement -Force -ErrorAction Stop -Verbose
         }
         else{
             Install-Package -Name PackageManagement -Force -ErrorAction Stop | Out-Null
         }
        
    }

    try{
        # Make sure package providers are up to date
        Write-Verbose "Checking local versions of PackageManagement, Nuget and PowershellGet against latest available"
        
        $LocalNugetVersion = Get-PackageProvider -Name nuget | Select-Object -ExpandProperty Version
        $LocalPowershellGetVersion = Get-PackageProvider -name PowershellGet | Select-Object -ExpandProperty Version
        $LatestNugetVersion = Find-PackageProvider -Name nuget -ErrorAction Stop | Select-Object -ExpandProperty Version
        $LatestPowershellGetVersion = Find-PackageProvider -name PowershellGet -ErrorAction Stop | Select-Object -ExpandProperty Version


        if($LocalNugetVersion -lt $LatestNugetVersion){
            
            Write-Verbose -Message "NuGet version is out of date, updating it now"
            if($VerbosePreference -eq "Continue"){
                Install-PackageProvider -Name NuGet -Force -ErrorAction Stop -Verbose
            }
            else{
                Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
            }
        }
    }
    Catch{
        Write-Output "Nuget or PackageManagement installation or check failed, consider rebooting and trying again or manually updating nuget/packagemanagement"
    }

    if($LocalPowershellGetVersion -lt $LatestPowershellGetVersion){
        Write-Verbose -Message "Attempting to update PowershellGet now"
        if($VerbosePreference -eq "Continue"){ 
            Install-Module -Name PowerShellGet -Force -Verbose
        }
        else{
            Install-Module -Name PowerShellGet -Force | Out-Null 
        }
    }

    if($ParamCheck){
            Write-Verbose -Message "Checking local system for desired module. Update if found out of date"
            if ($(Get-Module -ListAvailable | Select-Object -ExpandProperty Name) -inotcontains $ModuleName)
            {
                Write-Verbose -Message "Module not found on local system, installing it now"
                # if the module isn't found to be installed it will install it here
                if($VerbosePreference -eq "Continue"){
	                Install-Module -Name $ModuleName -Force -Verbose
                }
                else{
                    Install-Module -Name $ModuleName -Force | Out-Null
                }
            }
            elseif($(Get-Module -ListAvailable | Where-Object {$_.name -eq $ModuleName} | Select-Object -ExpandProperty Version) -lt $(Find-Module -name $ModuleName | Select-Object -ExpandProperty Version)){
                Write-Verbose -Message "Module found on local system but out of date, updating it now"
                if($VerbosePreference -eq "Continue"){
                    # The local version is out of date, update it here
                    Update-module -Name $ModuleName -Force -Verbose
                }
                else{
                    Update-module -Name $ModuleName -Force | Out-Null
                }
            }
            elseif($(Get-Module -ListAvailable | Where-Object {$_.name -eq $ModuleName} | Select-Object -ExpandProperty Version) -eq $(Find-Module -name $ModuleName | Select-Object -ExpandProperty Version)){
                Write-Output "Module already installed and on latest version"
                Write-Output "Local version: $(Get-Module -ListAvailable | Where-Object {$_.name -eq $ModuleName} | Select-Object -ExpandProperty Version)"
                Write-Output "Online version: $(Find-Module -name $ModuleName | Select-Object -ExpandProperty Version)"
            }
            Write-Verbose -Message "Importing module now"
            if($VerbosePreference -eq "Continue"){
                Import-Module -name $ModuleName -Verbose
            }
            else{
                Import-Module -Name $ModuleName | Out-Null
            }
    }
}

$RegKey = "HKLM:\SOFTWARE\FeatureUpgrade"
[DateTime]$EndTime = Get-ItemProperty -Path $RegKey -Name "End" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty "End"
[DateTime]$LastReboot = Get-CimInstance -ClassName Win32_OperatingSystem | Select -expand LastBootUpTime

if($LastReboot -lt $EndTime){

    if($(Get-module -ListAvailable).name -inotcontains "RunAsUser"){
        InstallOrUpdateModule -ModuleName "RunAsUser"
    }
    Invoke-AsCurrentUser -ScriptBlock {
    #Call the form
    Show-Upgrade-Result_psf | Out-Null
    } 
}