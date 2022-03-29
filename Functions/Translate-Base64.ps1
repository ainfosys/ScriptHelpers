Function Translate-Base64 {
    param
    (
	    [parameter(Mandatory = $true, HelpMessage = "The Base64 encoded string you wish to convert from base64")]
	    [String]$EncodedString
    )

    try{
        Return [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedString))
    }
    catch{
        $Error[0]
        $Error[0].Exception.GetType().FullName
    }
}