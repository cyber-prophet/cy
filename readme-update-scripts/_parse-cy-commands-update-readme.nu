# overlay hide cy_no_prefix
use ~/cy/cy.nu

rm 'help_output.md' -f

scope modules
| where name == 'cy'
| get commands.0
| sort-by decl_id
| get name
| skip
| each {|i| $"parse_help 'cy ($i)' \(help '($i)'\);"}
| prepend "use ~/cy/cy.nu"
| prepend (view source 'parse_help')
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
| str replace -ram ' +- *$' ''
| str replace -ra '<CompleterWrapper.*>\s+-\s+' ''
| save ~/cy/README.md -fr

print "success!"


def parse_help [
    command
    input
] {
    let $input_lines = (
        $input
        | default ''
        | lines
        | where $it !~ 'Display the help message for this command'
    )
    let $first_part = (
        $input_lines
        | take until {|i| $i =~ 'Usage'}
        | each {|i| $'  ($i)'}
    )

    $input_lines
    | skip until {|i| $i =~ Flags}
    | prepend ( $first_part | skip 2 )
    | prepend (
        $input_lines
        | skip until {|i| $i =~ Usage}
        | take until {|i| $i =~ Flags}
    )
    | prepend ( $first_part | take 2 )
    | prepend $"### ($command)\n\n```"
    | append "```\n\n"
    | str join "\n"
    | ansi strip
    | str replace "Flags:\n\n" ""
    | save -a 'help_output.md'
}
