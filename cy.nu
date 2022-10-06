# Cy - nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
# Git: https://github.com/cyber-prophet/cy
# 
# Use:
# > overlay use ~/apps-files/github/cy/cy.nu as cy -p


# Create text file and pin it to local node
export def add_text_particle_to_local_node [text] {
    echo $text | 
        ipfs add -Q | 
        str replace '\n' ''
}


def parse_ipfs_table [] {parse -r '(?<status>\w+) (?<to>Qm\w{44}) (?<filename>.+)'}

# Adding files from folder to ipfs, creating table. Without parameters all files will be added
export def add_files_from_folder_to_ipfs [
    ...files: string # filenames to add
    --cyberlink_filenames_to_their_files
] {

    let files = (
        if $files == [] {
            ls | where type == file | get name
        }
    )

    let cid_table = (
        $files |
            each {|f| ipfs add $f} |
            parse_ipfs_table 
    )

    let out_table = (
        if $cyberlink_filenames_to_their_files {
            $cid_table.filename | 
                each {
                    |it| add_text_particle_to_local_node $it 
                } | 
                wrap from | 
                merge {$cid_table}
        } else {
            $cid_table
        }
    )

    $out_table 
}

# Add text particle into 'from' column of local_cyberlinks table
export def add_from_particle [
    text: string # Text to upload to ipfs
] {
    $in | 
        upsert from (add_text_particle_to_local_node $text) |
        select from to
}

# Add text particle into 'to' column of local_cyberlinks table
export def add_to_particle [
    text: string # Text to upload to ipfs
] { 
    $in | 
        rename -c ['to' 'from'] | 
        upsert to (add_text_particle_to_local_node $text) |
        select from to
}

#Create custom unsigned cyberlinks transaction
export def cyberlinks_trans_json [
    cyberlinks?           # the table of cyberlinks
    neuron?: string              # address of neuron who will create cyberlinks
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    let cyberlinks = ($cyberlinks | select from to)

    let trans = ('{"body":{"messages":[{"@type":"/cyber.graph.v1beta1.MsgCyberlink","neuron":"","links":[{"from":"","to":""}]}],"memo":"","timeout_height":"0","extension_options":[],"non_critical_extension_options":[]},"auth_info":{"signer_infos":[],"fee":{"amount":[],"gas_limit":"2000000","payer":"","granter":""}},"signatures":[]}' | from json)

    $trans | 
        upsert body.messages.neuron $neuron | 
        upsert body.messages.links $cyberlinks | 
        save temp_cyberlinks.json 
}
