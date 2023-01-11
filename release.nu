let readme = (open ~/cy/README.md | lines)

let lines_to_drop = (
    $readme 
    | each {
        |it index| if ($it == "## Commands") {echo $index}
    } 
    | get 0 
    | into int
    | ($readme | length) - ($in + 2)
    )

$readme 
| drop ($lines_to_drop) 
| append (cy help -m) 
| save ~/cy/README.md -f -r

print "success!"