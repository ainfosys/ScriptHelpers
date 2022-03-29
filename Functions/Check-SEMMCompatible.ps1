Function Check-SEMMCompatible {
    <#
    .DESCRIPTION: Checks the device the function runs on to verify if it is SEMM compatible (Surface devices only)
    .AUTHOR: Ryan
    .TODO:
        - Add further checks to make sure the UEFI firmware is up to date or at least on a version supported
    #>
    $ValidSKU = $False
    $SystemSKU = (Get-CimInstance -Namespace root\wmi -ClassName MS_SystemInformation).SystemSKU
    $ValidSKUs = "Surface_Pro_8_for_Business_1983","Surface_Pro_8_for_Business_with_LTE_Advanced_1982","Surface_Pro_4*", `
        "Surface_Pro_X*","Surface Laptop SE*","Surface_Laptop_Studio_1964","Surface Hub 2S","Surface Hub 2S 85","Surface_Laptop_4_1978:1979", `
        "Surface_Laptop_4_1952:1953","Surface_Laptop_4_1950:1951","Surface_Laptop_4_1958:1959","Surface_Laptop_3_1872","Surface_Laptop_3_1867:1868", `
        "Surface_Laptop_Go*","Surface_Book*","Surface_Go_1824_Commercial","Surface_Go_1824_Consumer","Surface_Go_1825_Commercial","Surface_Go_2_1926", `
        "Surface_Go_2_1901","Surface_Go_2_1927","Surface_Go_3_1926","Surface_Studio*"
    
    foreach($SKU in $ValidSKUs){
        if($SKU -ilike "***"){
            # SKU contains an asterisk which means all skus for X model are valid
            if($SystemSKU -ilike $SKU){
                $ValidSKU = $true; Break
            } 
        }
        else{
            if($SystemSKU -imatch $SKU){
                $ValidSKU = $True; Break
            }
        }
    }

    Return $ValidSKU
}