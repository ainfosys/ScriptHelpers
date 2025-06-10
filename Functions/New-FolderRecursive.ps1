function New-FolderRecursive {
    param(
        $path
    )

    # unable to use get-item if path doesnt exist
    if ($Path -match "^([A-Z]:|\\\\)(.*)$" ) {
        $PathType =  "Filesystem"
    } elseif ($Path -match "^(HKCU:|HKLM:|HKCR:|HKU:|HKCC:|Registry::)(.*)$" ) {
        $PathType =  "Registry"
    } else {
        $PathType =  "Unknown"
    }

    if(!(test-path $path)){
        $parentPath = Split-Path $path -Parent
        $leaf = Split-Path $path -Leaf
        if(!(test-path $parentPath)){
            New-FolderRecursive -path $parentPath
        }
        switch($PathType){
            "Registry"{
                New-Item -path $parentPath -Name $leaf -Force | Out-Null
            }
            "FileSystem"{
                New-Item -path $parentPath -Name $leaf -ItemType Directory -Force | Out-Null
            }
            default{
                Write-Warning "Unexpected pathtype: $pathtype"
                New-Item -path $parentPath -Name $leaf -ItemType Directory -Force | Out-Null
            }
        }
    }
}
