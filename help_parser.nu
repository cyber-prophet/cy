def parse_help [
    command
    input
] {
    let $input_lines = (
        $input 
        | lines 
        | where $it !~ 'Display the help message for this command'
    )
    let $t3_first_part = (
        $input_lines 
        | take until {|i| $i =~ 'Usage'} 
        | each {|i| $'  ($i)'}
    )
    
    $input_lines 
    | skip until {|i| $i =~ Flags} 
    | prepend (
        $t3_first_part 
        | skip 2
        # | append "```"
    ) 
    | prepend (
        $input_lines 
        | skip until {|i| $i =~ Usage} 
        # | insert 1 "```"s
        | take until {|i| $i =~ Flags}
    ) 
    | prepend (
        $t3_first_part | take 2
    )
    | prepend $"### ($command)\n```"
    | append "```\n\n"
    | str join "\n"
    | ansi strip
    | str replace "Flags:\n\n" ""
    | save -a 'help_output.md'
}

rm 'help_output.md' -f 

# cy help | get command | drop | each {|i| $"parse_help '($i)' \(($i) --help\);"} | save -f cy-commands.nu