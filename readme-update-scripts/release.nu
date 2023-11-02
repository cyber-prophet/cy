# This script updates Readme with the latest version of command annotatations in cy.nu

let readme = (open ~/cy/README.md | lines)

let lines_to_drop = (
    $readme
    | enumerate
    | each {
        |it| if ($it.item == "## Commands") {echo $it.index}
    }
    | get 0
    | into int
    | ($readme | length) - ($in + 2)
)

$readme
| drop ($lines_to_drop)
| append (open -r help_output.md)
| str join (char nl)
| str replace -ram ' +$' ''
| str replace -ra '<CompleterWrapper.*> -  ' ''
| save ~/cy/README.md -fr

print "success!"
