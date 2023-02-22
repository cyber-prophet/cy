# Cy - the nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy)
# Git: https://github.com/cyber-prophet/cy
#
# Install/update to the latest version
# > mkdir ~/cy | http get https://raw.githubusercontent.com/cyber-prophet/cy/main/cy.nu | save ~/cy/cy.nu -f
#
# Use:
# > overlay use ~/cy/cy.nu -p -r

export def main [] { help }

export-env { 
    banner
    let-env cy = try {
        open $"($env.HOME)/cy/config/default.yaml"
    } catch {
        'file "/config/default.yaml" was not found. Run "cy config new"' | cprint -c green_underline
    }
    let-env cy_cache = null
}

# Pin a text particle
export def 'pin text' [
    text_param?: string
    --only_hash
] {
    let text_in = $in
    
    let text = (
        (
            if ($text_in | is-empty) {$text_param} else {$text_in}
        ) 
        | into string # To coerce numbers into strings
    ) 

    let cid = if (is-cid $text) {
        $text
    } else {
        if $only_hash {
            $text
            | ipfs add -Q --only-hash
            | str replace '\n' ''
        } else {
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
    }

    $cid
}

# Pin files from the current folder to the local node, output the cyberlinks table
export def 'pin files' [
    ...files: string                # filenames to add into the local ipfs node
    --link_filenames (-n)
    --disable_append (-d)
] {
    let files = (
        if $files == [] {
            ls | where type == file | get name
        } else {
            $files
        }
    )

    let cid_table = (
        $files 
        | each {|f| ipfs add $f -Q | str replace '\n' ''} 
        | wrap to
    )

    let out_table = (
        if $link_filenames {
            $files
            | each { |it| pin text $it } 
            | wrap from 
            | merge $cid_table
        } else {
            $cid_table
        }
    )

    if $disable_append {
        $out_table
    } else {
        $out_table 
        | tmp append
 }
}

# Add a 2-texts cyberlink to the temp table
export def 'link texts' [
    text_from
    text_to
    --disable_append (-d)
] {
    let cid_from = (pin text $text_from)
    let cid_to = (pin text $text_to)
    
    let $out_table = (
        [['from_text' 'to_text' from to];
        [$text_from $text_to $cid_from $cid_to]]
    )

    if $disable_append {
        $out_table
    } else {
        $out_table | tmp append
 }
}

# Add a tweet
export def 'tweet' [
    text_to
    --disable_send (-d)
] {
    # let cid_from = pin text "tweet"
    let cid_from = 'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx'
    let cid_to = (pin text $text_to)
    
    let $out_table = (
        [
            ['from_text', 'to_text', from, to];
            ['tweet', $text_to, $cid_from, $cid_to]
        ]
    )

    if (not $disable_send) {
        $out_table | tmp send tx
    } else {
        $out_table | tmp append
 }
}

# Add a random chuck norris cyberlink to the temp table
export def 'link chuck' [
    --disable_append (-d)
] {
    # let cid_from = (pin text 'chuck norris')
    let cid_from = 'QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1'
    
    let quote = (
        "> " + (http get https://api.chucknorris.io/jokes/random).value + 
        "\n\n" + "via [Chucknorris.io](https://chucknorris.io)"
    )

    $quote | cprint -f "="

    let cid_to = (pin text $quote)
    
    let $_table = (
        [['from_text' 'to_text' from to];
        ['chuck norris' $quote $cid_from $cid_to]]
    )

    if $disable_append {
            $_table
        } else {
            $_table | tmp append
 }
} 

# Add a random quote cyberlink to the temp table
export def 'link quote' [] {
    let q1 = (
        http get -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json 
        | str replace "\\\\" "" 
        | from json
    )

    let quoteAuthor = (
        if $q1.quoteAuthor == "" {
            ""
        } else {
            "\n\n>> " + $q1.quoteAuthor
        }
    )

    let quote = (
        "> " + $q1.quoteText + 
        $quoteAuthor +
        "\n\n" + "via [forismatic.com](https://forismatic.com)"
    )

    $quote | cprint -f '='

    link texts 'quote' $quote
    # link texts 'QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna' $quote
}

# View the temp cyberlinks table
export def 'tmp view' [
    --quiet (-q) # Don't print info
] {
    let tmp_links = open $"($env.HOME)/cy/cyberlinks_temp.csv" 

    let links_count = ($tmp_links | length)

    if (not $quiet) {
        if $links_count == 0 {
            $"The temp cyberlinks table ($"($env.HOME)/cy/cyberlinks_temp.csv") is empty." | cprint -c yellow
            $"You can add cyberlinks to it manually or by using commands like 'cy link texts'" | cprint
        } else {
            $"There are ($links_count) cyberlinks in the temp table:" | cprint -c green_underline
        }
    }

    $tmp_links
}

# Append cyberlinks to the temp table
export def 'tmp append' [
    cyberlinks?             # cyberlinks table
    --dont_show_out_table   
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    let cyberlinks = (
        $cyberlinks 
        | upsert date_time (
            date now 
            | date format '%y%m%d-%H%M%S'
        )
    )

    (
        tmp view -q 
        | append $cyberlinks 
        | tmp replace
    )
}

# Replace cyberlinks in the temp table
export def 'tmp replace' [
    cyberlinks?             # cyberlinks table
    --dont_show_out_table (-d)   
] {
    let cyberlinks = if ($cyberlinks | is-empty) {$in} else {$cyberlinks}

    (
        $cyberlinks 
        | save $"($env.HOME)/cy/cyberlinks_temp.csv" --force
    )

    if (not $dont_show_out_table)  {
        tmp view -q
    }
    
}

# Empty the temp cyberlinks table
export def 'tmp clear' [] {
    backup_fn $"($env.HOME)/cy/cyberlinks_temp.csv" 

    'from,to,from_text,to_text' | save $"($env.HOME)/cy/cyberlinks_temp.csv" --force
    # print "TMP-table is clear now."
}

# Add a text particle into the 'to' column of the temp cyberlinks table
export def 'tmp link to' [
    text: string # a text to upload to ipfs
    # --non-empty # fill non-empty only
] {
    let in_links = $in
    let links = if ($in_links == null) {
        tmp view -q
    } else {
        $in_links
    }

    let result = (
        $links
        | upsert to (pin text $text)
        | upsert to_text $text 
    )

    if ($in_links == null) {
        $result | tmp replace
    } else {
        $result
    }
}

# Add a text particle into the 'from' column of the temp cyberlinks table
export def 'tmp link from' [
    text: string # a text to upload to ipfs
    # --non-empty # fill non-empty only
] {
    let in_links = $in
    let links = if ($in_links == null) {
        tmp view -q
    } else {
        $in_links
    }

    let result = (
        $links
        | upsert from (pin text $text) 
        | upsert from_text $text
    )

    if ($in_links == null) {
        $result | tmp replace
    } else {
        $result
    }
}

# Pin values from a given column to IPFS node and add a column with their CIDs
export def 'tmp pin col' [
    --column_with_text: string = 'text' # a column name to take values from to upload to IPFS. Default is 'text
    --column_to_write_cid: string = 'from' # a column name to write CIDs to. Default is 'from'
] {


    let new_text_col_name = ( $column_to_write_cid + '_text' )

    tmp view -q 
    | upsert $column_to_write_cid {
        |it| $it | get $column_with_text | pin text 
        }
    | rename -c [$column_with_text $new_text_col_name]
    | tmp replace

}

# Check if any of the links in the tmp table exist
def 'link-exist' [
    from
    to
    neuron
] {
    let out1 = (do -i { 
        ^($env.cy.exec) query rank is-exist $from $to $neuron --output json --node $env.cy.rpc-address | complete 
    })

    if $out1.exit_code == 0 {
        $out1.stdout | from json | get "exist"
    } else {
        false
    }
}

# Remove existed cyberlinks from the temp cyberlinks table
export def 'tmp remove existed' [] {
    let links_with_status = (
        tmp view -q 
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
        
        $"($existed_links_count) cyberlink(s) was/were already created by ($env.cy.address)" | cprint 
        print $existed_links
        "So they were removed from the temp table!" | cprint -c red -a 2
        
        $links_with_status | filter {|x| not $x.link_exist} | tmp replace
    } else {
        "There are no cyberlinks from the tmp table for the current adress exist in the blockchain" | cprint
    }
}

# Create a custom unsigned cyberlinks transaction
def 'tx json create from cybelinks' [] {
    let cyberlinks = $in
    let cyberlinks = (
        $cyberlinks 
        | select from to 
        | uniq
    )

    let trans = (
        '{"body":{"messages":[
        {"@type":"/cyber.graph.v1beta1.MsgCyberlink",
        "neuron":"","links":[{"from":"","to":""}]}
        ],"memo":"cy","timeout_height":"0",
        "extension_options":[],"non_critical_extension_options":[]},
        "auth_info":{"signer_infos":[],"fee":
        {"amount":[],"gas_limit":"23456789","payer":"","granter":""}},
        "signatures":[]}' | from json
    )

    $trans 
    | upsert body.messages.neuron $env.cy.address 
    | upsert body.messages.links $cyberlinks 
    | save $"($env.HOME)/cy/temp/tx-unsigned.json" --force
}

def 'tx sign and broadcast' [] {
    ( 
        ^($env.cy.exec) tx sign $"($env.HOME)/cy/temp/tx-unsigned.json" --from $env.cy.address  
        --chain-id $env.cy.chain-id 
        --node $env.cy.rpc-address
        # --keyring-backend $env.cy.keyring-backend 
        --output-document $"($env.HOME)/cy/temp/tx-signed.json" 

        | complete 
        | if ($in.exit_code != 0) {
            error make {msg: 'Error of signing the transaction!'}
        }
    )

    let broadcast_complete = (
        ^($env.cy.exec) tx broadcast $"($env.HOME)/cy/temp/tx-signed.json" 
        --broadcast-mode block 
        --output json 
        --node $env.cy.rpc-address
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
export def 'tmp send tx' [] {
    let in_cyberlinks = $in

    if not (is-connected) {
        error make {msg: 'there is no internet!'}
    }

    let cyberlinks = if $in_cyberlinks == null {
        tmp view -q
    } else {
        $in_cyberlinks
    }

    let cyberlinks_count = ($cyberlinks | length)

    $cyberlinks | tx json create from cybelinks 

    let _var = ( 
        tx sign and broadcast
        | from json 
        | select raw_log code txhash
    )
    
    if $_var.code == 0 {
        open $"($env.HOME)/cy/cyberlinks_archive.csv" 
        | append (
            $cyberlinks
            | upsert neuron $env.cy.address
        ) 
        | save $"($env.HOME)/cy/cyberlinks_archive.csv" --force

        if ($in_cyberlinks == null) {
            tmp clear
        } 

        {'cy': $'($cyberlinks_count) cyberlinks should be successfully sent'} 
        | merge $_var 
        | select cy code txhash
        
    } else if $_var.code == 2 {
        {'cy': $'Use (ansi yellow)"cy tmp remove existed"(ansi reset)' } 
        | merge $_var 
    } else {
        $_var
    }
}

# Copy a table from the pipe into clipboard (in tsv format)
export def 'tsv copy' [] {
    let _table = $in
    echo $_table

    $_table | to tsv | pbcopy
}

# Paste a table from clipboard
export def 'tsv paste' [] {
    pbpaste | from tsv
}

# Update cy to the latest version
export def 'update cy' [
    --branch: string@'nu-complete-git-branches' = 'main'
] {

    let url = $"https://raw.githubusercontent.com/cyber-prophet/($branch)/dev/cy.nu" 

    mkdir ~/cy 
    | http get $url
    | save ~/cy/cy.nu -f

}

# Get a passport by providing a neuron's address
export def 'passport get by address' [
    address
] { 
    let json = ($'{"active_passport": {"address": "($address)"}}')
    let pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    do -i {^cyber query wasm contract-state smart $pcontract $json --node https://rpc.bostrom.cybernode.ai:443 --output json | from json | get data}
}

# Get a passport by providing a neuron's nick
export def 'passport get by nick' [
    nickname
] { 
    let json = ($'{"passport_by_nickname": {"nickname": "($nickname)"}}')
    let pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    (
        ^cyber query wasm contract-state smart $pcontract $json 
        --node https://rpc.bostrom.cybernode.ai:443 --output json 
    ) | from json | get data
}

# Set a passport's particle for a given nickname
export def 'passport set particle' [
    nickname
    particle
] {
    let json = $'{"update_particle":{"nickname":"($nickname)","particle":"($particle)"}}'
    let pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    (
        ^cyber tx wasm execute $pcontract $json 
        --from $env.cy.address 
        --node https://rpc.bostrom.cybernode.ai:443 --output json 
    ) | from json 
}

# Create config JSON to set env variables, to use them as parameters in cyber cli
export def-env 'config new' [
    # config_name?: string@'nu-complete-config-names'
] {
    'This wizzard will walk you through the setup of CY.' | cprint -c green_underline -a 2
    'If you skip entering the value - the default will be used.' | cprint -c yellow_italic
    let cy_home = ($env.HOME + '/cy/')

    'Choose the name of executable (cyber or pussy). ' | cprint --before 1 --after 0
    'Default: cyber' | cprint -c yellow_italic

    let _exec = if-empty (input) -a 'cyber'

    let addr_table = (
        ^($_exec) keys list --output json 
        | from json 
        | flatten 
        | select name address
    )
        
    if ($addr_table | length) > 0 {
        'Here are the keys that you have:' | cprint -b 1
        print $addr_table
    } else {
        let error_text = (
            $'There are no addresses in ($_exec). To use CY you need to add one.' +
            $'You can find out how to add one by running the command "($_exec) keys add -h".' +
            $'After adding a key - come back and launch this wizzard again'
        )

        error make -u {msg: $error_text}
    help: $'try "($_exec) keys add -h"'
    }
    
    let address_def = ($addr_table | get address.0)

    'Enter the address to send transactions from. ' | cprint --before 1 --after 0
    $'Default: ($address_def)' | cprint -c yellow_italic
    let address = if-empty (input) -a $address_def

    let config_name = (
        $addr_table 
        | select address name 
        | transpose -r -d
        | get $address
        | $"($in)+($_exec)" 
    )

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
        'config-name': $config_name
        'exec': $_exec
        'address': $address
        'chain-id': $chain_id
        'ipfs-storage': $ipfs_storage
        'rpc-address': $rpc_address
    } 
    

    make_default_folders_fn

    # ipfs files mkdir -p '/cy/cache'

    $temp_env | config save $config_name 

    if (
        not ($"($env.HOME)/cy/cyberlinks_temp.csv" | path exists)
    ) {
        'from,to' | save $"($env.HOME)/cy/cyberlinks_temp.csv"
    }

    if (
        not ($"($env.HOME)/cy/cyberlinks_archive.csv" | path exists)
    ) {
        'from,to,address,timestamp,txhash' | save $"($env.HOME)/cy/cyberlinks_archive.csv"
    }
}

# View a saved JSON config file
export def 'config view' [
    config_name?: string@'nu-complete-config-names'
] {
    if $config_name == null {
        print "current config is:"
        open $"($env.HOME)/cy/config/default.yaml"
    } else {
        let filename = $"($env.HOME)/cy/config/($config_name).yaml"
        open $filename 
    }
}

# Save the piped in JSON config file
export def-env 'config save' [
    config_name?: string@'nu-complete-config-names'
    --inactive # Don't activate current config
] {
    let in_config = $in

    let dt1 = datetime_fn

    let config_name = (
        if $config_name == null {
            "Enter the name of the config file to save. " | cprint --before 1 --after 0
            $"Default: ($dt1)" | cprint -c yellow_italic 
            input 
        } else {
            $config_name
        }
    )
    let config_name = (if-empty $config_name -a $dt1)

    mut file_name = $"($env.HOME)/cy/config/($config_name).yaml"

    let in_config = ($in_config | upsert config-name $config_name)

    if ($file_name | path exists) {
        let prompt1 = (input $"($file_name) exists. Do you want to overwrite it? \(y/n\) ")

        if $prompt1 == "y" {
            backup_fn $file_name
            $in_config | save $file_name -f
        } else {
            $file_name = $"($env.HOME)/cy/config/($dt1).yaml"
            $in_config | save $file_name
        }
    } else {
        $in_config | save $file_name -f
    }

    print $"($file_name) is saved"

    if (not $inactive) {
        $in_config | config activate
    }
}

# Activate config JSON
export def-env 'config activate' [
    config_name?: string@'nu-complete-config-names'
] {
    let inconfig = $in
    let file = (
        if $inconfig == $nothing {
            config view $config_name
        } else {
            $inconfig 
        }
    )

    let-env cy = $file

    "Config is loaded" | cprint -c green_underline
    $file | save $"($env.HOME)/cy/config/default.yaml" -f
    $file
}

export def 'search' [
    query
    --pretty (-P)
    --page (-p) = 0
] {
    let cid = if (is-cid $query) {
        $query
    } else {
        (pin text $query)
    }
    
    let serp = (
        ^($env.cy.exec) query rank search $cid $page 10 --output json
        | from json 
        | get result 
        | upsert particle {
            |i| let particle = (
                ipfs cat $i.particle -l 400
            ); 
            $particle 
            | file - 
            | if (
                $in | str contains "/dev/stdin: ASCII text"
            ) {
                $"($particle)\n(ansi grey)($i.particle)(ansi reset)"
            } else {
                $"Non-text particle. Is not supported yet.\n(ansi grey)($i.particle)(ansi reset)"
            }
        } 
        | select particle rank 
        )

    if $pretty {
        $serp 
        | table --width (term size | get columns)
    } else {
        $serp
    }


    # let results = (^($env.cy.exec) query rank search $cid 0 3 | from json | get result)

    # print $results
    
    # let cat1 = (
    #     $results.particle 
    #     |   par-each {
    #         |i| ipfs cat $i -l 400
    #     })
    # let type = ($cat1 | each {|i| $i | file -})
    
    # let safety = ($type | each {|i| if ($i | str contains "/dev/stdin: ASCII text") {
    #     "safe"
    # } } )

    # $cat1
}

export def 'search2' [
    query
    --pretty (-P)
    --page (-p) = 0
] {
    let cid = pin text $query --only_hash
    
    let serp = (
        ^($env.cy.exec) query rank search $cid $page 10 --output json
        | from json 
        | get result 
        | upsert particle {
            |i| request-file-from-cache $i.particle
        } 
        | select particle rank 
        )

    if $pretty {
        $serp 
        | table --width (term size | get columns)
    } else {
        $serp
    }
}

export def 'search3' [
    query
    --pretty (-P)
    --page (-p) = 0
] {
    # watch ~/cy/cache/ --glob=**/*.rs { cargo test }

    let cid = pin text $query --only_hash
    
    let serp = (
        ^($env.cy.exec) query rank search $cid $page 10 --output json
        | save $"~/cy/cache/search/($cid)-(date now|into int).json"
    )
}

export def 'search4' [
    query
    --pretty (-P)
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let cid = (pin text $query --only_hash)
    
    let results = (
        do -i {
            ^($env.cy.exec) query rank search $cid $page $results_per_page --output json
        }
        | from json 
    )

    if $results == null {
        print $"there is no search results for ($cid)"
        return
    }
    
    $results | save $"($env.HOME)/cy/cache/search/($cid)-(date now|into int).json"

    clear; print $"Searching ($env.cy.exec) for ($cid)";

    print (if $pretty {
        serp1 $results --pretty
    } else {
        serp1 $results
    })

    watch ~/cy/cache/queue { clear; print $"Searching ($env.cy.exec) for ($cid)"; serp1 $results --pretty }

}

def serp1 [
    results
    --pretty
] {

    let serp = (
        $results
        | get result 
        | upsert particle {
            |i| request-file-from-cache $i.particle
        } 
        | select particle rank 
    )

    $serp 
}

export def `download cid from ipfs` [
    cid
    --timeout = 300s
] {

    print $"cid to download ($cid)"
    let type1 = do -i {ipfs cat --timeout $timeout -l 400 $cid | file - | $in + "" | str replace "/dev/stdin: " ""}

    if ( $type1 =~ "(ASCII text)|(Unicode text)" ) {
            print $"found text ($type1) ($cid)"

            let result = (
                ipfs get --progress=false --timeout $timeout -o $"($env.HOME)/cy/cache/safe/($cid).txt" $cid 
                | complete
            )

            if ($result.exit_code == 0) {
                rm -f $"($env.HOME)/cy/cache/queue/($cid)" 
            }
        } else if ( $type1 == "empty" ) {
            print $"($cid) not found"
        } else {
            print $"found non-text ($cid) ($type1)"

            $type1 | save -f $"($env.HOME)/cy/cache/other/($cid).txt"

            rm -f $"($env.HOME)/cy/cache/queue/($cid)" 
        }

}

def 'download cid from gateway' [
    cid
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
] {
    let headers = (
        curl -s -I -m 60 $"($gate_url)($cid)"
        | lines
        | parse "{header}: {value}"
        | transpose -d -r -i
    )

    let type1 = ($headers | get -i 'Content-Type')
    if $type1 == 'text/plain; charset=utf-8' {
        http get $"($gate_url)($cid)" -m 60 | save -f $"($env.HOME)/cy/cache/safe/($cid).txt" 
    } else if ($type1 != null) {
        $type1 | save -f $"($env.HOME)/cy/cache/other/($cid).txt"
    }
    echo $type1
}


export def 'request-file-from-cache' [
    cid
] {
    let a1 = (
        do -i {
            open $"($env.HOME)/cy/cache/safe/($cid).txt"}
    )

    let a1 = if ($a1 == null) {
        (do -i {
            open $"($env.HOME)/cy/cache/other/($cid).txt"})
    } else {$a1}

    let a1 = if ($a1 == null) {
        (do -i {open $"($env.HOME)/cy/cache/queue/($cid)"})
    } else {$a1}

    let a1 = if ($a1 == null) {
        let message = $"($cid) is in the queue since (datetime_fn --pretty)"
        $message | save $"($env.HOME)/cy/cache/queue/($cid)"
        $message
    } else {
        $"($a1)"
    }

    (
        $a1 
        | str substring '0,400'
        | str replace "\n" "↩" --all 
        | $"($in)\n(ansi grey)($cid)(ansi reset)"
    )

}

export def `watch search folder` [] {
    watch ~/cy/cache/search { check-queue }
}

export def 'check-queue' [] {
    let files = (ls -s $"($env.HOME)/cy/cache/queue/")
    if ( ($files | length | inspect) > 0 ) {
        $files
        | get name -i
        | par-each {
            |i| download cid from ipfs $i
        }
    } else {
            "the queue is empty"
    }
}

export def `cache clear` [] {
    backup_fn $"($env.HOME)/cy/cache" 
    make_default_folders_fn
}

export def-env 'ber' [
    ...rest
    --seconds: int = 86400
    --exec: string
    --node: string
    --invcheckperiod: string
    --reserveacc: string
    --searchapi
    --force (-f)
    --home: string
    --overwrite
    --cpuprofile: string
    --events: string
    --instantiateonlyaddress: string
    --nobackup
    --xcrisisskipassertinvariants
    --algo: string
    --consensuscreate_empty_blocks
    --p2pprivate_peer_ids: string
    --help (-h)
    --maxmsgs: string
    --vestingamount: string
    --tracestore: string
    --db_backend: string
    --noadmin
    --consensuscreate_empty_blocks_interval: string
    --pruningkeeprecent: string
    --description: string
    --priv_validator_laddr: string
    --forzeroheight
    --wasmmemory_cache_size: string
    --keyringbackend: string
    --startingipaddress: string
    --proposal: string
    --hex
    --counttotal
    --interactive (-i)
    --grpconly
    --chainid: string
    --pruninginterval: string
    --height: string
    --moniker: string
    --cointype: string
    --depositor: string
    --status: string
    --instantiateeverybody: string
    --multisig: string
    --p2punconditional_peer_ids: string
    --offset: string
    --abci: string
    --from: string
    --allowedmessages: string
    --amino
    --limit: string
    --runas: string
    --upgradeinfo: string
    --page: string
    --halttime: string
    --gasadjustment: string
    --statesyncsnapshotkeeprecent: string
    --pruningkeepevery: string
    --feeaccount: string
    --minimumgasprices: string
    --p2pupnp
    --period: string
    --long
    --sequence (-s): string
    --reverse
    --transport: string
    --allowedvalidators: string
    --pruning: string
    --iavldisablefastnode
    --instantiatenobody: string
    --amount: string
    --keyringdir: string
    --admin: string
    --computegpu
    --unsafe
    --recover
    --commissionmaxrate: string
    --pubkey: string
    --packettimeouttimestamp: string
    --wasmquery_gas_limit: string
    --trace
    --overwrite (-o)
    --signmode: string
    --yes (-y)
    --statesyncsnapshotinterval: string
    --pagekey: string
    --voter: string
    --grpcwebenable
    --denyvalidators: string
    --type: string
    --rpcladdr: string
    --website: string
    --msgtype: string
    --securitycontact: string
    --offline
    --minselfdelegation: string
    --fast_sync
    --commissionmaxchangerate: string
    --p2pexternaladdress: string
    --jailallowedaddrs: string
    --newmoniker: string
    --address: string
    --denom: string
    --keepaddrbook
    --title: string
    --prove
    --log_format: string
    --rpcgrpc_laddr: string
    --broadcastmode (-b): string
    --consensusdouble_sign_check_height: string
    --p2ppex
    --outputdir (-o): string
    --absolutetimeouts
    --bech: string
    --ledger
    --pubkey (-p)
    --unsafeskipupgrades: string
    --packettimeoutheight: string
    --p2pseed_mode
    --periodlimit: string
    --accountnumber (-a): string
    --address (-a)
    --db_dir: string
    --device (-d)
    --note: string
    --output (-o): string
    --grpcaddress: string
    --gasprices: string
    --sequences: string
    --unarmoredhex
    --p2pseeds: string
    --nodedirprefix: string
    --gas: string
    --identity: string
    --haltheight: string
    --node: string
    --nodeid: string
    --outputdocument: string
    --label: string
    --commissionrate: string
    --nosort
    --generateonly
    --spendlimit: string
    --hdpath: string
    --vestingendtime: string
    --interblockcache
    --deposit: string
    --noautoincrement
    --genesistime: string
    --withtendermint
    --expiration: string
    --ascii
    --log_level: string
    --grpcwebaddress: string
    --fees: string
    --proxy_app: string
    --p2ppersistent_peers: string
    --rpcunsafe
    --signatureonly
    --timeoutheight: string
    --nodedaemonhome: string
    --v: string
    --gentxdir: string
    --details: string
    --grpcenable
    --poolcoindenom: string
    --index: string
    --b64
    --commission
    --p2pladdr: string
    --node (-n): string
    --listnames (-n)
    --delayed
    --unsafeentropy
    --output: string
    --hex (-x)
    --latestheight
    --upgradeheight: string
    --vestingstarttime: string
    --dryrun
    --wasmsimulation_gas_limit: string
    --rpcpprof_laddr: string
    --minretainblocks: string
    --ip: string
    --multisigthreshold: string
    --genesis_hash: string
    --account: string    
] {
    # mut flags_list = []

    let flags_nu = [$absolutetimeouts, $address, $amino, $ascii, $b64, $commission, $computegpu, $consensuscreate_empty_blocks, $counttotal, $delayed, $device, $dryrun, $fast_sync, $force, $forzeroheight, $generateonly, $grpcenable, $grpconly, $grpcwebenable, $help, $hex, $iavldisablefastnode, $interactive, $interblockcache, $keepaddrbook, $latestheight, $ledger, $listnames, $long, $noadmin, $noautoincrement, $nobackup, $nosort, $offline, $overwrite, $p2ppex, $p2pseed_mode, $p2pupnp, $prove, $pubkey, $recover, $reverse, $rpcunsafe, $searchapi, $signatureonly, $trace, $unarmoredhex, $unsafe, $unsafeentropy, $withtendermint, $xcrisisskipassertinvariants, $yes]

    let flags_cli = ["--absolute-timeouts", "--address", "--amino", "--ascii", "--b64", "--commission", "--compute-gpu", "--consensus.create_empty_blocks", "--count-total", "--delayed", "--device", "--dry-run", "--fast_sync", "--for-zero-height", "--force", "--generate-only", "--grpc-only", "--grpc-web.enable", "--grpc.enable", "--help", "--hex", "--iavl-disable-fastnode", "--inter-block-cache", "--interactive", "--keep-addr-book", "--latest-height", "--ledger", "--list-names", "--long", "--no-admin", "--no-auto-increment", "--no-backup", "--nosort", "--offline", "--overwrite", "--p2p.pex", "--p2p.seed_mode", "--p2p.upnp", "--prove", "--pubkey", "--recover", "--reverse", "--rpc.unsafe", "--search-api", "--signature-only", "--trace", "--unarmored-hex", "--unsafe", "--unsafe-entropy", "--with-tendermint", "--x-crisis-skip-assert-invariants", "--yes"]

    let list_flags_out = (
        $flags_nu 
        | reduce -f [] {
            |i acc n| if $i {
                $acc 
                | append ($flags_cli | get $n) 
            }
        }
    )

    # if $node != null {
    #     $flags_list = $flags_list | append ['--node' $node]
    # }

    let exec = if ($exec == null) {
        $env.cy.exec
    } else {
        $exec
    }

    let cfolder = $"($env.HOME)/cy/cache/cli_out/"
    let command = $"($exec)_($rest | str join '_')"
    let ts1 = (date now | into int)
    let filename = $"($cfolder)($command)-($ts1).json"

    let $cached_files1 = ls $cfolder

    # print "cached_files"

    let cached_file = (
        if $cached_files1 != null {
            # print "$cached_files1 != null"

            $cached_files1
            | where name =~ $"($command)-"
            | sort-by modified --reverse
            | where modified > (date now | into int | $in - $seconds | into datetime)
            | get -i name.0 
        } else {
            # print "null"
            null
        }
    )

    print $cached_file

    # let let_flags_list = $flags_list

    let content = (
        if ($cached_file != null) {
            # print "cached used"
            open $cached_file
        } else  {
            # print $"request command from cli, saving to ($filename)"
            print $"($exec) ($rest) --output json ($list_flags_out)"
            let out1 = do -i {^($exec) $rest --output json $list_flags_out | from json} 
            if $out1 != null {$out1 | save $filename}
            $out1
        } 
    )

    $content
}

export def 'balances' [
    ...name: string@'nu-complete keys values'
] {

    let keys0 = (
        ^($env.cy.exec) keys list --output json 
        | from json 
        | select name address 
    )

    let keys1 = (
        if ($name | is-empty) {
            $keys0
        } else {
            $keys0 | where name in $name
        }
    )

    let balances = (
        $keys1
        | par-each {
            |i| cyber query bank balances $i.address --output json 
            | from json 
            | get balances 
            | upsert amount {
                |b| $b.amount 
                | into int
            } 
            | transpose -i -r 
            | into record
            | merge $i
    } 
)

    let dummy1 = (
        $balances | columns | prepend "name" | uniq 
        | reverse | prepend ["address"] | uniq 
        | reverse | reduce -f {} {|i acc| $acc | merge {$i : 0}})

    let out = ($balances | each {|i| $dummy1 | merge $i} | sort-by name)

    if ($name | is-empty) or (($name | length) > 1) {
        $out 
    } else {
        $out | into record
    }
}

export def 'ipfs bootstrap add congress' [] {
    ipfs bootstrap add '/ip4/135.181.19.86/tcp/4001/p2p/12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY'
}

export def 'ibc denoms' [] {
    let bank_total = (
        cyber query bank total --output json 
        | from json # here we obtain only the first page of report
    )

    let denom_trace1 = (
        $bank_total 
        | get supply 
        | where denom =~ "^ibc" 
        | upsert ibc_hash {|i| $i.denom | str replace "ibc/" ""} 
        | upsert a1 {|i| cyber query ibc-transfer denom-trace $i.ibc_hash --output json 
        | from json 
        | get denom_trace}
    )

    $denom_trace1.a1 | merge $denom_trace1 | reject ibc_hash a1 | sort-by path --natural
}

# An ordered list of cy commands
export def 'help' [
    --to_md (-m) # export table as markdown
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

def 'banner' [] {
    print $"
     ____ _   _    
    / ___\) | | |   
   \( \(___| |_| |   
    \\____)\\__  |   (ansi yellow)cy(ansi reset) nushell module is loaded
         \(____/    have fun"
}

def 'banner2' [] {
    print "(ansi yellow)cy(ansi reset) is loaded"
}


def is-cid [particle: string] {
    ($particle =~ '^Qm\w{44}$') 
}

def is-neuron [particle: string] {
    ($particle =~ '^bostrom1\w{38}') 
}

def is-connected []  {
    (do -i {http get https://duckduckgo.com/} | describe) == 'raw input'
}

def make_default_folders_fn [] {
    mkdir ~/cy/temp/
    mkdir ~/cy/backups/
    mkdir ~/cy/config/
    mkdir ~/cy/cache/
    mkdir ~/cy/cache/search/
    mkdir ~/cy/cache/other/
    mkdir ~/cy/cache/safe/
    mkdir ~/cy/cache/queue/
    mkdir ~/cy/cache/cli_out/
}

# Print string colourfully
def cprint [
    ...args
    --color (-c): string@'nu-complete colors' = 'default'
    --frame (-f): string
    --before (-b): int = 0
    --after (-a): int = 1
] {
    let text = if ($args == []) {
        $in
    } else {
        $args | str join ' '
    }

    let text = (
        if $frame != null {
            let width = (term size | get columns) - 2
            (
                (" " | fill -a r -w $width -c $frame) + "\n" +
                ( $text ) + "\n" +
                (" " | fill -a r -w $width -c $frame)
            )
        } else {
            $text
        }
    )

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

def 'datetime_fn' [
    --pretty (-P)
] {
    if $pretty {
        date now | date format '%Y-%m-%d-%H:%M:%S'
    } else {
        date now | date format '%Y%m%d-%H%M%S'
    }
    
}

def 'nu-complete-config-names' [] {
    ls '~/cy/config/' -s
    | sort-by modified -r 
    | get name 
    | parse '{short}.{ext}'  
    | where ext == "yaml" 
    | get short
    | filter {|x| $x != "default"}
}

export def 'backup_fn' [
    filename
] {
    let basename1 = ($filename | path basename)
    let path2 = $"($env.HOME)/cy/backups/(datetime_fn)($basename1)"

    if (
        $filename
        | path exists 
    ) {
        ^mv $filename $path2
        # print $"Previous version of ($filename) is backed up to ($path2)"
    } else {
        print $"($filename) does not exist"
    }
}

def 'nu-complete-git-branches' [] {
    ['main', 'dev']
}

# cyber keys in a form of table
def "nu-complete keys table" [] {
    cyber keys list --output json | from json | select name address 
}

# Helper function to use addresses for completions in --from parameter
def "nu-complete keys values" [] {
    (nu-complete keys table).name | zip (nu-complete keys table).address | flatten
}