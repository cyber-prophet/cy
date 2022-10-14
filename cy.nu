# Cy - nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
# Git: https://github.com/cyber-prophet/cy
# 
# Use:
# > overlay use ~/apps-files/github/cy/cy.nu as cy -p


def parse-ipfs-table [] {parse -r '(?<status>\w+) (?<to>Qm\w{44}) (?<filename>.+)'}

def is-cid [particle: string] {
    ($particle =~ '^Qm\w{44}$') 
}

def is-connected []  {
    (do -i {fetch https://google.com} | describe) == 'raw input'
}

export-env { 
    let path1 = $env.HOME + '/cy/cy_config.json'
    let-env cy = if ($path1 | path exists ) {
        open ($path1)
    } else {
        echo 'cy_config.json is not found. Run "cy create config json"'
        ''
    }
}

export def-env "create config json" [] {

    let home = ($env.HOME + '/cy/')
    # let old = (open ($home + 'config.json'))

    let _exec = (input 'Choose cyber executable name (cyber or pussy): ')
    let _exec = (if ($_exec | is-empty) {'cyber'} else {$_exec})

    let address = (input 'Enter main address: ')
    let address = (if ($address | is-empty) {'bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel'} else {$address})

    let backend = (input 'Enter keyring backend: ')
    let backend = (if ($backend | is-empty) {'test'} else {$backend})

    # let chain_id = (input 'Enter chain-id: ')
    # let chain_id = (if ($chain_id | is-empty) {'bostrom'} else {$chain_id})
    let chain_id = (if ($_exec == 'cyber') {'bostrom'} else {'pussy'})

    let temp_env = {
        'exec': $_exec
        'address': $address
        'keyring-backend': $backend
        'chain-id': $chain_id
        'path': {
            'home': $home
            'cyberlinks-csv-temp': ($home + 'cyberlinks_temp.csv')
            'cyberlinks-csv-archive': ($home + 'cyberlinks_archive.csv')
            'tx-signed' : ($home + 'temp/tx-signed.json')
            'tx-unsigned' : ($home + 'temp/tx-unsigned.json')
        }
    } 
    
    mkdir $temp_env.path.home

    $temp_env | save ($temp_env.path.home + 'cy_config.json')
    
    let-env cy = $temp_env

    if (not ($env.cy.path.cyberlinks-csv-archive | path exists)) {
        "from,to,address,timestamp,txhash" | save $env.cy.path.cyberlinks-csv-archive
    }

    if (not ($env.cy.path.cyberlinks-csv-temp | path exists)) {
        "from,to" | save $env.cy.path.cyberlinks-csv-temp
    }

    echo ''
    echo 'JSON is updated'
    echo ''
    echo $env.cy
}

# export def init [
#     --remove-all
# ] {

#     let dt1 = (date now | date format '%Y%m%d-%H%M%S')

#     mkdir ($env.cy.path.home)
#     mkdir (($env.cy.path.home) + '/backup')
#     let path_back = ($env.cy.path.home + '/backup/' + $dt1 )

#     if (($env.cy.path.home) | path exists) {
#         mkdir $path_back
#         ls ($env.cy.path.home) | 
#             where name !~ 'backup' | 
#             get name | 
#             each {|it| mv $it $path_back} | 
#             echo ''
#     }

#     # mkdir (($env.cy.path.home) + '/particles')
#     # mkdir (($env.cy.path.home) + '/cyberlinks')
#     mkdir (($env.cy.path.home) + '/temp')

#     clear temp cyberlinks table

# }

export def 'clear temp cyberlinks table' [] {

    let dt1 = (date now | date format '%Y%m%d-%H%M%S')
    let path2 = $env.cy.path.home + 'backup/' + 'cyberlinks_' + $dt1 + '.csv'

    if ($env.cy.path.cyberlinks-csv-temp | path exists ) {
        ^mv $env.cy.path.cyberlinks-csv-temp $path2
    }
    'from,to' | save $env.cy.path.cyberlinks-csv-temp
}


export def 'append cyberlinks to temp table' [
    cyberlinks?    #cyberlinks table
    --dont_show_out_table
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    let cyberlinks = ($cyberlinks | 
        upsert date_time (date now | date format '%y%m%d-%H%M'))

    open $env.cy.path.cyberlinks-csv-temp | 
        append $cyberlinks | 
        save $env.cy.path.cyberlinks-csv-temp

    if (not $dont_show_out_table)  { 
        open $env.cy.path.cyberlinks-csv-temp 
    }
    
}


# Create text file and pin it to local node
export def 'create particle from text' [
    text?: string
] {

    let text = if ($text | is-empty) {$in} else {$text}

    echo $text | 
        ipfs add -Q | 
        str replace '\n' ''
}


# Adding files from folder to ipfs, creating table. Without parameters all files will be added
export def 'add files from folder to ipfs' [
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
            parse-ipfs-table 
    )

    let out_table = (
        if $cyberlink_filenames_to_their_files {
            $cid_table.filename | 
                each {
                    |it| create particle from text $it 
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
export def 'add text particle into from column' [
    text: string                    # Text to upload to ipfs
] {
    $in | 
        upsert from (create particle from text $text) |
        select from to
}

# Add text particle into 'to' column of local_cyberlinks table
export def 'add text particle into to column' [
    text: string                    # Text to upload to ipfs
] { 
    $in | 
        rename -c ['to' 'from'] | 
        upsert to (create particle from text $text) |
        select from to
}



# Upload values from column 'text' to the local IPFS node and add the column with the new CIDs.
export def 'upload text values from column to ipfs' [
    cyberlinks?: table
    --column_with_text: string = 'text' # column name to take values from to upload to IPFS. If is ommited default value is 'text'
    --column_to_write_cid: string = 'from' # column name to write CIDs to. If is ommited default value is 'from'
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    $cyberlinks | 
        upsert $column_to_write_cid {
            |it| $it |
                get $column_with_text |
                cy create particle from text 
        }
}

# $env.cy.exec tx sign --from hot_account temp_cyberlinks.json --chain-id space-pussy --keyring-backend test --output-document tx-signed_tx.json

#Create custom tx-unsigned cyberlinks transaction
def 'create tx json from temp cyberlinks' [
    # cyberlinks?                     # the table of cyberlinks
    --neuron: string                # address of neuron who will create cyberlinks
] {
    let cyberlinks = (open $env.cy.path.cyberlinks-csv-temp | select from to)

    # let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}
    let neuron = if ($neuron | is-empty) { $env.cy.address } else {$neuron}
    let trans = ('{"body":{"messages":[{"@type":"/cyber.graph.v1beta1.MsgCyberlink","neuron":"","links":[{"from":"","to":""}]}],"memo":"","timeout_height":"0","extension_options":[],"non_critical_extension_options":[]},"auth_info":{"signer_infos":[],"fee":{"amount":[],"gas_limit":"2000000","payer":"","granter":""}},"signatures":[]}' | from json)

    $trans | 
        upsert body.messages.neuron $neuron | 
        upsert body.messages.links $cyberlinks | 
        save $env.cy.path.tx-unsigned
}



# sign and broadcast transaction
export def 'tx create sign broadcast' [] {
    if not (is-connected) {
        error make {msg: "there is no internet!"}
    }

    create tx json from temp cyberlinks

    let var1 = (if $env.cy.exec == 'cyber' {
        cyber tx sign $env.cy.path.tx-unsigned --from $env.cy.address  --chain-id $env.cy.chain-id --keyring-backend $env.cy.keyring-backend --output-document $env.cy.path.tx-signed
        cyber tx broadcast $env.cy.path.tx-signed --broadcast-mode block
    } else {
        pyssy tx sign $env.cy.path.tx-unsigned --from $env.cy.address  --chain-id $env.cy.chain-id --keyring-backend $env.cy.keyring-backend --output-document $env.cy.path.tx-signed
        pyssy tx broadcast $env.cy.path.tx-signed --broadcast-mode block
    })

    let var2 = ($var1 | from json | select raw_log code txhash)
    if $var2.code == 0 {
        echo "cyberlinks should be successfully sent"
        $var2 
    } else {
        # echo "error!"
        $var2 
    }
}

#export def check cyberlinks

export def 'add chuck norris cyberlink' [
    --dont_append_to_cyberlinks_temp_csv
] {
    let chuck_cid = (create particle from text 'Chuck Norris')
    
    let quote = (fetch https://api.chucknorris.io/jokes/random).value 
    # echo $quote

    let quote_cid = (create particle from text $quote)
    
    # [[from to ];[$chuck_cid $quote_cid 'Chuck Norris' $quote]] | create tx json from temp cyberlinks
    let $_table = (
        [[from to 'from_text' 'to_text'];
        [$chuck_cid $quote_cid 'Chuck Norris' $quote]]
    )

    if $dont_append_to_cyberlinks_temp_csv {$_table} else {
        $_table | append cyberlinks to temp table
    }
} 

export def 'paste table from clipboard' [] {
    # pbpaste | lines | parse -r '(?P<col>.*)\t(?P<col2>.*)'
    # pbpaste | lines | split column '\t'
    let _table = ( pbpaste | from tsv )
    # let _col = $_table | columns 
}

# Copy table from the pipe into clipboard (in tsv format)
export def 'copy table to clipboard' [] {
    let _table =  $in
    $_table | to tsv | pbcopy
    echo $_table
}

export def 'view temp cyberlinks table' [] {
    open $env.cy.path.cyberlinks-csv-temp 
}