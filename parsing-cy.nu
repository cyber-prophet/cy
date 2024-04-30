let file = '~/cy/cy.nu'

$file
| open --raw
| parse -r "\n(?<whole_comments># (?<desc>.*)\n(?:#\n)?(?<examples>(?:(?:\n#)|.)*)*)\nexport def(?: --(?:env|wrapped))* '(?<command>.*)'"
| update examples {|i|
    $i.examples
    | str replace -ram '^# ?' ''
    | split row "\n\n"
    | parse -r '(?<annotation>^.+\n)??> (?<command>.*(?:\n\|.+)*)'
}
| enumerate
| reject index
