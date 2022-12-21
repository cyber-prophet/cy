# Cy - the nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
# Git: https://github.com/cyber-prophet/cy
# 
# Use:
# > overlay use ~/apps-files/github/cy/cy.nu as cy -p

def 'banner' [] {
    echo "
     ____ _   _    
    / ___) | | |   
   ( (___| |_| |   
    \\____)\\__  |   cy nushell module is loaded
         (____/    have fun"
}


def parse-ipfs-table [] {parse -r '(?<status>\w+) (?<to>Qm\w{44}) (?<filename>.+)'}

def is-cid [particle: string] {
    ($particle =~ '^Qm\w{44}$') 
}

def is-connected []  {
    (do -i {fetch https://www.iana.org} | describe) == 'raw input'
}

export-env { 
    banner
    let path1 = $env.HOME + '/cy/cy_config.json'
    let-env cy = try {
        open ($path1)
    } catch {
        echo 'cy_config.json is not found. Run "cy config"'
        echo ''
    }
}

# Create config JSON to set env variables, to use them as parameters in cyber cli
export def-env "config" [] {
    echo "This wizzard will walk you through setup of cy."
    let cy_home = ($env.HOME + '/cy/')

    let _exec = (input 'Choose the name of cyber executable (cyber or pussy): ')
    let _exec = (
        if ($_exec | is-empty) {
            'cyber'
        } else {
            $_exec
        }
    )

    echo "\nHere are the keys that you have:"

    let addr_table = (
        if ($_exec == 'cyber') {
            cyber keys list --output json | from json | flatten | select name address
        } else {
            pussy keys list --output json | from json | flatten | select name address
        }
    )

    echo $addr_table
    echo ''

    let address = (input 'Enter the address to send transactions from: ')
    let address = (
        if ($address | is-empty) {
            let def_address = ($addr_table | get address.0)
            $def_address
        } else {
            $address
        }
    )

    let chain_id = (if ($_exec == 'cyber') {'bostrom'} else {'space-pussy'})

    let ipfs_storage = (input 'Select the ipfs service to use (kubo, cyb.ai, both): ')
    let ipfs_storage = (if ($ipfs_storage | is-empty) {'cyb.ai'} else {$ipfs_storage})

    let temp_env = {
        'exec': $_exec
        'address': $address
        'chain-id': $chain_id
        'ipfs-storage': $ipfs_storage
        'path': {
            'cy_home': $cy_home
            'cy_temp': ($cy_home + 'temp/')
            'backups': ($cy_home + 'backups/')
            'cyberlinks-csv-temp': ($cy_home + 'cyberlinks_temp.csv')
            'cyberlinks-csv-archive': ($cy_home + 'cyberlinks_archive.csv')
            'tx-signed' : ($cy_home + 'temp/tx-signed.json')
            'tx-unsigned' : ($cy_home + 'temp/tx-unsigned.json')
        }
    } 
    
    mkdir $temp_env.path.cy_temp
    mkdir $temp_env.path.backups

    $temp_env | save ($temp_env.path.cy_home + 'cy_config.json')
    
    let-env cy = $temp_env

    if (
        not ($env.cy.path.cyberlinks-csv-temp | path exists)
    ) {
        "from,to" | save $env.cy.path.cyberlinks-csv-temp
    }

    if (
        not ($env.cy.path.cyberlinks-csv-archive | path exists)
    ) {
        "from,to,address,timestamp,txhash" | save $env.cy.path.cyberlinks-csv-archive
    }

    echo '\nJSON is updated. You can find below what was written there.\n'
    
    echo $env.cy
}

#################################################

# Pin a text particle
export def 'pin-text' [
    text?: string
] {
    let text = (
        (
            if ($text | is-empty) {$in} else {$text}
        ) 
        | into string # To coerce numbers into strings
    ) 

    let cid = if (
        ($env.cy.ipfs-storage == 'kubo') or ($env.cy.ipfs-storage == 'both')
        ) {(
            echo $text
            | ipfs add -Q 
            | str replace '\n' ''
        )} 
        
    let cid = if (
        ($env.cy.ipfs-storage == 'cyb.ai') or ($env.cy.ipfs-storage == 'both')
        ) {(
            echo $text 
            | curl --silent -X POST -F file=@- "https://io.cybernode.ai/add" 
            | from json 
            | get cid./
        )} else {
            $cid
        }

    echo $cid
}

# Pin files from the current folder to the local node, output the cyberlinks table
export def 'pin-files' [
    ...files: string                # filenames to add into the local ipfs node
    --cyberlink_filenames_to_their_files
    --dont_append_to_cyberlinks_temp_csv (-d)
] {
    let files = (
        if $files == [] {
            ls | where type == file | get name
        }
    )

    let cid_table = (
        $files 
        | each {|f| ipfs add $f} 
        | parse-ipfs-table 
    )

    let out_table = (
        if $cyberlink_filenames_to_their_files {(
            $cid_table.filename 
            | each {
                |it| pin-text $it 
                } 
            | wrap from 
            | merge {$cid_table}
        )} else {
            $cid_table
        }
    )

    if $dont_append_to_cyberlinks_temp_csv {
        $out_table
    } else {(
        $out_table 
        | temp-append
    )}
}

#################################################

# Add a 2-texts cyberlink to the temp table
export def 'link-texts' [
    text_from
    text_to
    --dont_append_to_cyberlinks_temp_csv (-d)
] {
    let cid_from = (pin-text $text_from)
    let cid_to = (pin-text $text_to)
    
    let $out_table = (
        [[from to 'from_text' 'to_text'];
        [$cid_from $cid_to $text_from $text_to]]
    )

    if $dont_append_to_cyberlinks_temp_csv {
        $out_table
    } else {
        $out_table | temp-append
    }
}

# Add a random chuck norris cyberlink to the temp table
export def 'link-chuck' [
    --dont_append_to_cyberlinks_temp_csv (-d)
] {
    let cid_from = (pin-text 'chuck norris')
    
    let quote = (fetch https://api.chucknorris.io/jokes/random).value 
    # echo $quote

    let cid_to = (pin-text $quote)
    
    let $_table = (
        [['from_text' 'to_text' from to];
        ['chuck norris' $quote $cid_from $cid_to]]
    )

    if $dont_append_to_cyberlinks_temp_csv {$_table} else {(
        $_table
        | temp-append
    )}
} 

# Add a random quote cyberlink to the temp table
export def 'link-quote' [] {
    let q1 = (
        fetch -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json 
        | str replace "\\\\" "" 
        | from json
    )

    let quoteAuthor = (
        if $q1.quoteAuthor == '' {
            'quote'
        } else {
            $q1.quoteAuthor
        }
    )

    link-texts $quoteAuthor $q1.quoteText
}

#################################################

# Append cyberlinks to the temp table
export def 'temp-append' [
    cyberlinks?             # cyberlinks table
    --dont_show_out_table   
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    let cyberlinks = (
        $cyberlinks 
        | upsert date_time (
            date now 
            | date format '%y%m%d-%H%M'
        )
    )

    (
        temp-view 
        | append $cyberlinks 
        | save $env.cy.path.cyberlinks-csv-temp --force
    )

    if (not $dont_show_out_table)  { 
        temp-view 
    }
    
}

# View the temp cyberlinks table
export def 'temp-view' [] {
    open $env.cy.path.cyberlinks-csv-temp 
    | select from_text to_text from to date_time
}

# Empty the temp cyberlinks table
export def 'temp-clear' [] {
    let dt1 = (date now | date format '%Y%m%d-%H%M%S')
    let path2 = $env.cy.path.backups + 'cyberlinks_temp_' + $dt1 + '.csv'

    if (
        $env.cy.path.cyberlinks-csv-temp
        | path exists 
    ) {
        ^mv $env.cy.path.cyberlinks-csv-temp $path2
    }
    'from,to' | save $env.cy.path.cyberlinks-csv-temp --force
}

#################################################

# Add a text particle into 'to' column of the temp cyberlinks table
export def 'link-to' [
    text: string  # a text to upload to ipfs
] {( 
    $in 
    | rename -c ['to' 'from'] 
    | upsert to (pin-text $text) 
    | select from to
)}

# Add a text particle into the 'from' column of the temp cyberlinks table
export def 'link-from' [
    text: string                    # a text to upload to ipfs
] {(
    $in 
    | upsert from (pin-text $text) 
    | select from to
)}

#################################################

def 'tx sign and broadcast' [] {
    if $env.cy.exec == 'cyber' {
        ( cyber tx sign $env.cy.path.tx-unsigned --from $env.cy.address  
            --chain-id $env.cy.chain-id 
            # --keyring-backend $env.cy.keyring-backend 
            --output-document $env.cy.path.tx-signed )

        cyber tx broadcast $env.cy.path.tx-signed --broadcast-mode block
    } else {
        ( pussy tx sign $env.cy.path.tx-unsigned --from $env.cy.address  
            --chain-id $env.cy.chain-id 
            # --keyring-backend $env.cy.keyring-backend 
            --output-document $env.cy.path.tx-signed )

        pussy tx broadcast $env.cy.path.tx-signed --broadcast-mode block
    }
}

# Create a custom unsigned cyberlinks transaction
def 'create tx json from temp cyberlinks' [] {
    let cyberlinks = (temp-view | select from to)

    let neuron = $env.cy.address

    let trans = ('{"body":{"messages":[
        {"@type":"/cyber.graph.v1beta1.MsgCyberlink",
        "neuron":"","links":[{"from":"","to":""}]}
        ],"memo":"","timeout_height":"0",
        "extension_options":[],"non_critical_extension_options":[]},
        "auth_info":{"signer_infos":[],"fee":
        {"amount":[],"gas_limit":"2000000","payer":"","granter":""}},
        "signatures":[]}' | from json
    )

    $trans 
    | upsert body.messages.neuron $neuron 
    | upsert body.messages.links $cyberlinks 
    | save $env.cy.path.tx-unsigned --force
}

# Create a tx from the temp cyberlinks table, sign and broadcast it
export def 'tx-send' [] {
    if not (is-connected) {
        error make {msg: "there is no internet!"}
    }

    create tx json from temp cyberlinks

    let var0 = (tx sign and broadcast)

    let _var = ( 
        $var0 
        | from json 
        | select raw_log code txhash
    )
    
    if $_var.code == 0 {
        (
            {'cy': 'cyberlinks should be successfully sent'} 
            | merge $_var 
            | select code txhash
        ) 

        (
            open $env.cy.path.cyberlinks-csv-archive 
            | append (
                temp-view 
                | upsert neuron $env.cy.address
            ) 
        | save $env.cy.path.cyberlinks-csv-archive --force
        )
        temp-clear

    } else {
        {'cy': 'error!' } | merge $_var 
    }
}

#################################################

# Copy a table from the pipe into clipboard (in tsv format)
export def 'copy-tsv' [] {
    let _table = $in
    echo $_table
    $_table | to tsv | pbcopy
}

# Paste a table from clipboard
export def 'paste-tsv' [] {
    let _table = ( pbpaste | from tsv )
    $_table
}

#################################################


# Upload values from a given column ('text' by default) to the local IPFS node and add a column with the new CIDs.
export def 'pin-column' [
    cyberlinks?: table
    --column_with_text: string = 'text' # a column name to take values from to upload to IPFS. If is ommited, the default value is 'text'
    --column_to_write_cid: string = 'from' # a column name to write CIDs to. If this option is ommited, the default value is 'from'
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    $cyberlinks 
    | upsert $column_to_write_cid {
        |it| $it 
        | get $column_with_text 
        | pin-text 
    }
}

#################################################

# An ordered list of cy commands
export def 'help' [] {
    echo "
cy config                Create config JSON to set env variables, to use them as parameters in cyber cli

cy pin-text              Pin a text particle 
cy pin-files             Pin files from the current folder to the local node, output the cyberlinks table

cy link-texts            Add a 2-texts cyberlink to the temp table
cy link-chuck            Add a random chuck norris cyberlink to the temp table
cy link-quote            Add a random quote cyberlink to the temp table

cy temp-append           Append cyberlinks to the temp table
cy temp-view             View the temp cyberlinks table
cy temp-clear            Empty the temp cyberlinks table

cy link-to               Add a text particle into 'to' column of the temp cyberlinks table
cy link-from             Add a text particle into the 'from' column of the temp cyberlinks table

cy tx-send               Create a tx from the temp cyberlinks table, sign and broadcast it

cy copy-tsv              Copy a table from the pipe into clipboard (in tsv format)
cy paste-tsv             Paste a table from clipboard

cy pin-column            Upload values from a given column ('text' by default) to the local IPFS node and add a column w
"
}