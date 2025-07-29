<#
.DESCRIPTION: Verify the device is able to use bitlocker and then configure bitlocker
.NOTES:
    *GENERAL REQUIREMENTS*
    + One of the following licenses is required:
        - Windows Pro
        - Windows Enterprise
        - Windows Pro Education/SE
        - Windows Education
        - Windows Enterprise E3 (Azure/Office Account)
        - Windows Enterprise E5 (Azure/Office Account)
        - Windows Education A3 (Azure/Office Account)
        - Windows Education A5 (Azure/Office Account)
    + Bitlocker requires the OS drive be partitioned with a minimum of 2 partitions:
        - Main partition should be NTFS
        - System partition must not be encrypted
            - for legacy/bios booting it must be NTFS
            - for UEFI booting it must be FAT32
    + Prior to Windows 11 24H2 the device must support modern standby or HSTI security requirements - this may only affect bitlocker auto deployment
    *KEY PROTECTORS*
    + Without a TPM have the following options:
        - Use a startup key, which is a file stored on a removable drive that is used to start the device, or when resuming from hibernation
        - Use a password. This option isn't secure since it's subject to brute force attacks as there isn't a password lockout logic. As such, the password option is discouraged and disabled by default.
    + TPM is the recommended key protector
        - TPM must be present, ready and enabled
        - TPM 1.2 or higher required
        - A device with a TPM must also have a Trusted Computing Group (TCG)-compliant BIOS or UEFI firmware
        - Devices with TPM 2.0 must have their boot mode configured as native UEFI only.
.CHANGELOG:
    - 6/1/7/25: Initial version
    - 7/18/25: added output for PCR validation profile
        - fixed getting partitions of osdisk
#>
function Module-ShouldBe {
    param(
        [parameter(Mandatory)]
        $ModuleName
    )
    try{
        [Net.ServicePointManager]::SecurityProtocol = 15360
    }
    catch{
      # Fall back to tls 1.2 if error thrown
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    }
    $ProgressPreference = 'SilentlyContinue'
    $Online = Find-Module -Name $ModuleName
    $Installed = Get-module -Name $ModuleName -ListAvailable
    if([bool]$Installed){
        if($Installed.version -ne [System.Version]$Online.version){
            Remove-Module -Name $ModuleName -ErrorAction Ignore
            Uninstall-Module -Name $ModuleName -AllVersions -Force
            Install-module -Name $ModuleName -Force
        }
    }else{
        Install-module -Name $ModuleName -Force
    }
}
$Mountpoint = $env:mountpoint
if([string]::IsNullOrWhiteSpace($Mountpoint)){
  $Mountpoint = $ENV:SystemDrive
}
$TargetDriveBLInfo = Get-BitLockerVolume -MountPoint $MountPoint
if($TargetDriveBLInfo.protectionstatus -ieq "on"){
    Write-Warning "Bitlocker protection is already enabled on $mountpoint"
    $TargetDriveBLInfo | select *
    Exit
}

# Check for required license
$osInfo = Get-CimInstance Win32_OperatingSystem
if($osInfo.Caption -ilike "*Home*"){
    Write-Warning "⚠️ Device is running Windows Home edition. Bitlocker requires a compatible license for either Windows or a signed in azure/entra/office/microsoft account. Proceeding assuming license is with account."
}

# verify at least 2 partitions on OS drive
$Disks = Get-PhysicalDisk
foreach($disk in $disks){
    $Partitions = $disk | get-disk | Get-Partition
    if($Partitions.DriveLetter -icontains $($Mountpoint -replace ":")){
        $OSDisk = $Disk
    }
}
$OSDiskPartitions = $OSDisk | Get-Disk | Get-Partition
if($OSDiskPartitions.count -lt 2){
    Throw "❌ Bitlocker requires two or more partitions on the OS drive"
}

# verify main partition is NTFS for OS disk
$MainVolume = $OSDiskPartitions | where {$_.DriveLetter -ieq $($Mountpoint -replace ":")} | Get-Volume
if($MainVolume.FileSystemType -ne "NTFS"){
    Throw "❌ Bitlocker requires that the main partition/volume for the OS drive be formated as NTFS. Currently formated as `"$($MainVolume.FileSystemType)`""
}

# verify the system partition is the correct format based on UEFI or BIOS firmware
$SystemVolume = $OSDiskPartitions | where {$_.Type -eq "System"} | Get-Volume

if($env:firmware_type -eq "UEFI"){
    if($SystemVolume.FileSystemType -ne "FAT32"){
        Throw "Bitlocker requires the system partition of the OS drive be formated as FAT32 when UEFI booting"
    }
}else{
    if($SystemVolume.FileSystemType -ne "NTFS"){
        Throw "❌ Bitlocker requires the system partition of the OS drive be formated as NTFS when Legacy/BIOS booting"
    }
}

# determine if there is any bootable media plugged in, bitlocker will have issues with this
# volumes can still trigger this, unable to determine if volumes are bootable
$Bootable = Get-Disk | Where { $_.BusType -eq 'USB' -and $_.BootFromDisk -eq $TRUE }
if([bool]$Bootable){
    Throw "❌ Bootable media detected plugged into the computer. Remove the bootable media before enabling bitlocker or the device will be asked for the recovery key on boot up"
}

# check for existing key protectors
$KeyProtectors = $TargetDriveBLInfo | select -expand KeyProtector
if([bool]$KeyProtectors){
    if($TargetDriveBLInfo.VolumeStatus -ieq "FullyEncrypted"){
        Write-Warning "Bitlocker drive protection status is off but drive has existing key protectors, attempting to resume bitlocker now"
        try{
            Resume-BitLocker -MountPoint $MountPoint -ErrorAction Stop
        }
        catch{
            Write-Warning "❌ Failed to resume bitlocker with existing key protectors, use the remove key protectors script and re-run this script"
            $Error[0]
            throw
        }
    }
}

# Determine if the device has a viable TPM for key protector use
try{
    $TPMInfo = Get-Tpm -ErrorAction Stop
}catch{
    try{
        $TPMInfo = Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftTpm' -ClassName 'Win32_Tpm' -ErrorAction Stop
    }
    catch{
        $TPMInfo = $null
    }
}

if($(!$TPMInfo.TpmPresent -and !$TPMInfo.IsActivated_InitialValue) -or $(!$TPMInfo.TpmReady -and !$TPMInfo.IsOwned_InitialValue) -or $(!$TPMInfo.TpmEnabled -and !$TPMInfo.IsEnabled_InitialValue)){
    Throw "❌ No valid TPM found to be used as a key protector. Without a TPM a startup key or password must be used on startup."
}

$TPMVersion = ((Get-CimInstance -Namespace 'root/cimv2/Security/MicrosoftTpm' -ClassName 'Win32_Tpm').SpecVersion -split ', ') | sort | select -Last 1
if([int]$TPMVersion -lt 1.2){
    throw "❌ TPM v1.2 or greater required for using TPM as a key protector"
}

if([int]$TPMVersion -ge 2.0 -and $env:firmware_type -ne "UEFI"){
    throw "❌ TPM v2.0 or greater detected. Device must UEFI boot in order to use it as a key protector"
}

# Encrypt
Write-Output "ℹ️ Attempting to enable bitlocker with a TPM and recovery key key protector"
try{
    Enable-BitLocker -MountPoint $MountPoint -TpmProtector -ErrorAction Stop > $Null
}
catch{
    Write-Warning "❌ Error thrown enabling bitlocker with TPM key protector:"
    $Error[0]
    throw
}

## Enable additional key protectors
# Recovery key
if($TargetDriveBLInfo.KeyProtector.keyprotectortype -inotcontains "RecoveryPassword"){
    Write-Output "ℹ️ Recovery password key protector is not currently setup, creating one now"
    Add-BitLockerKeyProtector -MountPoint $MountPoint -RecoveryPasswordProtector
}

# Determine if the device is azure ad or local ad joined
$InstalledModules = Get-Module -ListAvailable
if ($InstalledModules.name -inotcontains "DSReg")
{    
    Module-ShouldBe -ModuleName "DSReg"
}
Import-module -name "DSReg" -Force
try{
    $DsRegResults = Get-DSReg -ErrorAction stop
}
catch{
    Write-Warning "⚠️ Failed to determine if device is Azure AD or Active Directory joined, unable to apply additional key protectors"
}

if($DsRegResults.azureadjoined){
    # backup key to azure, there is no way to know if it is already backed up to azure so always run it
    $ProtectorID = Get-BitLockerVolume -MountPoint $MountPoint | Select-Object -expand KeyProtector | Where-object {$_.keyprotectortype -ieq "RecoveryPassword"} | Select-Object -expand KeyProtectorId
    try{
        BackupToAAD-BitLockerKeyProtector -MountPoint $mountpoint -KeyProtectorId $ProtectorID -erroraction stop > $null
    }
    catch{
        Write-Warning "⚠️ Failed to backup recovery key to azure"
    }
}

if($DsRegResults.DomainJoined){
    
    $Domain = $DsRegResults.domainname
    $User = Get-MostActiveUser
    $ADUser = "$Domain\$User"
    try{
        Add-BitLockerKeyProtector -MountPoint $MountPoint -AdAccountOrGroup $ADUser -AdAccountOrGroupProtector -erroraction stop > $null
    }
    catch{
        Write-Warning "⚠️ Failed to backup recovery key to active directory"
    }
}

# output PCR validators
$Output = manage-bde.exe -protectors -get $ENV:SystemDrive
$Line = $Output | Select-String "PCR Validation Profile:"
if([bool]$Line){
    $PCRLine = [int]$Line.LineNumber
    $PCRLine++
    Write-Output "🛡️ PCR Validation profile follows:"
    $($output[$PCRLine - 1]).trim()
}

Write-Output "ℹ️ If bitlocker was just enabled a restart may be required for bitlocker to be fully enabled"
