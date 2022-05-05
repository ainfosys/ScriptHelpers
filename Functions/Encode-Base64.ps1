Function Encode-Base64 {
    param
    (
	    [parameter(Mandatory = $true, HelpMessage = "The string you wish to encode in base64")]
	    [String]$String
    )

    try{
       Return [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($String))
    }Catch{
       $Error[0]
       $Error[0].Exception.GetType().FullName
    }
}