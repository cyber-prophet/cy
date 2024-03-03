# overlay hide cy_no_prefix
use ~/cy/cy.nu

rm 'help_output.md' -f

scope modules
| where name == 'cy'
| get commands.0
| sort-by decl_id
| get name
| skip
| each {|i| $"parse_help 'cy ($i)' \(cy ($i) --help\);"}
| prepend "use ~/cy/cy.nu; use parse_help.nu\n\n"
| str join "\n"
| nu --env-config env-table-settings.nu -c $in

# This script updates the README with the latest version of command annotations in cy.nu

let readme = (open ~/cy/README.md | lines)

$readme
| take until {|i| $i == "## Commands"}
| append "## Commands\n"
| append (open -r help_output.md)
| str join (char nl)
| str replace -ram ' +$' ''
| str replace -ra '<CompleterWrapper.*>\s+-\s+' ''
| save ~/cy/README.md -fr

print "success!"
