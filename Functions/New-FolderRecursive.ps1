
function Recursive-CreateDirectory {
    param(
        $path
    )

    if(!(test-path $path)){
        $parentPath = Split-Path $path -Parent
        $leaf = Split-Path $path -Leaf
        if(!(test-path $parentPath)){
            Recursive-CreateDirectory -path $parentPath
        }
        New-Item -path $parentPath -Name $leaf -ItemType Directory -Force | Out-Null
    }
}
