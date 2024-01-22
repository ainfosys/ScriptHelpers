function Verify-FilePermission {
    param(
        [parameter()]
        $identity = $(whoami),
        [parameter(Mandatory)]
        $path
    )

    $userInfo = (whoami /all) | ForEach-Object {
        switch -Regex ($_) {
            '^User\s?Name'  { $type  = 'User' ; break }
            '^Group\s?Name' { $type  = 'Group'; break }      
            '^\s*$'         { $type  = '' ; break}
            '^=+'           { $width = $_ -split ' ' ; break }
            default {
                if ($type -eq 'User') {
                    $sidStart = $width[0].Length + 1
                    [PsCustomObject]@{
                        'Name' = $_.Substring(0, $width[0].Length).Trim()
                        'SID'  = $_.Substring($sidStart, $width[1].Length).Trim()
                        'Type' = $type
                    }  
                }
                elseif ($type -eq 'Group') { 
                    $sidStart = $width[0].Length + $width[1].Length + 2
                    [PsCustomObject]@{
                        'Name' = $_.Substring(0, $width[0].Length).Trim()
                        'SID'  = $_.Substring($sidStart, $width[2].Length).Trim()
                        'Type' = $type
                    }  
                }
            }
        }
    }
    $aclInfo = Get-Acl $path
    
    # if the identity is the directory owner return true
    if($aclInfo.Owner -ieq $identity){
        Return $true
    }

    # if any access identity references refer to the identity specified return true
    $IdentityAccess = $aclInfo.access | where {$_.IdentityReference -ieq $identity}
    if([bool]$IdentityAccess -and $IdentityAccess.AccessControlType -ieq "Allow"){
        Return $true
    }


    # if a group the identity is a member of has access permissions on the directory return true
    $GroupMember = $userInfo | where {$_.type -ieq "Group"}
    foreach($g in $GroupMember){
        if($aclInfo.Access.IdentityReference -icontains $g.name){
            $GroupAccess = $aclInfo.Access | where {$_.IdentityReference -ieq $g.name}
            if($GroupAccess.AccessControlType -ieq "Allow"){
                Return $true
            }
        }
    }

    # if nothing returned true by now then return false
    Return $false
}
