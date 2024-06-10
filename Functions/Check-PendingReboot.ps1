function Check-PendingReboot
{
	<#
	.DESCRIPTION: Checks various registry keys to determine if there is a pending reboot
	.NOTES: 
			-Includes a lot of checks that likely aren't needed but included regardless
			-By default pending file rename operations are excludes as they typically are true
	#>
	param
	(
		[parameter(Mandatory = $false)]
		[bool]$ExcludePendingFileRenames = $true
	)
	
	#region Functions
	function Test-IsGuid
	{
		[OutputType([bool])]
		param
		(
			[Parameter(Mandatory = $true)]
			[string]$StringGuid
		)
		
		$ObjectGuid = [System.Guid]::empty
		return [System.Guid]::TryParse($StringGuid, [System.Management.Automation.PSReference]$ObjectGuid) # Returns True if successfully parsed
	}
	#endregion
	
	#region Process pending reboot checks
	# Pending filename renames
	try
	{
		$RegKey = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Ignore | select -expand PendingFileRenameOperations
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$PendingFileRenames = $true
		}
		else
		{
			$PendingFileRenames = $false
		}
	}
	Catch
	{
		$PendingFileRenames = $false
	}
	
	# Pending Updates
	try
	{
		$RegKey = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Updates' -name "UpdateExeVolatile" -ErrorAction stop | Select -expand "UpdateExeVolatile"
		
		if ($RegKey -ne "0")
		{
			$PendingUpdates = $True
		}
	}
	Catch
	{
		# Error thrown so value doesn't exist.
		$PendingUpdates = $false
	}
	
	# Pending file renames (2)
	try
	{
		$RegKey = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -name "PendingFileRenameOperations2" -ErrorAction stop | Select -expand "PendingFileRenameOperations2"
		$boolCheck = [bool]$RegKey
		if ($RegKey -ne "0")
		{
			$PendingFileRenames2 = $True
		}
		else
		{
			$PendingFileRenames2 = $False
		}
	}
	Catch
	{
		# Error thrown so value doesn't exist.
		$PendingFileRenames2 = $false
	}
	
	# Win Updates reboot required flag
	if (Test-path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")
	{
		$PendingWinUpdate = $true
	}
	else
	{
		$PendingWinUpdate = $false
	}
	
	# Win Updates (2)
	try
	{
		$RegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\Pending" -ErrorAction stop
		$VarProperties = $RegKey | Get-Member -ErrorAction Stop | Where { $_.membertype -eq "NoteProperty" }
		$FilteredProperties = $VarProperties | Where { $_.name -ine "PSDrive" -and $_.name -ine "PSParentPath" -and $_.name -ine "PSPath" -and $_.name -ine "PSProvider" -and $_.name -ine "PSChildName" }
		# loop through properties on variable and check if any values are a GUID
		foreach ($property in $FilteredProperties)
		{
			$PropertyName = $property | select -expand Name
			$GUIDCheck = Test-IsGuid -StringGuid $($RegKey.$($PropertyName))
			if ($GUIDCheck)
			{
				$PendingWinUpdate2 = $true
			}
		}
	}
	catch
	{
		$PendingWinUpdate2 = $false
	}
	
	# Win Updates (3)
	if (Test-path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\PostRebootReporting")
	{
		$PendingWinUpdate3 = $True
	}
	else
	{
		$PendingWinUpdate3 = $False
	}
	
	# DVD Reboot Signal
	try
	{
		$RegKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "DVDRebootSignal" -ErrorAction Stop | select -expand DVDRebootSignal
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$DVDRebootSignal = $True
		}
		else
		{
			$DVDRebootSignal = $False
		}
	}
	Catch
	{
		$DVDRebootSignal = $False
	}
	
	# Component servicing pending reboot
	if (Test-path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending")
	{
		$ComponentServicing = $true
	}
	else
	{
		$ComponentServicing = $false
	}
	
	# Component servicing pending reboot (2)
	if (Test-path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress")
	{
		$ComponentServicing2 = $true
	}
	else
	{
		$ComponentServicing2 = $false
	}
	
	# Component servicing pending packages
	if (Test-path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending")
	{
		$PendingPackages = $true
	}
	else
	{
		$PendingPackages = $false
	}
	
	# server mgr reboot attempts
	if (Test-path "HKLM:\SOFTWARE\Microsoft\ServerManager\CurrentRebootAttempts")
	{
		$SvrMgrReboot = $true
	}
	else
	{
		$SvrMgrReboot = $false
	}
	
	# Pending Domain Join
	try
	{
		$regkey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Name "JoinDomain" -ErrorAction Stop | Select -expand JoinDomain
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$PendingDomainJoin = $True
		}
		else
		{
			$PendingDomainJoin = $false
		}
	}
	catch
	{
		$PendingDomainJoin = $false
	}
	
	# Netlogon AvoidSpnSet
	try
	{
		$regkey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon" -Name "AvoidSpnSet" -ErrorAction Stop | Select -expand AvoidSpnSet
		$boolCheck = [bool]$RegKey
		if ($boolCheck)
		{
			$AvoidSpnSet = $True
		}
		else
		{
			$AvoidSpnSet = $false
		}
	}
	catch
	{
		$AvoidSpnSet = $false
	}
	
	# Pending computer name change
	try
	{
		$CurrentPCname = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName" -Name "ComputerName" -ErrorAction stop | select -expand ComputerName
		$PendingPCName = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName" -Name "ComputerName" -ErrorAction Stop | select -expand ComputerName
		
		if ($PendingPCName -ine $CurrentPCname)
		{
			$PCNameChange = $True
		}
		else
		{
			$PCNameChange = $false
		}
	}
	catch
	{
		$PCNameChange = $false
	}
	
	# consider adding SCCM reboot checks here. Maybe add automate reboot flags if any are unique
	#endregion
	
	#region Return information
	
	if ($ExcludePendingFileRenames)
	{
		$PendingReboot = $PendingUpdates -or `
		$PendingWinUpdate -or `
		$PendingWinUpdate2 -or `
		$PendingWinUpdate3 -or `
		$DVDRebootSignal -or `
		$ComponentServicing -or `
		$ComponentServicing2 -or `
		$PendingPackages -or `
		$SvrMgrReboot -or `
		$PendingDomainJoin -or `
		$AvoidSpnSet -or `
		$PCNameChange -or `
		$PendingDomainJoin
		
		[PSCustomObject]@{
			ComputerName				    = $ENV:ComputerName
			ComponentBasedServicing		    = $ComponentServicing
			ComponentBasedServicing2	    = $ComponentServicing2
			PendingComputerRenameDomainJoin = $PendingDomainJoin
			PendingWindowsUpdate		    = $PendingWinUpdate
			PendingWindowsUpdate2		    = $PendingWinUpdate2
			PendingWindowsUpdate3		    = $PendingWinUpdate3
			DVDRebootSignal				    = $DVDRebootSignal
			PendingPackages				    = $PendingPackages
			ServerManagerReboots		    = $SvrMgrReboot
			PendingDomainJoin			    = $PendingDomainJoin
			AvoidSpnSet					    = $AvoidSpnSet
			PendingNameChange			    = $PCNameChange
			PendingReboot				    = $PendingReboot
		}
	}
	else
	{
		$PendingReboot = $PendingFileRenames -or `
		$PendingUpdates -or `
		$PendingFileRenames2 -or `
		$PendingWinUpdate -or `
		$PendingWinUpdate2 -or `
		$PendingWinUpdate3 -or `
		$DVDRebootSignal -or `
		$ComponentServicing -or `
		$ComponentServicing2 -or `
		$PendingPackages -or `
		$SvrMgrReboot -or `
		$PendingDomainJoin -or `
		$AvoidSpnSet -or `
		$PCNameChange -or `
		$PendingDomainJoin
		
		[PSCustomObject]@{
			ComputerName				    = $ENV:ComputerName
			ComponentBasedServicing		    = $ComponentServicing
			ComponentBasedServicing2	    = $ComponentServicing2
			PendingComputerRenameDomainJoin = $PendingDomainJoin
			PendingFileRenameOperations	    = $PendingFileRenames
			PendingFileRenameOperations2    = $PendingFileRenames2
			PendingWindowsUpdate		    = $PendingWinUpdate
			PendingWindowsUpdate2		    = $PendingWinUpdate2
			PendingWindowsUpdate3		    = $PendingWinUpdate3
			DVDRebootSignal				    = $DVDRebootSignal
			PendingPackages				    = $PendingPackages
			ServerManagerReboots		    = $SvrMgrReboot
			PendingDomainJoin			    = $PendingDomainJoin
			AvoidSpnSet					    = $AvoidSpnSet
			PendingNameChange			    = $PCNameChange
			PendingReboot				    = $PendingReboot
		}
	}
	#endregion
}
# SIG # Begin signature block
# MIIr+QYJKoZIhvcNAQcCoIIr6jCCK+YCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAfCeMTI9wqbBRk
# jYX32M99A5v76XTKCOFImhrlcl7OxKCCJRAwggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggWNMIIEdaADAgECAhAOmxiO
# +dAt5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAi
# BgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAw
# MDBaFw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERp
# Z2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCC
# AgoCggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsb
# hA3EMB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iT
# cMKyunWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGb
# NOsFxl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclP
# XuU15zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCr
# VYJBMtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFP
# ObURWBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTv
# kpI6nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWM
# cCxBYKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls
# 5Q5SUUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBR
# a2+xq4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6
# MIIBNjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qY
# rhwPTzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8E
# BAMCAYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDig
# NoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCg
# v0NcVec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQT
# SnovLbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh
# 65ZyoUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSw
# uKFWjuyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAO
# QGPFmCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjD
# TZ9ztwGpn1eqXijiuZQwggYaMIIEAqADAgECAhBiHW0MUgGeO5B5FSCJIRwKMA0G
# CSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExp
# bWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBSb290
# IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5NTlaMFQxCzAJBgNVBAYT
# AkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28g
# UHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0GCSqGSIb3DQEBAQUAA4IB
# jwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjIztNsfvxYB5UXeWUzCxEe
# AEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NVDgFigOMYzB2OKhdqfWGV
# oYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/36F09fy1tsB8je/RV0mIk
# 8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05ZwmRmTnAO5/arnY83jeNzh
# P06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm+qxp4VqpB3MV/h53yl41
# aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUedyz8rNyfQJy/aOs5b4s+
# ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz44MPZ1f9+YEQIQty/NQd/
# 2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBMdlyh2n5HirY4jKnFH/9g
# Rvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQYMBaAFDLrkpr/NZZILyhA
# QnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritUpimqF6TNDDAOBgNVHQ8B
# Af8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcD
# AzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsGA1UdHwREMEIwQKA+oDyG
# Omh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5n
# Um9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsGAQUFBzAChjpodHRwOi8v
# Y3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RSNDYu
# cDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG
# 9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURhw1aVcdGRP4Wh60BAscjW
# 4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0ZdOaWTsyNyBBsMLHqafvIh
# rCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajjcw5+w/KeFvPYfLF/ldYp
# mlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNcWbWDRF/3sBp6fWXhz7Dc
# ML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalOhOfCipnx8CaLZeVme5yE
# Lg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJszkyeiaerlphwoKx1uHRz
# NyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z76mKnzAfZxCl/3dq3dUNw
# 4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5JKdGvspbOrTfOXyXvmPL6
# E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHHj95Ejza63zdrEcxWLDX6
# xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2Bev6SivBBOHY+uqiirZt
# g0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/L9Uo2bC5a4CH2RwwggZy
# MIIE2qADAgECAhEA+MlWJqsYGCkMn5RD9FeGaDANBgkqhkiG9w0BAQwFADBUMQsw
# CQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJT
# ZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2MB4XDTI0MDUxNjAwMDAw
# MFoXDTI1MDUxNjIzNTk1OVowaDELMAkGA1UEBhMCVVMxETAPBgNVBAgMCE1hcnls
# YW5kMSIwIAYDVQQKDBlBbGxpYW5jZSBJbmZvU3lzdGVtcywgTExDMSIwIAYDVQQD
# DBlBbGxpYW5jZSBJbmZvU3lzdGVtcywgTExDMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEAw5y17GI26wcQjXf7AwPsXD66VRrROUfBUJZPVFzM18rfECDP
# mFY6OV3hNKG/Jj1Tpm3Ukuci3j+WVkP8rJox41IhpDNAUXySfB9P4llfFoo5Xfy3
# w11hGfcBG+T3gmp92WRWo+GexZfxEyGxsQE0cGaOoZaHOvHvvqQBhnFaaYTWGyDF
# JHbsUy9JFcjgIl0aVSFp7VHkawYEs6lPp4qFr9ANOqY1TGcfHl1y5VhkH7h4rKDh
# +Zc9w1/f5QiUNivPrg4tYCQkGg3OHidCKRYNGrdq6LpKLWSad4ExE2+8q+GC4KIF
# rP5YEMjbig+sBeYgvNOogMVHLlbemIA5WJNbcsMzUHnd7GY5B1xZbvZlSuY+L4BN
# 0hIZtKFuRKrAtDtg/Aq1Iu8j+tBOo4SzspAXie+Mx9Lh33VYE8jLE6am+GDmqeuY
# GtjrG2hQViFWomUypwk3xNuZ5Nbl5ItjK4PhoMydggOQEGjgnZ+BvbAwdTXggHfb
# UdEQMeMXIT7beO1Ufzq2b3+LlHpOoDaijaWkOTBSZbOmAW5D/+3SeL0v81i3V1bn
# IxgpVwZ5nHkgAUnQXKWGZ6v56OqUQAuEUU2YEVM+OQ9gXSB1zjg9kCqnYdw5wyFa
# LiLaV8wMdeM/eL58cwT7C6Ik5o35kqqFdGRdQ6m5ZLVphBi1qshqfZHuLtkCAwEA
# AaOCAakwggGlMB8GA1UdIwQYMBaAFA8qyyCHKLjsb0iuK1SmKaoXpM0MMB0GA1Ud
# DgQWBBQLEziWPEW1/HQnbIUA6gbqHO4I9jAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0T
# AQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzBKBgNVHSAEQzBBMDUGDCsGAQQB
# sjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAI
# BgZngQwBBAEwSQYDVR0fBEIwQDA+oDygOoY4aHR0cDovL2NybC5zZWN0aWdvLmNv
# bS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5jcmwweQYIKwYBBQUHAQEE
# bTBrMEQGCCsGAQUFBzAChjhodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29Q
# dWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29j
# c3Auc2VjdGlnby5jb20wHgYDVR0RBBcwFYETY3Rvd2xlQGFpbmZvc3lzLmNvbTAN
# BgkqhkiG9w0BAQwFAAOCAYEALqn1PnrjV4wMqnA1VrSrqnlbZ1TkbM65lCltrY/S
# P91s4FdiUWC330CHJgVQ/j+PmLtXYAI+IKVEVHMZ/ZBeMecpxsR121Lv4B0gAzd+
# xpKULKsxrNW5BQLksBeGCWrVUvAEOr5CdaoccnJqCqBPsE4brLWT0wjNz7EFdeB4
# sc82kthwBUsbHUZfcl1wXPlTbDhahIrUB/PEVM9twBwAZ7vOaft1QVhkeesQGeSh
# 1dEHuS5JUnIdU/DEQj+tUG2EfL0fhhaVXj2SeXxnCAFVCUTk/O/ieYLH8M0v1kUS
# fGZpwJSbjoUUTlD7FOs1ogLhz8WW21Beso3SdOHAqTFc2e9F3Mkif1g3synHom/c
# kKC+fNGqSa+cfMLzirfKH+DLn9T71J+jRejLu8cwkdLNtcrLctB/WFnNX9kf43wV
# eCexOXLEExNdzdi9uCWzTcVRwjXVmWbnXdA84KSLGKui5XHsZNUz2PISysxalyxv
# pMoKrbC+oGFYF3vkXw2B329yMIIGrjCCBJagAwIBAgIQBzY3tyRUfNhHrP0oZipe
# WzANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNl
# cnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdp
# Q2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1
# OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5
# BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0
# YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxoY1Bkmz
# wT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyibaCwzIP5WvYRoUQVQl+kiPNo+n3znIkL
# f50fng8zH1ATCyZzlm34V6gCff1DtITaEfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C
# 3GeO6lE98NZW1OcoLevTsbV15x8GZY2UKdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5
# n12sy+iEZLRS8nZH92GDGd1ftFQLIWhuNyG7QKxfst5Kfc71ORJn7w6lY2zkpsUd
# zTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15/tePc5OsLDnipUjW8LAxE6lXKZYnLvWH
# po9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4nJZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/
# oN7jPqJz+ucfWmyU8lKVEStYdEAoq3NDzt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPV
# A+C/8KI8ykLcGEh/FDTP0kyr75s9/g64ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg
# 0ixXNXkrqPNFYLwjjVj33GHek/45wPmyMKVM1+mYSlg+0wOI/rOP015LdhJRk8mM
# DDtbiiKowSYI+RQQEgN9XyO7ZONj4KbhPvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6E
# VO7O6V3IXjASvUaetdN2udIOa5kM0jO0zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW2W1NhS9zKXaaL3WMaiCPnshvMB8GA1Ud
# IwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0f
# BDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcB
# MA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7Ak7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBT
# zr8Y+8dQXeJLKftwig2qKWn8acHPHQfpPmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/E
# UExiHQwIgqgWvalWzxVzjQEiJc6VaT9Hd/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fm
# niye4Iqs5f2MvGQmh2ySvZ180HAKfO+ovHVPulr3qRCyXen/KFSJ8NWKcXZl2szw
# cqMj+sAngkSumScbqyQeJsG33irr9p6xeZmBo1aGqwpFyd/EjaDnmPv7pp1yr8TH
# wcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/
# JWOZJyw9P2un8WbDQc1PtkCbISFA0LcTJM3cHXg65J6t5TRxktcma+Q4c6umAU+9
# Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHdI/0dKNPH+ejxmF/7K9h+8kaddSweJywm
# 228Vex4Ziza4k9Tm8heZWcpw8De/mADfIBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVB
# tzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE+oLeMt8EifAAzV3C+dAjfwAL5HYCJtnw
# ZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A+sDyDivl1vupL0QVSucTDh3bNzgaoSv2
# 7dZ8/DCCBsIwggSqoAMCAQICEAVEr/OUnQg5pr/bP1/lYRYwDQYJKoZIhvcNAQEL
# BQAwYzELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYD
# VQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFt
# cGluZyBDQTAeFw0yMzA3MTQwMDAwMDBaFw0zNDEwMTMyMzU5NTlaMEgxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjEgMB4GA1UEAxMXRGlnaUNl
# cnQgVGltZXN0YW1wIDIwMjMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQCjU0WHHYOOW6w+VLMj4M+f1+XS512hDgncL0ijl3o7Kpxn3GIVWMGpkxGnzaqy
# at0QKYoeYmNp01icNXG/OpfrlFCPHCDqx5o7L5Zm42nnaf5bw9YrIBzBl5S0pVCB
# 8s/LB6YwaMqDQtr8fwkklKSCGtpqutg7yl3eGRiF+0XqDWFsnf5xXsQGmjzwxS55
# DxtmUuPI1j5f2kPThPXQx/ZILV5FdZZ1/t0QoRuDwbjmUpW1R9d4KTlr4HhZl+NE
# K0rVlc7vCBfqgmRN/yPjyobutKQhZHDr1eWg2mOzLukF7qr2JPUdvJscsrdf3/Du
# dn0xmWVHVZ1KJC+sK5e+n+T9e3M+Mu5SNPvUu+vUoCw0m+PebmQZBzcBkQ8ctVHN
# qkxmg4hoYru8QRt4GW3k2Q/gWEH72LEs4VGvtK0VBhTqYggT02kefGRNnQ/fztFe
# jKqrUBXJs8q818Q7aESjpTtC/XN97t0K/3k0EH6mXApYTAA+hWl1x4Nk1nXNjxJ2
# VqUk+tfEayG66B80mC866msBsPf7Kobse1I4qZgJoXGybHGvPrhvltXhEBP+YUcK
# jP7wtsfVx95sJPC/QoLKoHE9nJKTBLRpcCcNT7e1NtHJXwikcKPsCvERLmTgyyIr
# yvEoEyFJUX4GZtM7vvrrkTjYUQfKlLfiUKHzOtOKg8tAewIDAQABo4IBizCCAYcw
# DgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYB
# BQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMB8GA1UdIwQY
# MBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQWBBSltu8T5+/N0GSh1Vap
# ZTGj3tXjSTBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5nQ0Eu
# Y3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3Au
# ZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8vY2FjZXJ0cy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2VGltZVN0YW1waW5n
# Q0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCBGtbeoKm1mBe8cI1PijxonNgl/8ss
# 5M3qXSKS7IwiAqm4z4Co2efjxe0mgopxLxjdTrbebNfhYJwr7e09SI64a7p8Xb3C
# YTdoSXej65CqEtcnhfOOHpLawkA4n13IoC4leCWdKgV6hCmYtld5j9smViuw86e9
# NwzYmHZPVrlSwradOKmB521BXIxp0bkrxMZ7z5z6eOKTGnaiaXXTUOREEr4gDZ6p
# RND45Ul3CFohxbTPmJUaVLq5vMFpGbrPFvKDNzRusEEm3d5al08zjdSNd311RaGl
# WCZqA0Xe2VC1UIyvVr1MxeFGxSjTredDAHDezJieGYkD6tSRN+9NUvPJYCHEVkft
# 2hFLjDLDiOZY4rbbPvlfsELWj+MXkdGqwFXjhr+sJyxB0JozSqg21Llyln6XeThI
# X8rC3D0y33XWNmdaifj2p8flTzU8AL2+nCpseQHc2kTmOt44OwdeOVj0fHMxVaCA
# EcsUDH6uvP6k63llqmjWIso765qCNVcoFstp8jKastLYOrixRoZruhf9xHdsFWyu
# q69zOuhJRrfVf8y2OMDY7Bz1tqG4QyzfTkx9HmhwwHcK1ALgXGC7KP845VJa1qwX
# IiNO9OzTF/tQa/8Hdx9xl0RBybhG02wyfFgvZ0dl5Rtztpn5aywGRu9BHvDwX+Db
# 2a2QgESvgBBBijGCBj8wggY7AgEBMGkwVDELMAkGA1UEBhMCR0IxGDAWBgNVBAoT
# D1NlY3RpZ28gTGltaXRlZDErMCkGA1UEAxMiU2VjdGlnbyBQdWJsaWMgQ29kZSBT
# aWduaW5nIENBIFIzNgIRAPjJViarGBgpDJ+UQ/RXhmgwDQYJYIZIAWUDBAIBBQCg
# gYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQgoN6iB0dZhlQ5JibdWm1Tiw2F6cI7R15DWsC412fBCIQwDQYJKoZIhvcN
# AQEBBQAEggIAhL4sB/MOOhcHS+qxmwRZBUkzhYYbHrsEqZFPKmd9wXddgObXqIrU
# dramMHmfe7hMmPAsRgN21xaCgOksBBXmbcSMxo4bK9U/DnbUBwc7Q6ep2+j5FlLz
# mNwsoT7yHp/mYlAe6rpoxhTaHtMrd4SyitV9u1S8tFy1NLlCWO0sgDIGY5qd7HqI
# +XYfrTRX8mX2hmpFoQ81mqvp+NKdHFAahrLhSLtWVDE/bATgxMF5gaXWrRR4oArI
# MW0zPGhSDS+FTCYnh9U0yuG4CImhDzE2NTs7aPR9xS4ONaTu2u+5gHRSayy7jytb
# 0OQBGsafIk6o8u6lA+G9BkaeESb5kPdJ6fHE5iaKNYTrJXaJUnjtGKAWybyK3nt6
# JyTKK0MR8yYtNn1LE9ESwGzBDR4RUdCFTd6ImJht7mDmApPVbjL4LVrb16UZKTmw
# ELTLXCOYO4dx83mKAdIWBhsZw/DvAWe4FA7bpU7yq0traFFLCmz9DRnMMNZjoctd
# kCTek3G+5F9G/AcZr8g0txHFaFCyjsQS24uKNFpX406+rWS/oKEL6Ba2ICfBsnnr
# cNvrHItQu8VKBECFyio3ME2dNYGxBkrQH4niXAdpe2jVvxmwb/9SFv2QpoMtCuwr
# bH+GF6LvsMzTUwVjmqEfLzrsB+kT+PjxLgnD4uOJKZoB3MKZIHYtxvKhggMgMIID
# HAYJKoZIhvcNAQkGMYIDDTCCAwkCAQEwdzBjMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQg
# UlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhAFRK/zlJ0IOaa/2z9f5WEW
# MA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkq
# hkiG9w0BCQUxDxcNMjQwNjEwMTQxMTU0WjAvBgkqhkiG9w0BCQQxIgQgT5mCMNlR
# Dg4In8TH5OziesMC+6uHmw4bZOIqLXsB/JkwDQYJKoZIhvcNAQEBBQAEggIADWAY
# 1gS2AweTdb3IHen2vg1OOZcYoDkuNMdQFV4HzwlpE2f3BA8tu3p50nOPZIsvN4Bn
# er5+oX45gZMUTFqBH7rzjqF+4t+PidV3e1rZu/UDoyuDETKXAa+RZ05BQq7jmuRy
# 5aONXCr2VVorikLPlBN+tMd4pz787n09rWvrEdGMsXaCVK7CxYsBU/F0qNlfdGZE
# Kkao9y7dhXzGcdov4UNev/nxrFB9DU3A34OY08sMBjWCd8VzcIFcrASZPSI5fUcg
# fMKzuAcLEl5n4wIyg26TgP9QKzaKBQ1oqnrkrpylwhhIzRwDfLRCRCXcicxCdFzU
# rMU/LjKamu+QSiAay3zy11fj7sDSaqJUiZMw1Ssw2gQL+cQJGFdiM3eSwuPMHaMi
# XEgGT4khB4wtjEa7PZp3YEwn8xFmuEalTx9dTife52JZULn1Rg4+xf8f6O1WSrFf
# XWx0HkVoECY9ShKYD7TzvP69vvKWzGf3bVuXUdsoq+3SqGqLHGNFQdNcDr1wG1xD
# EOMbI5ZXO1fC9JRmaeP5TA3NRLTenf6d8Fr+kWt4/9Q8c4RqFQx2obtEqfKA4pqS
# z7O+E4ZeZGzCMhfkAvgIjUQB2FRFxU7nmNGQhlZCuBQDWmxNrWD5o/YGFZiV5mx1
# Z0GAQdWBgcL5DUonNKj5EqArjN4N4RMlRoG15WA=
# SIG # End signature block
