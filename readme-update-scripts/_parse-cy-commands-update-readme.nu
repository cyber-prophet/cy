overlay hide cy_no_prefix
overlay use ~/cy/cy.nu -pr as cy

rm 'help_output.md' -f

cy help-cy
| get command
| drop
| each {|i| $"parse_help '($i)' \(($i) --help\);"}
| prepend 'source help_parser.nu'
| save -f cy-commands.nu

source cy-commands.nu
source release.nu
