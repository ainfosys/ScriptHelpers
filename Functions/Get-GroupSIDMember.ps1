Function Get-GroupSIDMember {
    param(
        [parameter(Mandatory)]
        $GroupSID
    )

    $Group = Get-LocalGroup -SID $GroupSID

    $null = Add-Member -InputObject $Group -MemberType 'NoteProperty' -Force -Name 'Members' -Value (
        [string[]](
            $(
                [adsi](
                    'WinNT://{0}/{1}' -f $env:COMPUTERNAME, $Group.'Name'
                )
            ).Invoke(
                'Members'
            ).ForEach{
                $([adsi]($_)).'path'.Split('/')[-1]
            }
        )
    )
    
    $Group.'Members'
}
