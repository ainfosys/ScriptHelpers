Function Get-MSIProducts {
    # Much quicker than using WMI/CIMInstance
    # Found online here: https://stackoverflow.com/questions/29937568/how-can-i-find-the-product-guid-of-an-installed-msi-setup
    $Installer = New-Object -ComObject WindowsInstaller.Installer
    $InstallerProducts = $Installer.ProductsEx("", "", 7)
    $InstalledProducts = ForEach($Product in $InstallerProducts){
        try{
            [PSCustomObject]@{
                ProductCode = $Product.ProductCode()
                LocalPackage = $Product.InstallProperty("LocalPackage")
                Version = $Product.InstallProperty("VersionString")
                Name = $Product.InstallProperty("ProductName")
            }
        }
        Catch{

        }
    } 
    Return $($InstalledProducts | Sort-Object -Property Name)
}