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
| nu --env-config table_env_test.nu -c $in

nu -n release.nu
