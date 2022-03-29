Function Validate-Base64 {
    param
    (
	    [parameter(Mandatory = $true, HelpMessage = "The string you want to validate as being base64 encoded")]
	    [String]$EncodedString
    )

    if($EncodedString -match '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4})$'){
        Return $true
    }
    else{
        Return $false
    }
}