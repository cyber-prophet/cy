# Setup cy

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

if not 'cy' in $nu.scope.modules.name {
    $'overlay use "($cy_folder)/cy.nu" -p -r' | save -a $'($nu.config-path)'
} else {
    'cy should have already been installed.'
}

print "CY has been downloaded and installed. Now it will launch automatically with Nu."
print "restart nu, and execute 'cy config new'. Have fun!"