# Setup cy
def install_if_missing [
    cli_name: string
] {
    if (which $cli_name) == [] {
        try {
            brew install $cli_name
        } catch {
            print $'($cli_name) was not installed'
        }
    }
}

install_if_missing "pussy"
install_if_missing "curl"
install_if_missing "pueue"
install_if_missing "ipfs"
install_if_missing "rich-cli"
install_if_missing "gum"

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

let $cy_folder = '~/cy'

if (not ('cy' in (scope modules | get name))) {
    $"overlay use '($cy_folder)/cy.nu' -pr (char nl)" | save -a $'($nu.config-path)'
}

print "CY has been downloaded and installed. Now it will launch automatically with Nu."
print "restart nu, and execute 'cy config-new'. Have fun!"
