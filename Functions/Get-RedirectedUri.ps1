function Get-RedirectedUri {
  # reworked to work with curl since iwr no longer works unattended
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [string]$Uri
  )
  cmd.exe /c curl -sL -w "%{url_effective}" $Uri -o /dev/null
}
