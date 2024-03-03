export def main [
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

# cy help | get command | drop | each {|i| $"parse_help '($i)' \(($i) --help\);"} | save -f cy-commands.nu
