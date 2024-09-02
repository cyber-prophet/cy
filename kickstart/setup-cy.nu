# Setup cy
use ../cy/nu-utils/ [cprint print-and-pass]

def --env 'install_if_missing' [
    brew_cli_name: string
    local_cli_name?
] {
    if ($local_cli_name | default $brew_cli_name | which $in) == [] {
        if (confirm $"You don't have `($brew_cli_name)` app available now. Would you like to install it via homebrew?") {
            try {
                brew install $brew_cli_name;
                print ''
            } catch {
                print $'($brew_cli_name) failed to install.'
            }
        }
    }
}

def --env 'confirm' [
    prompt: string
    --default_not (-n)
    --dont_keep_prompt
] : nothing -> bool {
    if ($env.confirm_all? | default false) {
        return true
    }

    if ($env.reject_all? | default false) {
        return false
    }

    if not $dont_keep_prompt {cprint $prompt}

    [yes 'yes for all' no 'no for all']
    | if $default_not { $in | reverse } else { }
    | input list (if $dont_keep_prompt {cprint --echo --after 0 $prompt} else {''})
    | if $dont_keep_prompt {} else {print-and-pass}
    | if $in == 'yes for all' {$env.confirm_all = true; 'yes'} else {}
    | if $in == 'no for all' {$env.reject_all = true; 'no'} else {}
    | $in in [yes]
}

install_if_missing "cyber"
install_if_missing "pussy"
install_if_missing "curl"
install_if_missing "ipfs"
install_if_missing "mdcat"

"\n# upgrade `ipfs` if it is installed\n"
| $'(ansi yellow)($in)(ansi reset)'
| print

if (brew list ipfs | complete | get exit_code) == 0 {
    brew upgrade ipfs
}

"\n# add default folder for ipfs\n"
| $'(ansi yellow)($in)(ansi reset)'
| print

if not ('~/.ipfs' | path exists) {
    try {ipfs init}
    sleep 0.5sec
}

if (ipfs swarm peers | complete | get exit_code) == 1 {
    try {brew services start ipfs}
    sleep 0.5sec
}

"# add cybernode to bootstrap \n"
| $'(ansi yellow)($in)(ansi reset)'
| print

try {ipfs bootstrap add '/ip4/135.181.19.86/tcp/4001/p2p/12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY'}
sleep 0.5sec

"\n# check if congress's cybernode is availible\n"
| $'(ansi yellow)($in)(ansi reset)'
| print

try {ipfs routing findpeer 12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY}

"\n# nu_plugin_polars is needed for local graph snapshot querying
# check if it is installed \n"
| $'(ansi yellow)($in)(ansi reset)'
| print

cargo install nu_plugin_polars
plugin add ('~/.cargo/bin/nu_plugin_polars' | path expand)

let $cy_folder = '~/cy'

"\n# check if there is `overlay use ... cy.nu ` in the configs\n"
| $'(ansi yellow)($in)(ansi reset)'
| print

open $nu.config-path | lines | find -r '^overlay use .*cy'
| if ($in | is-empty) {
    ((char nl) + "#💎 load Cy on Nushell start" + (char nl) +
        $"overlay use '($cy_folder)/cy/' -pr" + (char nl))
    | save -a $nu.config-path
}

"# Change Nushell default settings to preferred by Cyber-prophet \n"
| $'(ansi yellow)($in)(ansi reset)'
| print

open $nu.config-path
| str replace 'show_banner: true' 'show_banner: false'
| str replace 'show_empty: true' 'show_empty: false'
| str replace 'methodology: wrapping' 'methodology: truncating'
| str replace 'header_on_separator: false' 'header_on_separator: true'
| str replace 'file_format: "plaintext"' 'file_format: "sqlite"'
| str replace 'quick: true' 'quick: false'
| str replace 'algorithm: "prefix"' 'algorithm: "fuzzy"'
| save -f $nu.config-path

if (open $nu.env-path | lines | where $it starts-with '$env.EDITOR' | is-empty) {
    (char nl) + '$env.EDITOR = ^nano' + (char nl) | save -a $nu.env-path
}

print "Cy has been downloaded and installed. Now it will be launched automatically with Nu."
print "Now nu exits. Execute 'cy config-new' after you relaunch it. Have fun!"

exit
