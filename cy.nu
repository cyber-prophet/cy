# Cy - nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
# Git: https://github.com/cyber-prophet/cy
# 
# Use:
# > overlay use ~/apps-files/github/cy/cy.nu as cy -p


export def init [
    --remove-all
] {

    let dt1 = (date now | date format "%Y-%m-%d_%H_%M_%S")

    let path1 = $env.HOME + "/cy"
    mkdir $path1
    mkdir ($path1 + "/backup")
    let path_back = $path1 + "/backup/" + $dt1 

    if ($path1 | path exists) {
        mkdir $path_back
        ls $path1 | 
            where name !~ "backup" | 
            get name | 
            each {|it| mv $it $path_back} | 
            echo ""
    }

    # mkdir ($path1 + "/particles")
    mkdir ($path1 + "/cyberlinks")
    mkdir ($path1 + "/temp")

    cyberlinks-empty-table

}

export def cyberlinks-empty-table [] {

    let dt1 = (date now | date format "%Y-%m-%d_%H_%M_%S")
    let path1 = $env.HOME + "/cy/temp/cyberlinks.csv"           # ~ make errors with mv on mac
    let path2 = $env.HOME + "/cy/backup/" + "cyberlinks_" + $dt1 + ".csv"

    if ($path1 | path exists ) {
        ^mv $path1 $path2
    }
    'from,to' | save $path1
}

export def cyberlinks_append [
    cyberlinks?    #cyberlinks table
    --display_result_cyberlinks
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}
    let path1 = $env.HOME + '/cy/temp/cyberlinks.csv'

    open $path1 | append $cyberlinks | save $path1
    if (not ($display_result_cyberlinks | is-empty ) )  { open $path1 }
    
}


# Create text file and pin it to local node
export def particle_add_text_to_local_node [
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
                    |it| particle_add_text_to_local_node $it 
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
export def cyberlinks_add_from_particle [
    text: string                    # Text to upload to ipfs
] {
    $in | 
        upsert from (particle_add_text_to_local_node $text) |
        select from to
}

# Add text particle into 'to' column of local_cyberlinks table
export def cyberlinks_add_to_particle [
    text: string                    # Text to upload to ipfs
] { 
    $in | 
        rename -c ['to' 'from'] | 
        upsert to (particle_add_text_to_local_node $text) |
        select from to
}

#Create custom unsigned cyberlinks transaction
export def cyberlinks_create_trans_json [
    cyberlinks?                     # the table of cyberlinks
    --neuron: string                # address of neuron who will create cyberlinks
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    let cyberlinks = ($cyberlinks | select from to)

    let neuron = if ($neuron | is-empty) { $env.pussy.from } else {$neuron}

    let trans = ('{"body":{"messages":[{"@type":"/cyber.graph.v1beta1.MsgCyberlink","neuron":"","links":[{"from":"","to":""}]}],"memo":"","timeout_height":"0","extension_options":[],"non_critical_extension_options":[]},"auth_info":{"signer_infos":[],"fee":{"amount":[],"gas_limit":"2000000","payer":"","granter":""}},"signatures":[]}' | from json)

    $trans | 
        upsert body.messages.neuron $neuron | 
        upsert body.messages.links $cyberlinks | 
        save ~/cy/unsigned_tx.json 
}



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
                cy particle_add_text_to_local_node 
        }
}

# pussy tx sign --from hot_account temp_cyberlinks.json --chain-id space-pussy --keyring-backend test --output-document signed_tx.json

# sign and broadcast transaction
export def tx_sign_broadcast [] {
    pussy tx sign ~/cy/unsigned_tx.json --from $env.pussy.from  --chain-id space-pussy --keyring-backend $env.pussy.keyring-backend --output-document ~/cy/signed_tx.json
    pussy tx broadcast ~/cy/signed_tx.json
}

export def create_chuck_norris_cyberlink [] {
    let chuck_cid = (particle_add_text_to_local_node 'Chuck Norris')
    
    let quote = (fetch https://api.chucknorris.io/jokes/random).value 
    echo $quote

    let quote_cid = (particle_add_text_to_local_node $quote)
    
    # [[from to ];[$chuck_cid $quote_cid "Chuck Norris" $quote]] | cyberlinks_create_trans_json
    [[from to 'from text' 'to text'];[$chuck_cid $quote_cid "Chuck Norris" $quote]] 
} 

export def parse_copied_table [] {
    # pbpaste | lines | parse -r '(?P<col>.*)\t(?P<col2>.*)'
    # pbpaste | lines | split column '\t'
    let _table = ( pbpaste | from tsv )
    # let _col = $_table | columns 
    }

    export-env { 
        let-env pussy = if ('~/cy/cy_config.json' | path exists ) {
            open ~/cy/cy_config.json
        } else {
            ""
        }
    }
    
    export def create_config_json [] {
        print 'Enter pussy address: ' -n
        let pussy_address = (input)
        echo ''
        print 'Enter keyring backend: ' -n 
        let backend = (input)
        {'back': $pussy_address}
    }