# Cy - nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
# Git: https://github.com/cyber-prophet/cy
# 
# Use:
# > overlay use ~/apps-files/github/cy/cy.nu as cy -p


# Create text file and pin it to local node
export def add_text_particle_to_local_node [
    text?: string
] {

    let text = if ($text | is-empty) {$in} else {$text}

    echo $text | 
        ipfs add -Q | 
        str replace '\n' ''
}


def parse_ipfs_table [] {parse -r '(?<status>\w+) (?<to>Qm\w{44}) (?<filename>.+)'}

def is-cid [particle: string] {
    (($particle | str length) == 46) && ($particle =~ '^Qm') 
}

# Adding files from folder to ipfs, creating table. Without parameters all files will be added
export def add_files_from_folder_to_ipfs [
    ...files: string                # filenames to add into local ipfs node
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
export def cyberlinks_create_trans_json [
    cyberlinks?           # the table of cyberlinks
    --neuron: string              # address of neuron who will create cyberlinks
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    let cyberlinks = ($cyberlinks | select from to)

    let trans = ('{"body":{"messages":[{"@type":"/cyber.graph.v1beta1.MsgCyberlink","neuron":"","links":[{"from":"","to":""}]}],"memo":"","timeout_height":"0","extension_options":[],"non_critical_extension_options":[]},"auth_info":{"signer_infos":[],"fee":{"amount":[],"gas_limit":"2000000","payer":"","granter":""}},"signatures":[]}' | from json)

    $trans | 
        upsert body.messages.neuron $neuron | 
        upsert body.messages.links $cyberlinks | 
        save cyberlinks_unsigned.json 
}

# pussy tx sign --from hot_account temp_cyberlinks.json --chain-id space-pussy --keyring-backend test --output-document signed-trans.json

# Upload values from column 'text' to the local IPFS node and add the column with the new CIDs.
export def upload_text_column_to_ipfs [
    cyberlinks?: table
    --column_with_text: string = 'text' # column name to take values from to upload to IPFS. If is ommited default value is 'text'
    --column_to_write_cid: string = 'from' # column name to write CIDs to. If is ommited default value is 'from'
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    $cyberlinks | 
        upsert $column_to_write_cid {
            |it| $it |
                get $column_with_text |
                cy add_text_particle_to_local_node 
        }
}