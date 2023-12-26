# Setup cy
use ../nu-utils/ [cprint print-and-pass]

def --env 'install_if_missing' [
    brew_cli_name: string
    local_cli_name?
] {
    if ($local_cli_name | default $brew_cli_name | which $in) == [] {
        if (confirm $"You don't have `($brew_cli_name)` app availble now. Would you like to install it via homebrew?") {
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
    --default_not (-n): bool = false
    --dont_keep_prompt
] : nothing -> bool {
    if not $dont_keep_prompt {cprint $prompt}

    if ($env.confirm_all? | default false) {
        return true
    }

    if ($env.reject_all? | default false) {
        return false
    }

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
install_if_missing "pueue"
install_if_missing "ipfs"
install_if_missing "rich-cli" "rich"
# install_if_missing "gum"

# depends_on "atuin"

# print "Where to install cy? Cyber-prophet recommends using a folder in a home directory '~/cy/'"
# let $cy_folder = (
#     ['~/cy/' 'other']
#     | input list
#     | do {|i| if $i == 'other' { input "type choosen path: " } else { $i } } $in
#     | path expand
#     | do {|i|
#         print $i;

#         ['yes' 'no']
#         | input list "Confirm that is the right path"
#         | if $in == yes {$i} else {print "repeat 'install cy'"; null}
#     } $in
# )

# {
#     'path': $cy_folder
#     'ipfs-files-folder': $"($cy_folder)/graph/particles/safe/"
#     'ipfs-download-from': 'gateway'
# } | save ("~/.cy_config.toml" | path expand) -f

# mkdir $"($cy_folder)"

# http get https://raw.githubusercontent.com/cyber-prophet/cy/dev/cy.nu
# | save -f $"($cy_folder | path join 'cy.nu')"

if ( '~/.ipfs' | path exists | not $in ) {
    ipfs init
}

if ( ipfs swarm peers | complete | get exit_code | $in == 1 ) {
    brew services start ipfs
}

let $cy_folder = '~/cy'

(open $nu.config-path | lines | find -r '^overlay use .*cy\.nu')
| if ($in | is-empty) {
    $"#💎 load Cy on NuShell start(char nl)overlay use '($cy_folder)/cy.nu' -pr (char nl)"
    | save -a $'($nu.config-path)'
} else {
    print $in
}

print "CY has been downloaded and installed. Now it will launch automatically with Nu."
print "Now nu exits. Execute 'cy config-new' after you relaunch it. Have fun!"

exit
