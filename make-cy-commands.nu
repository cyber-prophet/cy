cy help 
| get command 
| drop 
| each {|i| $"parse_help '($i)' \(($i) --help\);"} 
| prepend 'source help_parser.nu' 
| save -f cy-commands.nu