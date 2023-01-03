# Cy - the nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
# Git: https://github.com/cyber-prophet/cy
#
# Install/update to the latest version
# > mkdir ~/cy | fetch https://raw.githubusercontent.com/cyber-prophet/cy/main/cy.nu | save ~/cy/cy.nu -f
#
# Use:
# > overlay use ~/cy/cy.nu as cy -p -r

export-env { 
    banner
    let-env cy = try {
        open ($env.HOME + '/cy/cy_config.json')
    } catch {
        'file "cy_config.json" was not found. Run "cy config"' | cprint -c green_underline
    }
}

# Create config JSON to set env variables, to use them as parameters in cyber cli
export def-env 'config' [] {
    'This wizzard will walk you through the setup of cy.' | cprint -c green_underline -a 2
    'If you skip entering the value - the default will be used.' | cprint -c yellow_italic
    let cy_home = ($env.HOME + '/cy/')

    'Choose the name of executable (cyber or pussy). ' | cprint --before 1 --after 0
    'Default: cyber' | cprint -c yellow_italic

    let _exec = if-empty (input) -a 'cyber'

    'Here are the keys that you have:' | cprint -b 1

    let addr_table = (
        ^($_exec) keys list --output json 
        | from json 
        | flatten 
        | select name address
    )

    print $addr_table
    
    let address_def = ($addr_table | get address.0)

    'Enter the address to send transactions from. ' | cprint --before 1 --after 0
    $'Default: ($address_def)' | cprint -c yellow_italic
    let address = if-empty (input) -a $address_def


    let chain_id_def = (if ($_exec == 'cyber') {
            'bostrom'
        } else {
            'space-pussy'
        }
    )

    'Enter the chain-id for interacting with the blockchain. ' | cprint --before 1 --after 0
    $'Default: ($chain_id_def)' | cprint -c yellow_italic
    let chain_id = if-empty (input) -a $chain_id_def


    let rpc_def = (if ($_exec == 'cyber') {
        'https://rpc.bostrom.cybernode.ai:443'
    } else {
        'https://rpc.space-pussy.cybernode.ai:443'
    }
)

    'Enter the address of RPC api for interacting with the blockchain. ' | cprint --before 1 --after 0
    $'Default: ($rpc_def)' | cprint -c yellow_italic
    let rpc_address = if-empty (input) -a $rpc_def


    'Select the ipfs service to use (kubo, cybernode, both). ' | cprint --before 1 --after 0
    'Default: cybernode' | cprint -c yellow_italic

    let ipfs_storage = if-empty (input) -a 'cybernode'


    let temp_env = {
        'exec': $_exec
        'address': $address
        'chain-id': $chain_id
        'ipfs-storage': $ipfs_storage
        'node': $rpc_address
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

    $temp_env | save ($temp_env.path.cy_home + 'cy_config.json') --force
    
    let-env cy = $temp_env

    if (
        not ($env.cy.path.cyberlinks-csv-temp | path exists)
    ) {
        'from,to' | save $env.cy.path.cyberlinks-csv-temp
    }

    if (
        not ($env.cy.path.cyberlinks-csv-archive | path exists)
    ) {
        'from,to,address,timestamp,txhash' | save $env.cy.path.cyberlinks-csv-archive
    }

    'config JSON was updated. You can find below what was written there.' | cprint -c green_underline
    
    echo $env.cy
}

#################################################

# Pin a text particle
export def 'pin-text' [
    text_param?: string
] {
    let text_in = $in
    
    let text = (
        (
            if ($text_in | is-empty) {$text_param} else {$text_in}
        ) 
        | into string # To coerce numbers into strings
    ) 

    let cid = if (is-cid $text) {$text} else {
        let cid = if (
            ($env.cy.ipfs-storage == 'kubo') or ($env.cy.ipfs-storage == 'both')
            ) {
                $text
                | ipfs add -Q 
                | str replace '\n' ''
            } 
            
        let cid = if (
            ($env.cy.ipfs-storage == 'cybernode') or ($env.cy.ipfs-storage == 'both')
            ) {
                $text 
                | curl --silent -X POST -F file=@- 'https://io.cybernode.ai/add' 
                | from json 
                | get cid./
            } else {
                $cid
            }

        $cid
    }

    $cid
}

# Pin files from the current folder to the local node, output the cyberlinks table
export def 'pin-files' [
    ...files: string                # filenames to add into the local ipfs node
    --cyberlink_filenames_to_their_files (-n)
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
        if $cyberlink_filenames_to_their_files {
            $cid_table.filename 
            | each {
                |it| pin-text $it 
                } 
            | wrap from 
            | merge $cid_table
        } else {
            $cid_table
        }
    )

    if $dont_append_to_cyberlinks_temp_csv {
        $out_table
    } else {
        $out_table 
        | tmp-append
    }
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
        [['from_text' 'to_text' from to];
        [$text_from $text_to $cid_from $cid_to]]
    )

    if $dont_append_to_cyberlinks_temp_csv {
        $out_table
    } else {
        $out_table | tmp-append
    }
}

# Add a random chuck norris cyberlink to the temp table
export def 'link-chuck' [
    --dont_append_to_cyberlinks_temp_csv (-d)
] {
    # let cid_from = (pin-text 'chuck norris')
    let cid_from = 'QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1'
    
    let quote = (
        "> " + (fetch https://api.chucknorris.io/jokes/random).value + 
        "\n\n" + "via [Chucknorris.io](https://chucknorris.io)"
    )

    $quote | cprint -f "="

    let cid_to = (pin-text $quote)
    
    let $_table = (
        [['from_text' 'to_text' from to];
        ['chuck norris' $quote $cid_from $cid_to]]
    )

    if $dont_append_to_cyberlinks_temp_csv {
            $_table
        } else {(
            $_table
            | tmp-append
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
        if $q1.quoteAuthor == "" {
            ""
        } else {
            "\n>> " + $q1.quoteAuthor
        }
    )

    let quote = (
        "> " + $q1.quoteText + 
        $quoteAuthor +
        "\n\n" + "via [forismatic.com](https://forismatic.com)"
    )

    $quote | cprint -f '='

    link-texts 'quote' $quote
    # link-texts 'QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna' $quote
}

#################################################

# Append cyberlinks to the temp table
export def 'tmp-append' [
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
        tmp-view -d 
        | append $cyberlinks 
        | tmp-replace
    )
}

# Replace cyberlinks in the temp table
export def 'tmp-replace' [
    cyberlinks?             # cyberlinks table
    --dont_show_out_table (-d)   
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    (
        $cyberlinks 
        | save $env.cy.path.cyberlinks-csv-temp --force
    )

    if (not $dont_show_out_table)  {
        tmp-view
    }
    
}

# View the temp cyberlinks table
export def 'tmp-view' [
    --disable_title (-d) # show title
] {
    let tmp_links = open $env.cy.path.cyberlinks-csv-temp 

    let links_count = ($tmp_links | length)

    if (not $disable_title) {
        if $links_count == 0 {
            $"The temp cyberlinks table ($env.cy.path.cyberlinks-csv-temp) is empty now!" | cprint -c red
            $"You can add cyberlinks to it manually or by using commands like 'cy link-texts'" | cprint
        } else {
            $"There are ($links_count) cyberlinks in the temp table:" | cprint -c green_underline
        }
    }

    $tmp_links
}

# Empty the temp cyberlinks table
export def 'tmp-clear' [] {
    let dt1 = (date now | date format '%Y%m%d-%H%M%S')
    let path2 = $env.cy.path.backups + 'cyberlinks_temp_' + $dt1 + '.csv'

    if (
        $env.cy.path.cyberlinks-csv-temp
        | path exists 
    ) {
        ^mv $env.cy.path.cyberlinks-csv-temp $path2
    }

    'from,to,from_text,to_text' | save $env.cy.path.cyberlinks-csv-temp --force
}

#################################################

# Add a text particle into the 'to' column of the temp cyberlinks table
export def 'tmp-link-to' [
    text: string  # a text to upload to ipfs
] {
    tmp-view -d
    | upsert to (pin-text $text)
    | upsert to_text $text 
    | tmp-replace
}

# Add a text particle into the 'from' column of the temp cyberlinks table
export def 'tmp-link-from' [
    text: string                    # a text to upload to ipfs
] {
    tmp-view -d
    | upsert from (pin-text $text) 
    | upsert from_text $text
    | tmp-replace
}

# Pin values from a given column to IPFS node and add a column with their CIDs
export def 'tmp-pin-col' [
    --column_with_text: string = 'text' # a column name to take values from to upload to IPFS. If is ommited, the default value is 'text'
    --column_to_write_cid: string = 'from' # a column name to write CIDs to. If this option is ommited, the default value is 'from'
] {


    let new_text_col_name = ( $column_to_write_cid + '_text' )

    tmp-view -d 
    | upsert $column_to_write_cid {
        |it| $it | get $column_with_text | pin-text 
        }
    | rename -c [$column_with_text $new_text_col_name]
    | tmp-replace

}

# Check if any of the links in tmp table exist
def 'link-exist' [
    from
    to
    neuron
] {
    let out1 = (do -i {(
        ^($env.cy.exec) query rank is-exist $from $to $neuron 
        --output json 
        --node $env.cy.node 
        | complete 
    )})

    if $out1.exit_code == 0 {
        $out1.stdout | from json | get "exist"
    } else {
        false
    }
}

# Remove existed cyberlinks from the temp cyberlinks table
export def 'tmp-remove-existed' [] {
    let links_with_status = (
        tmp-view -d 
        | upsert link_exist {
            |row| (link-exist  $row.from $row.to $env.cy.address)
        }
    )

    let existed_links = (
        $links_with_status 
        | filter {|x| $x.link_exist} 
    )

    let existed_links_count = ($existed_links | length)

    if $existed_links_count > 0 {
        
        $"($existed_links_count) cyberlink/s was/were already created by ($env.cy.address)" | cprint 
        print $existed_links
        "So they were removed from the temp table!" | cprint -c red -a 2
        
        $links_with_status | filter {|x| not $x.link_exist} | tmp-replace
    } else {
        "There are no cyberlinks from the tmp table existed in the blockchain" | cprint
    }
}

#################################################

# Create a custom unsigned cyberlinks transaction
def 'create tx json from temp cyberlinks' [] {
    let cyberlinks = (tmp-view -d | select from to)

    let neuron = $env.cy.address

    let trans = (
        '{"body":{"messages":[
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

def 'tx sign and broadcast' [] {
    ( 
        ^($env.cy.exec) tx sign $env.cy.path.tx-unsigned --from $env.cy.address  
        --chain-id $env.cy.chain-id 
        --node $env.cy.node
        # --keyring-backend $env.cy.keyring-backend 
        --output-document $env.cy.path.tx-signed 

        | complete 
        | if ($in.exit_code != 0) {
            error make {msg: 'Error of signing the transaction!'}
        }
    )

    let broadcast_complete = (
        ^($env.cy.exec) tx broadcast $env.cy.path.tx-signed 
        --broadcast-mode block 
        --output json 
        --node $env.cy.node
        | complete 
    )

    if ($broadcast_complete.exit_code != 0 ) {
        error make {
            msg: 'exit code is not 0'
        }
    } else {
        $broadcast_complete.stdout
    }
}

# Create a tx from the temp cyberlinks table, sign and broadcast it
export def 'tx-send' [] {
    if not (is-connected) {
        error make {msg: 'there is no internet!'}
    }

    create tx json from temp cyberlinks

    let var0 = tx sign and broadcast
    let cyberlinks_count = (tmp-view -d | length)

    let _var = ( 
        $var0 
        | from json 
        | select raw_log code txhash
    )
    
    if $_var.code == 0 {
        {'cy': $'($cyberlinks_count) cyberlinks should be successfully sent'} 
        | merge $_var 
        | select cy code txhash

        open $env.cy.path.cyberlinks-csv-archive 
        | append (
            tmp-view -d 
            | upsert neuron $env.cy.address
        ) 
        | save $env.cy.path.cyberlinks-csv-archive --force

        tmp-clear

    } else {
        {'cy': 'If the problem is with the already existed cyberlinks, use "cy tmp-remove-existed"' } 
        | merge $_var 
    }
}

#################################################

# Copy a table from the pipe into clipboard (in tsv format)
export def 'tsv-copy' [] {
    let _table = $in
    echo $_table

    $_table | to tsv | pbcopy
}

# Paste a table from clipboard
export def 'tsv-paste' [] {
    pbpaste | from tsv
}

#################################################

# Update cy to the latest version
export def 'update-cy' [
    --development_version (-d)
] {

    let url = if $development_version {
        "https://raw.githubusercontent.com/cyber-prophet/cy/dev/cy.nu" 
    } else {
        "https://raw.githubusercontent.com/cyber-prophet/cy/main/cy.nu" 
    }

    mkdir ~/cy 
    | fetch $url
    | save ~/cy/cy.nu -f
    
    # overlay below freezes nu 0.7.3 inside Alacritty Version 0.11.0 (8dbaa0b)
    # overlay use ~/cy/cy.nu as cy -p -r   

}

# An ordered list of cy commands
export def 'help' [
    --to_md (-m) #export table as markdown
] {
    let text = (
        view-source cy 
        | parse -r "(\n(# )(?<desc>.*?)(?:=?\n)export (def|def.env) '(?<command>.*)')"
        | select command desc 
        | upsert command {|row index| ('cy ' + $row.command)}
    )
    
    if $to_md {
        $text | to md 
    } else {
        $text | table --width (term size).columns
    }
}

#################################################

def 'banner' [] {
    print "
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

# Print string colourfully
def cprint [
    ...args
    --color (-c): string@'nu-complete colors' = 'default'
    --frame (-f): string
    --before (-b): int = 0
    --after (-a): int = 1
] {
    mut text = if ($args == []) {
        $in
    } else {
        $args | str join ' '
    }

    if $frame != null {
        let width = (term size | get columns) - 2
        $text = (
            (" " | str rpad -l $width -c $frame) + "\n" +
            (
                $text 
                # | split row "\n" 
                # | each {
                #     str replace "(^.)" "    $1"
                # } | str collect "\n"
            ) + "\n" +
            (" " | str rpad -l $width -c $frame)
        )
    }
    seq 1 $before | each {|i| print ""}
    $text | print $"(ansi $color)($in)(ansi reset)" -n 
    seq 1 $after | each {|i| print ""}
}

def 'nu-complete colors' [] {
    ansi --list | get name | each while {|it| if $it != 'reset' {$it} }
}

def 'if-empty' [
    value?
    --alternative (-a): any
] {
     (
         if ($value | is-empty) {
             $alternative
         } else {
             $value
         }
     )
 }
