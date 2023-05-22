# Setup cy

print "Where to install cy? Cyber-prophet recommends using a folder in a home directory '~/cy/'"
let $cy_folder = (
    ['~/cy/' 'other'] 
    | input list
    | do {|i| if $i == 'other' { input "type choosen path: " } else { $i } } $in
    | path expand
    | do {|i| print $i; $i} $in
)

{
    'path': $cy_folder
    'ipfs-files-folder': $"($cy_folder)/graph/particles/safe/"
    'ipfs-download-from': 'gateway'
} | save ("~/.cy_config.toml" | path expand) -f

mkdir $"($cy_folder)" 
| http get https://raw.githubusercontent.com/cyber-prophet/cy/dev/cy.nu 
| save -f $"($cy_folder | path join 'cy.nu')"

if not 'cy' in $nu.scope.modules.name {
    $'overlay use ($cy_folder)/cy.nu -p -r' | save -a $'($nu.config-path)'
}

print "cy has been downloaded and installed. Restart nu, and execute 'cy config new'. Have fun!"

nu