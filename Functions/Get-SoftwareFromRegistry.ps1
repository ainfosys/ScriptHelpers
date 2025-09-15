function Get-SoftwareFromRegistry {
    $key = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
    Get-ChildItem -Path $key | Get-ItemProperty
}
