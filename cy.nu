# Cy - nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
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
    let-env cy = if ($path1 | path exists ) {
        open ($path1)
    } else {
        echo 'cy_config.json is not found. Run "cy config"'
        ''
    }
}

# Create config JSON to set env varables, to use as parameters
export def-env "config" [] {

    let home = ($env.HOME + '/cy/')
    # let old = (open ($home + 'config.json'))

    let _exec = (input 'Choose cyber executable name (*cyber* or pussy): ')
    let _exec = (
        if ($_exec | is-empty) {
            'cyber'
        } else {
            $_exec
        }
    )

    let address = (input 'Enter address to send transactions from: ')
    let address = (
        if ($address | is-empty) {
            'bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel'
        } else {
            $address
        }
    )

    let backend = (input 'Enter keyring backend: ')
    let backend = (if ($backend | is-empty) {'os'} else {$backend})

    # let chain_id = (input 'Enter chain-id: ')
    # let chain_id = (if ($chain_id | is-empty) {'bostrom'} else {$chain_id})
    let chain_id = (if ($_exec == 'cyber') {'bostrom'} else {'space-pussy'})

    let temp_env = {
        'exec': $_exec
        'address': $address
        'keyring-backend': $backend
        'chain-id': $chain_id
        'path': {
            'home': $home
            'backup_folder': ($home + 'backup/')
            'cyberlinks-csv-temp': ($home + 'cyberlinks_temp.csv')
            'cyberlinks-csv-archive': ($home + 'cyberlinks_archive.csv')
            'tx-signed' : ($home + 'temp/tx-signed.json')
            'tx-unsigned' : ($home + 'temp/tx-unsigned.json')
        }
    } 
    
    mkdir $temp_env.path.home
    mkdir $temp_env.path.backup_folder

    $temp_env | save ($temp_env.path.home + 'cy_config.json')
    
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

    echo ''
    echo 'JSON is updated'
    echo ''
    echo $env.cy
}

#################################################

# Create text particle and pin it to local node
export def 'pin' [
    text?: string
] {

    let text = if ($text | is-empty) {$in} else {$text}

    echo ( $text | into string ) | 
        ipfs add -Q | 
        str replace '\n' ''
}


# Add 2 texts cyberlink to temp table
export def 'append-cl-texts' [
    text_from
    text_to
    --dont_append_to_cyberlinks_temp_csv (-d)
] {
    let cid_from = (pin $text_from)
    let cid_to = (pin $text_to)
    
    let $out_table = (
        [[from to 'from_text' 'to_text'];
        [$cid_from $cid_to $text_from $text_to]]
    )

    if $dont_append_to_cyberlinks_temp_csv {
        $out_table
    } else {
        $out_table | append-cl-pipe
    }
}


# Append cyberlinks from pipe or parameters to temp table
export def 'append-cl-pipe' [
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


# Add files from folder to ipfs, create table. Without parameters all files will be added
export def 'pin-files' [
    ...files: string                # filenames to add into local ipfs node
    --cyberlink_filenames_to_their_files
    --dont_append_to_cyberlinks_temp_csv (-d)
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
                    |it| pin $it 
                } | 
                wrap from | 
                merge {$cid_table}
        } else {
            $cid_table
        }
    )

    if $dont_append_to_cyberlinks_temp_csv {
        $out_table
    } else {
        $out_table | append-cl-pipe
    }

}

# Add random quote cyberlink to temp table
export def 'append-cl-forismatic' [] {
    let q1 = (
        fetch -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json |
        str replace "\\\\" "" | 
        from json
    )

    let quoteAuthor = (
        if $q1.quoteAuthor == '' {
            'quote'
        } else {
            $q1.quoteAuthor
        }
    )

    append-cl-texts $quoteAuthor $q1.quoteText
}

# Add chuck norris cyberlink to temp table
export def 'append-cl-chuck' [
    --dont_append_to_cyberlinks_temp_csv (-d)
] {
    let cid_from = (pin 'chuck norris')
    
    let quote = (fetch https://api.chucknorris.io/jokes/random).value 
    # echo $quote

    let cid_to = (pin $quote)
    
    let $_table = (
        [[from to 'from_text' 'to_text'];
        [$cid_from $cid_to 'chuck norris' $quote]]
    )

    if $dont_append_to_cyberlinks_temp_csv {$_table} else {
        $_table | append-cl-pipe
    }
} 


# Add text particle into 'from' column of local_cyberlinks table
export def 'link-from' [
    text: string                    # Text to upload to ipfs
] {
    $in | 
        upsert from (pin $text) |
        select from to
}

# Add text particle into 'to' column of local_cyberlinks table
export def 'link-to' [
    text: string                    # Text to upload to ipfs
] { 
    $in | 
        rename -c ['to' 'from'] | 
        upsert to (pin $text) |
        select from to
}


# Upload values from the given column ('text' by default) to the local IPFS node and add the column with the new CIDs.
export def 'pin-column' [
    cyberlinks?: table
    --column_with_text: string = 'text' # column name to take values from to upload to IPFS. If is ommited default value is 'text'
    --column_to_write_cid: string = 'from' # column name to write CIDs to. If is ommited default value is 'from'
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    $cyberlinks | 
        upsert $column_to_write_cid {
            |it| $it |
                get $column_with_text |
                pin 
        }
}


# Empty temp cyberlinks table
export def 'clear-temp' [] {

    let dt1 = (date now | date format '%Y%m%d-%H%M%S')
    let path2 = $env.cy.path.home + 'backup/' + 'cyberlinks_temp_' + $dt1 + '.csv'

    if ($env.cy.path.cyberlinks-csv-temp | path exists ) {
        ^mv $env.cy.path.cyberlinks-csv-temp $path2
    }
    'from,to' | save $env.cy.path.cyberlinks-csv-temp
}

#################################################

# Paste table from clipboard
export def 'paste-tsv' [] {
    let _table = ( pbpaste | from tsv )
    $_table
}

# Copy table from the pipe into clipboard (in tsv format)
export def 'copy-tsv' [] {
    let _table =  $in
    echo $_table
    $_table | to tsv | pbcopy
}

# View current temp cyberlinks table
export def 'view-temp' [] {
    open $env.cy.path.cyberlinks-csv-temp 
}

#################################################

# Create custom tx-unsigned cyberlinks transaction
def 'create tx json from temp cyberlinks' [
    # cyberlinks?                     # the table of cyberlinks
    # --neuron: string                # address of neuron who will create cyberlinks
] {
    let cyberlinks = (open $env.cy.path.cyberlinks-csv-temp | select from to)

    # let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}
    # let neuron = if ($neuron | is-empty) { $env.cy.address } else {$neuron}
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

    $trans | 
        upsert body.messages.neuron $neuron | 
        upsert body.messages.links $cyberlinks | 
        save $env.cy.path.tx-unsigned
}

def 'tx sign and broadcast' [] {
    if $env.cy.exec == 'cyber' {
        (cyber tx sign $env.cy.path.tx-unsigned --from $env.cy.address  
            --chain-id $env.cy.chain-id 
            --keyring-backend $env.cy.keyring-backend 
            --output-document $env.cy.path.tx-signed)

        cyber tx broadcast $env.cy.path.tx-signed --broadcast-mode block
    } else {
        (pussy tx sign $env.cy.path.tx-unsigned --from $env.cy.address  
            --chain-id $env.cy.chain-id 
            --keyring-backend $env.cy.keyring-backend 
            --output-document $env.cy.path.tx-signed)

        pussy tx broadcast $env.cy.path.tx-signed --broadcast-mode block
    }
}

# Create sign and broadcast transaction
export def 'tx-send' [] {
    if not (is-connected) {
        error make {msg: "there is no internet!"}
    }

    create tx json from temp cyberlinks

    let var0 = (tx sign and broadcast)

    let _var = ( 
        $var0 | 
        from json | 
        select raw_log code txhash
    )
    
    if $_var.code == 0 {
        {'cy': 'cyberlinks should be successfully sent'} | 
            merge {
                $_var | select code txhash 
            }
        

        open $env.cy.path.cyberlinks-csv-archive |
            append (
                open $env.cy.path.cyberlinks-csv-temp | 
                upsert neuron $env.cy.address
            ) |
            save $env.cy.path.cyberlinks-csv-archive

        clear-temp

    } else {
        {'cy': 'error!' } | 
            merge {
                $_var 
            }
    }
}
