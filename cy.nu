# Cy - the nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy) and go-ipfs (kubo)
# Git: https://github.com/cyber-prophet/cy
#
# Use:
# > overlay use ~/cy/cy.nu -p -r

export def main [] { help }

# Check if all necessary dependencies are installed
export def check-requirements [] {

    let $intermid = {
        |x| if ($x | length | $in == 0) {
            'all needed apps are installed'
        } else {
            $x
        }
    }

    ['ipfs', 'bat', 'curl', 'pueue', 'cyber', 'pussy']
    | par-each {
        |i| if (which ($i) | is-empty) {
            $'($i) is missing'
        }
    }
    | do $intermid $in
}

export-env {
    banner2
    if not ('~/.cy_config.toml' | path exists) {
        {
            'path': '~/cy/'
            'ipfs-files-folder': '~/cy/graph/particles/safe/'
            'ipfs-download-from': 'gateway'
            'ipfs-storage': 'cybernode'
        } |
        save '~/.cy_config.toml'
    }

    let $config = (open '~/.cy_config.toml')

    let-env cy = (
        try {
            $config
            | merge (
                open $'($config.path)/config/($config.config-name).toml'
            )
            | sort
        } catch {
            $'A config file was not found. Run *"cy config-new"*' | cprint
            $config
        }
    )

    make_default_folders_fn
    graph-load-vars
}

# Pin a text particle
#
# > cy pin-text 'cyber'
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
# > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt'
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
# > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt' --dont_follow_path
# QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
# > cy pin-text "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
# > cy pin-text QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV --dont_detect_cid
# QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F
export def 'pin-text' [
    text_param?: string
    --only_hash  # calculate hash only, don't pin anywhere
    --dont_detect_cid  # work with CIDs as regular texts
    --dont_follow_path # treat existing file paths as reuglar texts
] {
    let $text = (
        $in 
        | default $text_param 
        | into string
        | if (not $dont_follow_path) and (try {$in | path exists} catch {false}) {
            open $in
        } else {}
    )

    if (is-cid $text) and (not $dont_detect_cid) {
        return $text
    } 
    
    if $only_hash {
        $text
        | ipfs add -Q --only-hash
        | str replace '\n' ''
        | return $in
    }

    let $cid = (
        if ($env.cy.ipfs-storage == 'kubo') or ($env.cy.ipfs-storage == 'both') {
            $text
            | ipfs add -Q
            | str replace '\n' ''
        }
    )

    if ($env.cy.ipfs-storage == 'cybernode') or ($env.cy.ipfs-storage == 'both') {
        $text
        | curl --silent -X POST -F file=@- 'https://io.cybernode.ai/add'
        | from json
        | get cid
    } else { $cid }
}

# Add a 2-texts cyberlink to the temp table
#
# > cy link-texts 'cyber' 'cyber-prophet' --disable_append | to yaml
# from_text: cyber
# to_text: cyber-prophet
# from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
# to: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
export def 'link-texts' [
    text_from
    text_to
    --disable_append (-D) # Disable adding the cyberlink into the temp table
    --quiet (-q) # Don't output the cyberlink record after executing the command
] {

    let $row = {
        'from_text': $text_from
        'to_text': $text_to
        'from': (pin-text $text_from)
        'to': (pin-text $text_to)
    } 
    
    if not $disable_append {
        $row | tmp-append --quiet
    }

    if not $quiet {$row}
}

# Add a link chain to the temp table
#
# > cy link-chain "a" "b" "c" | to yaml
# - from_text: a
#   to_text: b
#   from: QmfDmsHTywy6L9Ne5RXsj5YumDedfBLMvCvmaxjBoe6w4d
#   to: QmQLd9KEkw5eLKfr9VwfthiWbuqa9LXhRchWqD4kRPPWEf
# - from_text: b
#   to_text: c
#   from: QmQLd9KEkw5eLKfr9VwfthiWbuqa9LXhRchWqD4kRPPWEf
#   to: QmS4ejbuxt7JvN3oYyX85yVfsgRHMPrVzgxukXMvToK5td
export def 'link-chain' [
    ...rest
] {
    let $count = ($rest | length)
    if $count < 2 {
        return $'($count) particles were submitted. We need 2 or more'
    }

    (
        0..($count - 2) # The number of paris of cids to iterate through
        | each {
            |i| link-texts ($rest | get $i) ($rest | get ($i + 1)) 
        }
    )
}

# Pin files from the current folder to the local node and append their cyberlinks to the temp table
#
# > mkdir linkfilestest; cd linkfilestest
# > 'cyber' | save cyber.txt; 'bostrom' | save bostrom.txt
# > cy link-files --link_filenames --yes | to yaml
# - from: QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k
#   to: QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb
# - from: QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
#   to: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
# > cd ..; rm -r linkfilestest
export def 'link-files' [
    ...files: string        # filenames to add into the local ipfs node
    --link_filenames (-n)   # Add filenames as a from link
    --disable_append (-D)   # Don't append links to the tmp table
    --quiet                 # Don't output results page
    --yes (-y)              # Confirm uploading files without request 
] {
    let $files_col = (
        $files 
        | if $in == [] {
            ls 
            | where type == file 
            | get name 
            | where $it not-in ['desktop.ini' '.DS_Store']
        } else { }
        | wrap from_text
    )

    $'Confirm uploading ($files_col | length) files?'
    | if $yes or (agree -n $in) { } else { return }

    let $results = (
        $files_col
        | par-each {|f| $f 
            | upsert to_text $'pinned_file:($f.from_text)'
            | upsert to (ipfs add $f.from_text -Q | str replace '\n' '')
            | if ($link_filenames) {
                upsert from (pin-text $f.from_text --dont_follow_path)
                | move from --before to
            } else { reject from_text }
        }
    )

    if not $disable_append { $results | tmp-append --quiet }
    if not $quiet { $results }
}

# Create a cyberlink with semantic construction to follow a neuron
#
# > cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
# from_text: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
# to_text: bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
# from: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
# to: QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af
export def 'follow' [
    neuron
] {
    if not (is-neuron $neuron) {
        $"*($neuron)* doesn't look like an address" | cprint 
        return
    }

    link-texts 'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx' $neuron
}

# Add a tweet and send it immediately (unless of disable_send flag)
#
# > cy tmp-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
# from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to_text: cyber-prophet is cool
# from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK
export def 'tweet' [
    text_to
    --disable_send (-D)
] {
    # let $cid_from = pin-text 'tweet'
    let $cid_from = 'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx'

    if (not $disable_send) {
        link-texts $cid_from $text_to -D | tmp-send-tx
    } else {
        link-texts $cid_from $text_to
    }
}

# Add a random chuck norris cyberlink to the temp table
def 'link-chuck' [] {
    # let $cid_from = (pin-text 'chuck norris')
    let $cid_from = 'QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1'

    let $quote = (
        '> ' + (http get https://api.chucknorris.io/jokes/random).value +
        "\n\n" + 'via [Chucknorris.io](https://chucknorris.io)'
    )

    $quote | cprint -f '='

    let $cid_to = (pin-text $quote)

    let $_table = (
        [
            [from_text to_text from to];
            ['chuck norris' $quote $cid_from $cid_to]
        ]
    )

    $_table | tmp-append --quiet
}

# Add a random quote cyberlink to the temp table
def 'link-quote' [] {
    let $json = (
        http get -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json
        | str replace '\\\\' ''
        | from json
    )

    let $quoteAuthor = (
        if $json.quoteAuthor == '' {
            ''
        } else {
            "\n\n>> " + $json.quoteAuthor
        }
    )

    let $quote = (
        '> ' + $json.quoteText +
        $quoteAuthor +
        "\n\n" + 'via [forismatic.com](https://forismatic.com)'
    )

    $quote | cprint -f '='

    # link-texts 'quote' $quote
    link-texts 'QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna' $quote
}

# Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)
export def 'link-random' [
    source?: string@'nu-complete-random-sources'
    -n: int = 1 # Number of links to append
] {
    mut $table = $nothing
    for x in 1..$n {
        if $source == 'forismatic.com' {
            $table = (link-quote)
        } else {
            $table = (link-chuck)
        }
    }
    $table 
}


# View the temp cyberlinks table
export def 'tmp-view' [
    --quiet (-q) # Don't print info
] {
    let $tmp_links = (
        try {
            open $'($env.cy.path)/cyberlinks_temp.csv'
        } catch {
            [[from]; [null]] | first 0 
        }
    )

    if (not $quiet) {
        let $links_count = ($tmp_links | length)

        if $links_count == 0 {
            $'The temp cyberlinks table *"($env.cy.path)/cyberlinks_temp.csv"* is empty.
            You can add cyberlinks to it manually or by using commands like *"cy link-texts"*' | cprint
        } else {
            $'There are *($links_count) cyberlinks* in the temp table:' | cprint
        }
    }

    $tmp_links
}

# Append cyberlinks to the temp table
export def 'tmp-append' [
    cyberlinks?             # cyberlinks table
    --quiet (-q)
] {
    $in 
    | default $cyberlinks
    | upsert date_time (now-fn)
    | prepend (tmp-view -q)
    | if $quiet { tmp-replace -q } else { tmp-replace }
}

# Replace cyberlinks in the temp table
export def 'tmp-replace' [
    cyberlinks?             # cyberlinks table
    --quiet (-q)
] {
    $in 
    | default $cyberlinks
    | save $'($env.cy.path)/cyberlinks_temp.csv' --force
    
    if (not $quiet) { tmp-view -q } 
}

# Empty the temp cyberlinks table
export def 'tmp-clear' [] {
    backup-fn $'($env.cy.path)/cyberlinks_temp.csv'

    'from_text,to_text,from,to' | save $'($env.cy.path)/cyberlinks_temp.csv' --force
    # print 'TMP-table is clear now.'
}

# Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table
#
# > [[from_text, to_text]; ['cyber-prophet' null] ['tweet' 'cy is cool!']] 
# | cy tmp-pin-columns | cy tmp-link-all 'master' --column 'to' --non_empty | to yaml
# - from_text: cyber-prophet
#   to_text: master
#   from: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
#   to: QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW
# - from_text: tweet
#   to_text: cy is cool!
#   from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
#   to: QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8
export def 'tmp-link-all' [
    text: string            # a text to upload to ipfs
    --dont_replace (-D)     # don't replace the temp cyberlinks table, just output results
    --column (-c) = 'from'  # a column to use for values ('from' or 'to'). 'from' is default
    --non_empty             # fill non-empty only
] {
    $in
    | default (tmp-view -q)
    | if $non_empty {
        each {|i| 
            $i 
            | if ( $in | get $column -i | is-empty ) {
                upsert $column (pin-text $text)
                | upsert $'($column)_text' $text
            } else { }
        }
    } else {
        upsert $column (pin-text $text)
        | upsert $'($column)_text' $text
    }
    | if $dont_replace {} else { tmp-replace }
}

# Pin values from column 'text_from' and 'text_to' to an IPFS node and fill according columns with their CIDs
#
# > [{from_text: 'cyber' to_text: 'cyber-prophet'} {from_text: 'tweet' to_text: 'cy is cool!'}] 
# | cy tmp-pin-columns | to yaml
# - from_text: cyber
#   to_text: cyber-prophet
#   from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   to: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
# - from_text: tweet
#   to_text: cy is cool!
#   from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
#   to: QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8
export def 'tmp-pin-columns' [
    --dont_replace (-D) # Don't replace the tmp cyberlinks table
] {

    let cyberlinks = (
        $in
        | default ( tmp-view -q )
        | fill non-exist -v null
    )

    let dict = (
        $cyberlinks 
        | reduce -f [] {|it acc| 
            $acc 
            | if $it.from_text? != null { append $it.from_text } else {} 
            | if $it.to_text? != null { append $it.to_text } else {}
        } 
        | if $in == [] {
            'No columns *"from_text"* or *"to_text"* found. Add at least one of them.' | cprint ;
            return
        } else {}
        | uniq 
        | par-each {|i| {$i: (pin-text $i)}} 
        | reduce -f {} {|it acc| 
            $acc 
            | merge $it
        }
    )

    $cyberlinks 
    | each {|i| $i 
        | if $i.from_text? != null {
            upsert from (
                $dict
                | get -i $i.from_text
            )
        } else {} 
        | if $i.to_text? != null {
            upsert to {
                $dict
                | get -i $i.to_text
            }
        } else {}
    } | if $dont_replace {} else { tmp-replace }
}

# Check if any of the links in the tmp table exist
# > let $from = 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufA'
# > let $to = 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufB'
# > let $neuron = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
# > cy link-exist $from $to $neuron
# false
def 'link-exist' [
    from: string
    to: string
    neuron: string
] {
    (
        do -i {
            ^($env.cy.exec) query rank is-exist $from $to $neuron --output json --node $env.cy.rpc-address
        } | complete 
        | if $in.exit_code == 0 {
            get stdout | from json | get 'exist'
        } else {
            false
        }
    )
}

# Remove existing cyberlinks from the temp cyberlinks table
export def 'tmp-remove-existed' [] {
    let $links_with_status = (
        tmp-view -q
        | upsert link_exist {
            |row| (link-exist  $row.from $row.to $env.cy.address)
        }
    )

    let $existed_links = (
        $links_with_status
        | filter {|x| $x.link_exist}
    )

    let $existed_links_count = ($existed_links | length)

    if $existed_links_count > 0 {

        $'*($existed_links_count) cyberlink\(s\)* was/were already created by *($env.cy.address)*' | cprint
        ($existed_links | select from_text from to_text to | each {|i| print $i})
        'So they were removed from the temp table!' | cprint -c red -a 2

        $links_with_status | filter {|x| not $x.link_exist} | tmp-replace
    } else {
        'There are no cyberlinks from the tmp table for the current address that exist in the blockchain' | cprint
    }
}

# Create a custom unsigned cyberlinks transaction
def 'tx-json-create-from-cybelinks' [] {
    let $cyberlinks = (
        $in
        | select from to
        | uniq
    )

    let $trans = (
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
    | save $'($env.cy.path)/temp/tx-unsigned.json' --force
}

def 'tx-sign-and-broadcast' [] {
    (
        ^($env.cy.exec) tx sign $'($env.cy.path)/temp/tx-unsigned.json' --from $env.cy.address
        --chain-id $env.cy.chain-id
        --node $env.cy.rpc-address
        --output-document $'($env.cy.path)/temp/tx-signed.json'

        | complete
        | if ($in.exit_code != 0) {
            error make {msg: 'Error signing the transaction!'}
        }
    )

    (
        ^($env.cy.exec) tx broadcast $'($env.cy.path)/temp/tx-signed.json'
        --broadcast-mode block
        --output json
        --node $env.cy.rpc-address
        | complete
        | if ($in.exit_code != 0 ) {
            error make { msg: 'exit code is not 0' }
        } else {
            get stdout
        }
    )
}

# Create a tx from the temp cyberlinks table, sign and broadcast it
export def 'tmp-send-tx' [] {
    let $in_cyberlinks = $in

    if not (is-connected) {
        error make {msg: 'there is no internet!'}
    }

    let $cyberlinks = ($in_cyberlinks | default (tmp-view -q))

    let $cyberlinks_count = ($cyberlinks | length)

    $cyberlinks | tx-json-create-from-cybelinks

    let $_var = (
        tx-sign-and-broadcast
        | from json
        | select raw_log code txhash
    )

    if $_var.code == 0 {
        open $'($env.cy.path)/cyberlinks_archive.csv'
        | append (
            $cyberlinks
            | upsert neuron $env.cy.address
        )
        | save $'($env.cy.path)/cyberlinks_archive.csv' --force

        if ($in_cyberlinks == null) {
            tmp-clear
        }

        {'cy': $'($cyberlinks_count) cyberlinks should be successfully sent'}
        | merge $_var
        | select cy code txhash

    } else if $_var.code == 2 {
        {'cy': ('Use *"cy tmp-remove-existed"*' | cprint --echo) }
        | merge $_var
    } else {
        $_var
    }
}

# Copy a table from the pipe into the clipboard (in tsv format)
export def 'tsv-copy' [] {
    let $_table = $in
    $_table | to tsv | clip --no-notify --silent
}

# Paste a table from the clipboard to stdin (so it can be piped further)
export def 'tsv-paste' [] {
    pbpaste | from tsv
}

# Update-cy to the latest version
export def 'update-cy' [
    --branch: string@'nu-complete-git-branches' = 'main'
] {

    let $url = $'https://raw.githubusercontent.com/cyber-prophet/($branch)/dev/cy.nu'

    mkdir $env.cy.path
    | http get $url
    | save $'($env.cy.path)/cy.nu -f'

}

# Get a passport by providing a neuron's address or nick
export def 'passport-get' [
    address_or_nick: string # Name of passport or neuron's address
] {
    let $json = (
        if (is-neuron $address_or_nick) {
            $'{"active_passport": {"address": "($address_or_nick)"}}'
        } else {
            $'{"passport_by_nickname": {"nickname": "($address_or_nick)"}}'
        }
    )

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    let $params = ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']
    let $out = (
        do -i {
            ^cyber query wasm contract-state smart $pcontract $json $params
        } | complete
    )

    if $out.exit_code == 0 {
        $out.stdout  | from json | get data
    } else {
        $'No passport for *($address_or_nick)* is found' | cprint --before 1
        {}
    }
}


# Set a passport's particle, data or avatar field for a given nickname
export def 'passport-set' [
    particle: string
    nickname?
    --data
    --avatar
] {
    let $nickname = (
        if ($nickname | is-empty) {
            if ($env.cy.passport-nick | is-empty) {
                print 'there is no nickname for passport set. To update the fields we need one.'
                return
            } else {
                $env.cy.passport-nick
            }
        } else {
            $nickname
        }
    )

    let $particle = (
        if (is-cid $particle) {
            $particle
        } else {
            print $"($particle) doesn't look like a cid"
            return
        }
    )

    let $json = (
        if $data {
            $'{"update_data":{"nickname":"($nickname)","data":"($particle)"}}'
        } else if $avatar {
            $'{"update_avatar":{"nickname":"($nickname)","new_avatar":"($particle)"}}'
        } else {
            $'{"update_particle":{"nickname":"($nickname)","particle":"($particle)"}}'
        }
    )

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'

    let $params = [
        '--from' $env.cy.address
        '--node' 'https://rpc.bostrom.cybernode.ai:443'
        '--output' 'json'
        '--yes'
        '--broadcast-mode' 'block'
        '--gas' '23456789'
    ]

    let $out = (
        do -i {
            ^cyber tx wasm execute $pcontract $json $params
        } | complete
    )

    let $results = if $out.exit_code == 0 {
        $out.stdout | from json | select raw_log code txhash
    } else {
        $'The particle might not be set. Check with *"cy passport-get ($nickname)"*' | cprint
    }

    $results
}

# Download graph dataframes into the environment
export def-env 'graph-load-vars' [] {
    if not ($'($env.cy.path)/graph/cyberlinks.csv' | path exists) {
        'There is no cyberlinks.csv. Download it using *"cy graph-download-snapshoot"*' | cprint
        return
    }
    let $neurons = (
        open $'($env.cy.path)/graph/neurons_dict.yaml' 
        | fill non-exist
        | dfr into-df
    )
    let $cyberlinks = (
        dfr open $'($env.cy.path)/graph/cyberlinks.csv' 
        | dfr join --left (
            $neurons 
            | dfr select neuron nick
        ) neuron neuron
    )
    let $particles = (if (not ($'($env.cy.path)/particles.parquet' | path exists)) {
        dfr open $'($env.cy.path)/graph/particles.parquet'
    } else {
        'there is no "particles.parquet" file. 
        Create one using the command *"cy graph-update-particles-parquet"*' | cprint
        null
    })
    let-env cy = (
        $env.cy
        | merge {'cyberlinks': $cyberlinks}
        | merge {'particles': $particles}
        | merge {'neurons': $neurons}
    )
}

# Download a snapshot of cybergraph by graphkeeper
export def-env 'graph-download-snapshoot' [
    --disable_update_parquet (-d)
] {
    make_default_folders_fn
    
    let $path = $'($env.cy.path)/graph'
    let $cur_data_cid = (passport-get graphkeeper | get extension.data -i)
    let $update_info = (try {open $'($path)/update.toml'} catch {{}})
    let $last_data_cid = ($update_info | get -i last_cid)

    if ($last_data_cid == $cur_data_cid) {
        print 'no updates found'
        return
    }

    print 'Downloading cyberlinks.csv'
    ipfs get $'($cur_data_cid)/graph/cyberlinks.csv' -o $path
    print 'Downloading neurons.json'
    ipfs get $'($cur_data_cid)/graph/neurons_dict.json' -o $path
    print 'Downloading particles zips'
    ipfs get $'($cur_data_cid)/graph/particles/' -o $'($path)/particles_arch/'

    let $archives = (ls $'($path)/particles_arch/*.zip' | get name)
    let $last_archive = (
        $update_info
        | get -i last_archive
        | default ($archives | first)
    )

    (
        $archives
        | skip until {|x| $x == $last_archive}
        | each {
            |i| unzip -ojq $i -d $'($path)/particles/safe/'; 
            cprint $'*($i)* is unzipped'
        }
    )

    (
        try {open $'($path)/update.toml'} catch {{}}
        | upsert 'last_cid' $cur_data_cid
        | upsert 'last_archive' ($archives | last)
        | save $'($path)/update.toml' -f
    )

    $'The graph data has been downloaded to the *"($path)"* directory' | cprint

    if (not $disable_update_parquet) {
        print 'Updating particles parquet'
        graph-update-particles-parquet
    }
}

# Output unique list of particles from piped in cyberlinks table
export def 'graph-to-particles' [
    cyberlinks?
    --from
    --to
    --include_system (-s)
    --include_content
    --cids_only (-c)
] {
    let $c = (
        $in 
        | default $cyberlinks
        | default ($env | get cy.cyberlinks -i)
        | default (
            dfr open $'($env.cy.path)/graph/cyberlinks.csv'
        ) | dfr into-lazy
    )

    (
        $c 
        | dfr rename particle_from particle 
        | dfr drop particle_to
        | dfr first 0  # Create dummy dfr to have something to appended to
        | if not $to { dfr into-lazy
            | dfr append --col (
                | $c 
                | dfr rename particle_from particle 
                | dfr drop particle_to
            )
        } else {}
        | if not $from { dfr into-lazy
            | dfr append --col (
                $c 
                | dfr rename particle_to particle 
                | dfr drop particle_from
            )
        } else {} | dfr into-lazy 
        | dfr sort-by height 
        | dfr unique --subset [particle]
        | if $cids_only { dfr into-lazy
            | dfr select particle
        } else { dfr into-lazy
            | dfr with-column (
                dfr arg-where ((dfr col height) != 0) | dfr as particle_index
            )
        } 
        | if $include_content { dfr into-lazy # not elegant solution to keep columns from particles and to have particle_index in this function
            | dfr select particle
            | dfr join $env.cy.particles particle particle
        } else {}
        | if not $include_system { dfr into-lazy
            | dfr filter-with (
                (dfr col particle) 
                | dfr is-in  [
                    'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx', 
                    'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx', 
                    'Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs' 
                ] | dfr expr-not
            ) 
        } else {} | dfr into-lazy
        | dfr collect
    )
}

export def-env 'graph-update-particles-parquet' [
    --full_content
] {

    let $ls_files = (ls $'($env.cy.path)/graph/particles/safe');

    let $ls_content_nu = (
        $ls_files
        | get name
        | each {
            |i| open $i
        }
    )

    let $downloaded_cids = (
        $ls_files
        | get name
        | each {
            |i| $i
            | path basename
            | str substring 0..46
            | into string
        } | dfr into-df
        | dfr rename '0' cid
    )

    let $content_df1 = (
        $ls_files | dfr into-df
        | dfr with-column (
            $ls_content_nu
            | each {
                |i| $i
                | str substring 0..150 -g
                | str trim
                | lines
                | get -i 0
                | default $'!!malformed ($i)'
            } | dfr into-df
            | dfr rename '0' content_s
        )
        | dfr with-column $downloaded_cids
        | if $full_content { dfr into-df
            | dfr with-column (
                $ls_content_nu
                | dfr into-df
                | dfr rename '0' content
            )
        } else {} | dfr into-df
        | dfr drop name modified type
    )

    let $content_df2 = (
        graph-to-particles --include_system | dfr into-df
        | dfr join $content_df1 particle cid --left
    )

    let $m2_mask_null = (
        $content_df2
        | dfr get content_s
        | dfr is-null
    )

    let $final_df = (
        $content_df2
        | dfr with-column (
            $content_df2
            | dfr get content_s
            | dfr set 'timeout' --mask ($m2_mask_null | dfr into-df)
            | dfr rename string content_s
        )
    )

    backup-fn $'($env.cy.path)/graph/particles.parquet'
    $final_df | dfr to-parquet $'($env.cy.path)/graph/particles.parquet' | print $in
    graph-load-vars
}


export def 'graph-filter-neurons' [
    ...neurons_nicks: string@'nu-complete-neurons-nicks'
    --cyberlinks: any
] {
    let $cyberlinks = (
        $in 
        | default $cyberlinks 
        | default ($env | get cy.cyberlinks -i)
    )
    
    let $filtered_links = (
        $neurons_nicks | dfr into-df
        | dfr join $env.cy.neurons '0' nick
        | dfr select neuron
        | dfr join $cyberlinks neuron neuron
    )

    $filtered_links
}

export def 'graph-append-related' [] {
    let $c = ($in | dfr into-lazy | dfr with-column (dfr lit '1' | dfr as 'step'))

    let $to_2 = (
        $c 
        | graph-to-particles --cids_only  | dfr into-lazy 
        | dfr rename particle particle_to 
        | dfr join $env.cy.cyberlinks particle_to particle_to 
        | dfr with-column (dfr lit '2to' | dfr as 'step') 
    )

    let $from_2 = (
        $c 
        | graph-to-particles --cids_only  | dfr into-lazy 
        | dfr rename particle particle_from 
        | dfr join $env.cy.cyberlinks particle_from particle_from 
        | dfr with-column (dfr lit '2from' | dfr as 'step') 
    )

    $c 
    | dfr append -c $to_2 
    | dfr append -c $from_2  | dfr into-lazy 
    | dfr sort-by height 
    | dfr unique --subset [neuron particle_from particle_to] 
    | dfr collect

}

export def 'graph-update-neurons' [
    --passport
    --balance
    --karma
    --all (-a)
    --threads (-t) = 30
    --dont_save
    --verbose (-v)
] {
    $in 
    | default $env.cy.cyberlinks 
    | dfr into-df 
    | dfr select neuron 
    | dfr unique 
    | dfr join $env.cy.neurons neuron neuron --left 
    | dfr into-nu 
    | if $passport or $all {
        par-each -t $threads {|i| 
            $i | merge (passport-get $i.neuron | get -i extension | default {})
        }
    } else {}
    | if $balance or $all {
        par-each -t $threads {|i| 
            $i | merge (balance-get $i.neuron)
        }
    } else {}
    | if $karma or $all {
        par-each -t $threads {|i| 
            $i | merge (
                ^($env.cy.exec) query rank karma $i.neuron -o json 
                | from json 
                | upsert karma {|i| $i.karma | into int}
            )
        }
    } else {}
    | if $dont_save {} else {
        save -f $'($env.cy.path)/graph/neurons_dict.yaml'
    }
}

export def 'graph-neurons-stats' [] {
#neuron-stats-works
    let c = ($env.cy.cyberlinks | dfr into-df)
    let p = ($env.cy.particles | dfr into-df )

    let follows = ($p 
        | dfr filter ((dfr col content_s) == follow) 
        | dfr select particle 
        | dfr join --left $c particle particle_from 
        | dfr group-by neuron 
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'follows')
        ] 
        | dfr sort-by follows --reverse [true]
    )

    let $tweets = ($p 
        | dfr filter ((dfr col content_s) == tweet) 
        | dfr select particle 
        | dfr join --left $c particle particle_from 
        | dfr group-by neuron 
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'tweets')
        ] 
        | dfr sort-by tweets --reverse [true]
    )


    let $followers = (
        $p 
        | dfr filter ((dfr col content_s) == follow) 
        | dfr select particle 
        | dfr join --left $c particle particle_from 
        | dfr join $p particle_to particle 
        | dfr group-by content_s 
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'followers')
        ] 
        | dfr sort-by followers --reverse [true]
    ) 

    (
        $c 
        | dfr group-by neuron 
        | dfr agg [
            (dfr col timestamp | dfr min | dfr as 'ts_min')
            (dfr col timestamp | dfr max | dfr as 'ts_max')
            (dfr col timestamp | dfr count | dfr as 'links_count')
        ] 
        | dfr sort-by links_count --reverse [true]  # cygraph neurons activity
        | dfr join $followers neuron content_s --left
        | dfr join $follows neuron neuron --left 
        | dfr join $tweets neuron neuron --left 
        | dfr join (
            $env.cy.neurons | dfr into-df 
        ) neuron neuron --left
    ) 
}

# Export the entire graph into CSV file for import to Gephi
export def 'graph-to-gephi' [
    cyberlinks?
] {
    let $cyberlinks = ($in | default $cyberlinks | default ($env | get cy.cyberlinks -i) | dfr into-df)
    let $particles = (graph-to-particles $cyberlinks --include_system --include_content)

    let $t1_height_index = (
        $cyberlinks.height  | dfr into-df 
        | dfr append -c $particles.height # Particles might be created before they appear in the filtered graph
        | dfr unique 
        | dfr with-column (
            dfr arg-where ((dfr col height) != 0) | dfr as height_index
        )
    )

    let $height_index_max = (
        $t1_height_index | dfr shape | dfr into-nu | get rows.0
    )

    (
        $cyberlinks | dfr into-df
        | dfr join --left $t1_height_index height height 
        | dfr with-column (
            dfr concat-str '' [
                (dfr lit '<[') 
                (dfr col height_index) 
                (dfr lit ($',($height_index_max)]>'))
            ] 
            | dfr as Timeset
        ) 
        # | dfr with-column (
        #     dfr concat-str '' [
        #         (dfr lit "<[") 
        #         (dfr col timestamp) 
        #         (dfr lit ($',(date now | date format "%Y-%m-%d")]>'))
        #     ] 
        #     | dfr as timestamp_interval
        # ) 
        | dfr rename [particle_from particle_to] [source target]
        | dfr to-csv $'($env.cy.path)/gephi/!cyberlinks.csv'
    )

    (
        $particles | dfr into-lazy
        | dfr join --left $t1_height_index height height 
        | dfr with-column (
            (dfr col particle) | dfr as cid
        ) | dfr rename [particle content_s] [id label]
        | dfr collect
        | dfr with-column (
            dfr concat-str '' [
                (dfr lit '<[') 
                (dfr col height_index) 
                (dfr lit ($',($height_index_max)]>'))
            ] 
            | dfr as Timeset
        ) 
        # | dfr with-column (
        #     dfr concat-str "" [
        #         (dfr lit "<[") 
        #         (dfr col timestamp) 
        #         (dfr lit ($',(date now | date format "%Y-%m-%d")]>'))
        #     ] 
        #     | dfr as timestamp_interval
        # ) 
        | dfr into-nu
        | reject index
        | move id label cid --before height
        | save $'($env.cy.path)/gephi/!particles.csv' -f
    )
}

export def 'graph-to-logseq' [
    cyberlinks?
    # --path: string
] {
    let $cyberlinks = ($in | default $cyberlinks | default ($env | get cy.cyberlinks -i | inspect2))
    let $particles = (graph-to-particles $cyberlinks --include_system --include_content | inspect2)

    let $path = $'($env.cy.path)/logseq/(date now | date format "%Y-%m-%d_%H-%M-%S")/'
    mkdir $'($path)/pages'
    mkdir $'($path)/journals'

    $particles | dfr into-df 
    | dfr into-nu 
    | par-each {|p|
        # print $p.particle
        $"author:: [[($p.nick)]]\n\n- (
            do -i {open $'($env.cy.ipfs-files-folder)/($p.particle).md' 
            | default "timeout"
        } )\n- --- \n- ## cyberlinks from \n" |
        save $'($path)/pages/($p.particle).md'
    }

    $cyberlinks | dfr into-df
    | dfr into-nu
    | each {|c| 
        $"\t- [[($c.particle_to)]] ($c.height) [[($c.nick?)]]\n" |
        save $'($path)/pages/($c.particle_from).md' -a
    }
}

# Create a config JSON to set env variables, to use them as parameters in cyber cli
export def-env 'config-new' [
    # config_name?: string@'nu-complete-config-names'
] {
    'Choose the name of executable:' | cprint -c green
    let $exec = (nu-complete-executables | input list -f | inspect2)

    let $addr_table = (
        ^($exec) keys list --output json
        | from json
        | flatten
        | select name address
    )

    if ($addr_table | length) == 0 {
        let $error_text = (
            $'There are no addresses in ($exec). To use CY you need to add one. ' +
            $'You can find out how to add one by running the command "($exec) keys add -h". ' +
            $'After adding a key - come back and launch this wizzard again'
        )

        error make -u {msg: $error_text}
    help: $'try "($exec) keys add -h"'
    }

    'Select the address to send transactions from:' | cprint -c green --before 1
    let $address = (
        $addr_table 
        | input list -f
        | get address
        | inspect2
    )

    let $config_name = (
        $addr_table
        | select address name
        | transpose -r -d
        | get $address
        | $'($in)+($exec)'
    )

    let $passport_nick = (
        passport-get $address
        | get extension.nickname -i
    )

    if (not ($passport_nick | is-empty)) {
        $'Passport nick *($passport_nick)* will be used' | cprint -c default_italic --before 1
    }

    let $chain_id_def = (if ($exec == 'cyber') {
            'bostrom'
        } else {
            'space-pussy'
        }
    )

    # 'Enter the chain-id for interacting with the blockchain. ' | cprint -c green --before 1 --after 0
    # $'Default: ($chain_id_def)' | cprint -c green -c yellow_italic
    let $chain_id = ($chain_id_def)


    let $rpc_def = if ($exec == 'cyber') {
        'https://rpc.bostrom.cybernode.ai:443'
    } else {
        'https://rpc.space-pussy.cybernode.ai:443'
    }

    'Select the address of RPC api for interacting with the blockchain:' | cprint -c green --before 1
    let $rpc_address = (
        [$rpc_def 'other'] 
        | input list -f
        | do {
            |x| if $x == 'other' {
                input 'enter the RPC address:'
            } else {$x}
        } $in
        | inspect2
    )

    'Select the ipfs service to store particles:' | cprint -c green --before 1
    let $ipfs_storage = (
        [cybernode, kubo, both] 
        | input list -f 
        | inspect2
    )


    let $temp_env = {
        'config-name': $config_name
        'exec': $exec
        'address': $address
        'passport-nick': $passport_nick
        'chain-id': $chain_id
        'ipfs-storage': $ipfs_storage
        'rpc-address': $rpc_address
    }


    make_default_folders_fn

    $temp_env | config-save $config_name

    if (
        not ($'($env.cy.path)/cyberlinks_temp.csv' | path exists)
    ) {
        'from,to' | save $'($env.cy.path)/cyberlinks_temp.csv'
    }

    if (
        not ($'($env.cy.path)/cyberlinks_archive.csv' | path exists)
    ) {
        'from,to,address,timestamp,txhash' | save $'($env.cy.path)/cyberlinks_archive.csv'
    }
}

# View a saved JSON config file
export def 'config-view' [
    config_name?: string@'nu-complete-config-names'
    # --quiet (-q)
] {
    if $config_name == null {
        $env.cy 
    } else {
        let $filename = $'($env.cy.path)/config/($config_name).toml'
        open $filename 
    } 
    # | if $quiet {} else {inspect2}
}

# Save the piped-in JSON into config file
export def-env 'config-save' [
    config_name: string@'nu-complete-config-names'
    --inactive # Don't activate current config
] {
    let $in_config = ($in | upsert config-name $config_name)
    let $file_name = $'($env.cy.path)/config/($config_name).toml'

    let $file_name2 = (
        if not ($file_name | path exists) {
            $file_name
        } else {
            $'($file_name) exists. Do you want to overwrite it?' | cprint -c green --before 1

            ['yes' 'no'] | input list
            | if $in == 'yes' {
                backup-fn $file_name;
                $file_name
            } else {
                $'($env.cy.path)/config/(now-fn).toml'
            }
        }
    )

    $in_config | save $file_name2 -f
    print $'($file_name2) is saved'

    if (not $inactive) {
        $in_config | config-activate
    }
}

# Activate the config JSON
export def-env 'config-activate' [
    config_name?: string@'nu-complete-config-names'
] {
    let $config = ($in | default (config-view $config_name))
    let $config_toml = (
        open '~/.cy_config.toml'
        | merge $config 
    )

    let-env cy = $config_toml

    'Config is loaded' | cprint -c green_underline -b 1
    # $config_toml | save $'($env.cy.path)/config/default.toml' -f
    (
        open '~/.cy_config.toml'
        | upsert 'config-name' ($config_toml | get 'config-name')
        | save '~/.cy_config.toml' -f
    )

    $config_toml
}

def 'search-sync' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let $cid = if (is-cid $query) {
        $query
    } else {
        (pin-text $query --only_hash)
    }

    print $'searching ($env.cy.exec) for ($cid)'

    (
        ^($env.cy.exec) query rank search $cid $page 10 
        --output json --node $env.cy.rpc-address
        | from json
        | get result
        | upsert particle {
            |i| let $particle = (
                ipfs cat $i.particle -l 400
            );
            $particle
            | file -
            | if (
                $in | str contains '/dev/stdin: ASCII text'
            ) {
                $"($particle)\n(ansi grey)($i.particle)(ansi reset)"
            } else {
                $"Non-text particle. Is not supported yet.\n(ansi grey)($i.particle)(ansi reset)"
            }
        }
        | select particle rank
    )
}

def 'search-with-backlinks' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let $cid = if (is-cid $query) {
        print $'searching (cid-read-or-download $query)'
        $query
    } else {
        (pin-text $query --only_hash | inspect)
    }

    print $'searching ($env.cy.exec) for ($cid)'

    let $serp = (
        ^($env.cy.exec) query rank search $cid $page $results_per_page 
        --output json --node $env.cy.rpc-address
        | from json
        | get result
        | upsert particle {
            |i| cid-read-or-download $i.particle
        }
        | select particle rank
        | upsert source 'search'
    )

    let $back = (
        ^($env.cy.exec) query rank backlinks $cid $page $results_per_page 
        --output json --node $env.cy.rpc-address
        | from json
        | get result
        | upsert particle {
            |i| cid-read-or-download $i.particle
        }
        | select particle rank
        | upsert source 'backlinks'
    )

    let $result = ($serp | append $back)

    $result
}

def 'search-auto-refresh' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let $cid = (pin-text $query --only_hash)

    print $'searching ($env.cy.exec) for ($cid)'

    let $out = (
        do -i {(
            ^($env.cy.exec) query rank search $cid $page $results_per_page 
            --output json --node $env.cy.rpc-address
        )} | complete
    )

    let $results = if $out.exit_code == 0 {
        $out.stdout | from json
    } else {
        null
    }

    if $results == null {
        print $'there is no search results for ($cid)'
        return
    }

    $results | save $'($env.cy.path)/cache/search/($cid)-(date now|into int).json'

    clear; print $'Searching ($env.cy.exec) for ($cid)';

    serp1 $results

    watch $'($env.cy.path)/cache/queue' {|| clear; print $'Searching ($env.cy.exec) for ($cid)'; serp1 $results}
}

# Use the built-in node search function in cyber or pussy
export def 'search' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
    --search_type: string@'nu-complete-search-functions' = 'search-with-backlinks'
] {
    if $search_type == 'search-with-backlinks' {
        search-with-backlinks $query --page $page --results_per_page $results_per_page
    } else if $search_type == 'search-auto-refresh' {
        search-auto-refresh $query --page $page --results_per_page $results_per_page
    } else if $search_type == 'search-sync' {
        search-sync $query --page $page --results_per_page $results_per_page
    }
}

def serp1 [
    results
    --pretty: bool@'nu-complete-bool' = false
] {

    let $serp = (
        $results
        | get result
        | upsert particle {
            |i| cid-read-or-download $i.particle
        }
        | select particle rank
    )

    $serp
}

# Obtain cid info
export def 'cid-get-type-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --to_csv
] {
    let $headers = (
        curl -s -I -m 120 $'($gate_url)($cid)'
        | lines
        | skip 1
        | append 'dummy: dummy'   # otherwise it returns list in the end
        | parse '{header}: {value}'
        | transpose -d -r -i
    )
    let $type = ($headers | get -i 'Content-Type')
    let $size = ($headers | get -i 'Content-Length')

    if (
        ($type == null) or ($size == null) or 
        (($type == 'text/html') and (($size == '157'))
    )) {
        return null
    }

    log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '3.downloaded headers'

    {type: $type size: $size}
}

export def log_row_csv [
    --cid: string = ''
    --source: string = ''
    --type: string = ''
    --size: string = ''
    --status: string = ''
    --file: string = 
] {
    let $file = ($file | default $'($env.cy.path)/cache/MIME_types.csv')
    $'($cid),($source),"($type)",($size),($status),(history session)\n' | save -a $file
}

# Read a CID from the cache, and if the CID is absent - add it into the queue
export def 'cid-read-or-download' [
    cid: string
    --full  # output full text of a particle 
] {
    do -i {open $'($env.cy.ipfs-files-folder)/($cid).md'}
    | default (
        pu-add $'cy cid-download ($cid)';
        'downloading'
    ) | if $full {} else {
        str substring 0..400
        | str replace "\n" '↩' --all
        | $"($in)\n(ansi grey)($cid)(ansi reset)"
    }
}

# Add a cid into queue to download asynchronously
export def 'cid-download-async' [
    cid: string
    --force (-f)
    --source: string # kubo or gateway
    --info_only # Don't download the file by write a card with filetype and size
    --folder: string
] {
    let $folder = ($folder | default $'($env.cy.ipfs-files-folder)')
    let $content = (do -i {open $'($env.cy.ipfs-files-folder)/($cid).md'})
    let $source = ($source | default $env.cy.ipfs-download-from)

    if ($content == null) or ($content == 'timeout') or $force {
        pu-add $'cy cid-download ($cid) --source ($source) --info_only ($info_only) --folder '($folder)''
        print 'downloading'
    }
}

# Download cid immediately and mark it in the queue
export def 'cid-download' [
    cid: string
    --source: string # kubo or gateway
    --info_only = false # Don't download the file by write a card with filetype and size
    --folder: string
] {
    let $folder = ($folder | default $env.cy.ipfs-files-folder)
    let $source = ($source | default $env.cy.ipfs-download-from)
    let $status = match $source {
        'gateway' => {cid-download-gateway $cid --info_only $info_only --folder $folder}
        'kubo' => {cid-download-kubo $cid --info_only $info_only --folder $folder}
    }

    if ($status) in ['text' 'non_text'] {
        rm --force $'($env.cy.path)/cache/queue/($cid)'
        'downloaded'
    } else if $status == 'not found' {
        cid-queue-add $cid '-'
        'not found'
    } 
}

# Download a cid from kubo (go-ipfs cli) immediately
def 'cid-download-kubo' [
    cid: string
    --timeout = '300s'
    --folder: string
    --info_only = false # Don't download the file by write a card with filetype and size
] {
    print $'cid to download ($cid)'
    let $type = (
        do -i {ipfs cat --timeout $timeout -l 400 $cid} 
        | complete
        | if $in.exit_code == 1 {
            'empty'
        } else {
            get stdout
            | file - -I
            | $in + ''
            | str replace '\n' ''
            | str replace '/dev/stdin: ' ''
        }
    )

    if ($type =~ '^empty') {
        return 'not found'
    } else if (
        ($type =~ '(text/plain)|(ASCII text)|(Unicode text, UTF-8)|(very short file)') and (not $info_only)
     ) {
        try {
            ipfs get --progress=false --timeout $timeout -o $'($folder)/($cid).md' $cid
            return 'text'
        } catch {
            return 'not found'
        }
    } else {
        (
            {'MIME type': ($type | split row ';' | get -i 0)}
            | merge (
                do -i {
                    ipfs dag stat $cid --enc json --timeout $timeout | from json
                }
                | default {'Size': null}
            )
            | sort -r
            | to toml
            | save -f $'($folder)/($cid).md'
        )
        return 'non_text'
    }
}

# Download a cid from gateway immediately
export def 'cid-download-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --folder: string
    --info_only: bool = false # Don't download the file by write a card with filetype and size
] {
    let $folder = ($folder | default $'($env.cy.ipfs-files-folder)')
    let $meta = (cid-get-type-gateway $cid)
    let $type = ($meta | get -i type)
    let $size = ($meta | get -i size)

    if (
        (($type | default '') == 'text/plain; charset=utf-8') and (not $info_only)
    ) {
        http get $'($gate_url)($cid)' -m 120 | save -f $'($folder)/($cid).md'
        return 'text'
        # log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '4.downloaded file'
    } else if ($type != null) {
        {'MIME type': $type, 'Size': $size} | sort -r | to toml | save -f $'($folder)/($cid).md'
        return 'non_text'
        # log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '4.downloaded info'
    } else {
        return 'not found'
    }
}

export def 'cid-queue-add' [
    cid: string
    symbol: string = '+'
] {
    $symbol | save -a $'($env.cy.path)/cache/queue/($cid)'
}

# Watch the queue folder, and if there are updates, request files to download
export def 'watch-search-folder' [] {
    watch $'($env.cy.path)/cache/search' {|| queue-check }
}

# Check the queue for the new CIDs, and if there are any, safely download the text ones
export def 'queue-check' [
    attempts = 0
    --info
    --quiet
] {
    let $files = (ls -s $'($env.cy.path)/cache/queue/')

    if (do -i {pueue status} | complete | $in.exit_code != 0) {
        return 'Tasks queue manager is turned off. Launch it with "brew services start pueue" or "pueued -d" command'
    }

    if ( ($files | length) == 0 ) {
        return 'there are no files in queue'
    }

    $'Overall count of files in queue is *($files | length)*' | cprint

    print $'For download will be used ($env.cy.ipfs-download-from)'

    let $filtered_files = (
        $files
        | where size <= (1 + $attempts | into filesize)
        | sort-by size
    )

    if ($filtered_files == []) {
        return $'There are no files, that was attempted to download for less than ($attempts) times.'
    } else {
        print $'There are ($filtered_files | length) files that was attempted to be downloaded ($attempts) times already.'
        print $'The latest file was added into the queue ($filtered_files | sort-by modified -r | sort-by size | get modified.0 -i)'    
    }


    if not $info {
        $filtered_files
        | get name -i
        | each {
            |i| pu-add $'cy cid-download ($i)'
        } 
    }
}

# Clear the cache folder
export def 'cache-clear' [] {
    backup-fn $'($env.cy.path)/cache'
    make_default_folders_fn
}

# Get a current height for a network choosen in config
export def 'query-current-height' [
    exec?: string@'nu-complete-executables'
] {
    let $exec = ($exec | default $env.cy.exec)
    # print $'current height for ($exec)'
    ^($exec) query block | from json | get block.header | select height time chain_id
}

# Get a balance for a given account
export def 'balance-get' [
    address: string
] {
    if not (is-neuron $address) {
        $"*($address)* doesn't look like an address" 
        | cprint 
        return null
    }

    # let exec = match ($address | str substring 0..4) {
    #     'pussy' => { 'pussy' },
    #     'bostr' => { 'cyber' }
    # }

    (
        ^($env.cy.exec) query bank balances $address 
        --output json --node $env.cy.rpc-address
        | from json
        | get balances
        | upsert amount {
            |b| $b.amount
            | into int
        }
        | transpose -i -r
        | into record
    )
}

# Check balances for the keys added to the active CLI
export def 'balances' [
    ...name: string@'nu-complete keys values'
] {

    let $keys0 = (
        ^($env.cy.exec) keys list --output json
        | from json
        | select name address
    )

    let $keys1 = (
        if ($name | is-empty) {
            $keys0
        } else {
            $keys0 | where name in $name
        }
    )

    let $balances = (
        $keys1
        | par-each {
            |i| balance-get $i.address
            | merge $i
        }
    )

    let $dummy1 = (
        $balances | columns | prepend 'name' | uniq
        | reverse | prepend ['address'] | uniq
        | reverse | reduce -f {} {|i acc| $acc | merge {$i : 0}}
    )

    let $out = ($balances | each {|i| $dummy1 | merge $i} | sort-by name)

    if ($name | is-empty) or (($name | length) > 1) {
        $out
    } else {
        $out | into record
    }
}

# Add the cybercongress node to bootstrap nodes
export def 'ipfs-bootstrap-add-congress' [] {
    ipfs bootstrap add '/ip4/135.181.19.86/tcp/4001/p2p/12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY'
    print 'check if bootstrap node works by executing commands:'

    print 'ipfs routing findpeer 12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY'
    ipfs routing findpeer 12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY

    print 'ipfs routing findpeer QmUgmRxoLtGERot7Y6G7UyF6fwvnusQZfGR15PuE6pY3aB'
    ipfs routing findpeer QmUgmRxoLtGERot7Y6G7UyF6fwvnusQZfGR15PuE6pY3aB
}

# Check IBC denoms
export def 'ibc-denoms' [] {
    let $bank_total = (
        cyber query bank total --output json
        | from json # here we obtain only the first page of report
    )

    let $denom_trace1 = (
        $bank_total
        | get supply
        | where denom =~ '^ibc'
        | upsert ibc_hash {|i| $i.denom | str replace 'ibc/' ''}
        | upsert temp_out {
            |i| cyber query ibc-transfer denom-trace $i.ibc_hash --output json
            | from json
            | get denom_trace
        }
    )

    $denom_trace1.temp_out | merge $denom_trace1 | reject ibc_hash temp_out | sort-by path --natural
}

# Dump the peers connected to the given node to the comma-separated 'persistent_peers' list
export def 'validator-generate-persistent-peers-string' [
    node_address: string
] {
    let $node_address = ($node_address | default $'($env.cy.rpc-address)')
    if $node_address == $env.cy.rpc-address {
        print $"Nodes list for ($env.cy.rpc-address)\n"
    }

    let $peers = (http get $'($node_address)/net_info' | get result.peers)

    print $'($peers | length) peers found\n'

    $peers
    | each {|i| $i 
    | get node_info.id remote_ip node_info.listen_addr} 
    | each {
        |i| $'($i.0)@($i.1):($i.2 | split row ":" | last)'
    } 
    | str join ',' 
    | $'persistent_peers = "($in)"'
}

# An ordered list of cy commands
export def 'help' [
    --to_md (-m) # export table as markdown
] {
    let $text = (
        open $'($env.cy.path)/cy.nu' --raw
        | parse -r "(\n(# )(?<desc>.*?)(?:\n#[^\n]*)*\nexport (def|def.env) '(?<command>.*)')"
        | select command desc
        | upsert command {|row index| ('cy ' + $row.command)}
    )

    if $to_md {
        $text | to md
    } else {
        $text
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
    print $'(ansi yellow)cy(ansi reset) is loaded'
}


def is-cid [particle: string] {
    ($particle =~ '^Qm\w{44}$')
}

def is-neuron [particle: string] {
    (
        ($particle =~ '^bostrom\w{39}$') 
        or ($particle =~ '^bostrom\w{59}$') 
        or ($particle =~ '^pussy\w{39}$') 
        or ($particle =~ '^pussy\w{59}$')
    )
}

def is-connected []  {
    (do -i {http get https://duckduckgo.com/} | describe) == 'raw input'
}

def make_default_folders_fn [] {
    mkdir $'($env.cy.path)/temp/'
    mkdir $'($env.cy.path)/backups/'
    mkdir $'($env.cy.path)/config/'
    mkdir $'($env.cy.path)/graph/particles/safe/'
    mkdir $'($env.cy.path)/gephi/'
    mkdir $'($env.cy.path)/cache/search/'
    mkdir $'($env.cy.path)/cache/queue/'
    mkdir $'($env.cy.path)/cache/cli_out/'

    touch $'($env.cy.path)/graph/update.toml'
}

# Print string colourfully
export def 'cprint' [
    ...args
    --color (-c): any = 'default'
    --highlight_color (-h): any = 'green_bold'
    --frame_color (-r): any = 'dark_gray'
    --frame (-f): string        # A symbol (or a string) to frame text
    --before (-b): int = 0      # A number of new lines before text
    --after (-a): int = 1       # A number of new lines after text
    --echo (-e)                 # Echo text string instead of printing
] {
    let $in_text = ($in | default ($args | str join ' '))

    def compactit [] {
        $in 
        | str replace -a '\n[\t ]+' ' ' 
        | str replace -a '[\t ]+' ' ' 
        | str replace -a '(?m)^[\t ]+' ' '
    }

    def colorit [] {
        let text = ($in | split chars)
        mut agg = []
        mut open_tag = true

        for i in $text {
            if $i == '*' {
                if $open_tag {
                    $open_tag = false 
                    $agg = ($agg | append $'(ansi reset)(ansi $highlight_color)')
                } else {
                    $open_tag = true
                    $agg = ($agg | append $'(ansi reset)(ansi $color)')
                }
            } else {
                $agg = ($agg | append $i)
            }
        }

        $agg
        | str join ''
        | $'(ansi $color)($in)(ansi reset)'
    }

    def frameit [] {
        let $text = $in
        let $width = (
            term size 
            | get columns 
            | ($in / ($frame | str length) | math round) 
            | $in - 1
            | [$in 1]
            | math max  # term size gives 0 in tests
        )
        let $line = (' ' | fill -a r -w $width -c $frame | $'(ansi $frame_color)($in)(ansi reset)')

        (
            $line + "\n" + $text + "\n" + $line
        )
    }

    def newlineit [] {
        let $text = $in

        print ("\n" * $before) -n
        print $text -n
        print ("\n" * $after) -n
    }

    (
        $in_text
        | compactit
        | colorit
        | if $frame != null {
            frameit
        } else {}
        | if $echo { } else { newlineit }
    )
}

def 'if-empty' [
    alternative: any
] {
    let value = $in
     (
         if ($value | is-empty) {
             $alternative
         } else {
             $value
         }
     )
 }

def 'now-fn' [
    --pretty (-P)
] {
    if $pretty {
        date now | date format '%Y-%m-%d-%H:%M:%S'
    } else {
        date now | date format '%Y%m%d-%H%M%S'
    }
}

def 'backup-fn' [
    filename
] {
    let $basename1 = ($filename | path basename)
    let $path2 = $'($env.cy.path)/backups/(now-fn)($basename1)'

    if (
        $filename
        | path exists
    ) {
        ^mv $filename $path2
        # print $'Previous version of ($filename) is backed up to ($path2)'
    } else {
        $'*($filename)* does not exist' | cprint
    }
}

export def 'pu-add' [
    command: string
] {
    do {pueue add -p $'nu -c "($command)" --config "($nu.config-path)" --env-config "($nu.env-path)"'}
    | null
}

def inspect2 [
    callback?: closure
] {
    let input = $in

    if $callback == $nothing {
        print $input
    } else {
        do $callback $input
    }

    $input
}

def 'nu-complete-random-sources' [] {
    ['chucknorris.io' 'forismatic.com']
}

def 'nu-complete-search-functions' [] {
    ['search-auto-refresh' 'search-with-backlinks', 'search-sync']
}

def 'nu-complete-neurons-nicks' [] {
    $env.cy.neurons.nick | dfr into-df | dfr into-nu | get nick
}

def 'nu-complete-colors' [] {
    ansi --list | get name | each while {|it| if $it != 'reset' {$it} }
}

def 'nu-complete-config-names' [] {
    ls $'($env.cy.path)/config/' -s
    | sort-by modified -r
    | get name
    | parse '{short}.{ext}'
    | where ext == 'toml'
    | get short
}

def 'nu-complete-git-branches' [] {
    ['main', 'dev']
}

def 'nu-complete-executables' [] {
    ['cyber' 'pussy']
}

# cyber keys in a form of table
def 'nu-complete-keys-table' [] {
    cyber keys list --output json | from json | select name address
}

# Helper function to use addresses for completions in --from parameter
def 'nu-complete keys values' [] {
    (nu-complete-keys-table).name | zip (nu-complete-keys-table).address | flatten
}

def 'nu-complete-bool' [] {
    [true, false]
}

def do-async [commands: string] {
    bash -c $'nu -c "($commands)" &'
}

def do-bash [commands: string] {
    bash -c $'"($commands)" &'
}

# > [{a: 1} {b: 2}] | to nuon
# [{a: 1}, {b: 2}]
#
# > [{a: 1} {b: 2}] | fill non-exist | to nuon
# [[a, b]; [1, null], [null, 2]]
def 'fill non-exist' [
    tbl?
    --value_to_replace (-v): any = ''
] {
    let $table = ($in | default $tbl)
    
    let $cols = (
        $table
        | par-each {|i| $i | columns} 
        | flatten 
        | uniq 
        | reduce --fold {} {|i acc| 
            $acc 
            | merge {$i: $value_to_replace}
        }
    )

    $table | each {|i| $cols | merge $i}
}

# A wrapper, to cache CLI requests
export def-env 'ber' [
    ...rest
    --seconds: int = 86400
    --exec: string
    --abci: string
    --absolutetimeouts
    --account: string
    --accountnumber (-a): string
    --address: string
    --admin: string
    --algo: string
    --allowedmessages: string
    --allowedvalidators: string
    --amino
    --amount: string
    --ascii
    --b64
    --bech: string
    --broadcastmode (-b): string
    --chainid: string
    --cointype: string
    --commission
    --commissionmaxchangerate: string
    --commissionmaxrate: string
    --commissionrate: string
    --computegpu
    --consensuscreate_empty_blocks
    --consensuscreate_empty_blocks_interval: string
    --consensusdouble_sign_check_height: string
    --counttotal
    --cpuprofile: string
    --db_backend: string
    --db_dir: string
    --delayed
    --denom: string
    --denyvalidators: string
    --deposit: string
    --depositor: string
    --description: string
    --details: string
    --device (-d)
    --dryrun
    --events: string
    --expiration: string
    --fast_sync
    --feeaccount: string
    --fees: string
    --force (-f)
    --forzeroheight
    --from: string
    --gas: string
    --gasadjustment: string
    --gasprices: string
    --generateonly
    --genesis_hash: string
    --genesistime: string
    --gentxdir: string
    --grpcaddress: string
    --grpcenable
    --grpconly
    --grpcwebaddress: string
    --grpcwebenable
    --haltheight: string
    --halttime: string
    --hdpath: string
    --height: string
    --help (-h)
    --hex
    --hex (-x)
    --home: string
    --iavldisablefastnode
    --identity: string
    --index: string
    --instantiateeverybody: string
    --instantiatenobody: string
    --instantiateonlyaddress: string
    --interactive (-i)
    --interblockcache
    --invcheckperiod: string
    --ip: string
    --jailallowedaddrs: string
    --keepaddrbook
    --keyringbackend: string
    --keyringdir: string
    --label: string
    --latestheight
    --ledger
    --limit: string
    --listnames (-n)
    --log_format: string
    --log_level: string
    --long
    --maxmsgs: string
    --minimumgasprices: string
    --minretainblocks: string
    --minselfdelegation: string
    --moniker: string
    --msgtype: string
    --multisig: string
    --multisigthreshold: string
    --newmoniker: string
    --noadmin
    --noautoincrement
    --nobackup
    --node (-n): string
    --node: string
    --nodedaemonhome: string
    --nodedirprefix: string
    --nodeid: string
    --nosort
    --note: string
    --offline
    --offset: string
    --output (-o): string
    --output: string
    --outputdir (-o): string
    --outputdocument: string
    --overwrite
    --overwrite (-o)
    --p2pexternaladdress: string
    --p2pladdr: string
    --p2ppersistent_peers: string
    --p2ppex
    --p2pprivate_peer_ids: string
    --p2pseed_mode
    --p2pseeds: string
    --p2punconditional_peer_ids: string
    --p2pupnp
    --packettimeoutheight: string
    --packettimeouttimestamp: string
    --page: string
    --pagekey: string
    --period: string
    --periodlimit: string
    --poolcoindenom: string
    --priv_validator_laddr: string
    --proposal: string
    --prove
    --proxy_app: string
    --pruning: string
    --pruninginterval: string
    --pruningkeepevery: string
    --pruningkeeprecent: string
    --pubkey: string
    --recover
    --reserveacc: string
    --reverse
    --rpcgrpc_laddr: string
    --rpcladdr: string
    --rpcpprof_laddr: string
    --rpcunsafe
    --runas: string
    --searchapi
    --securitycontact: string
    --sequence (-s): string
    --sequences: string
    --signatureonly
    --signmode: string
    --spendlimit: string
    --startingipaddress: string
    --statesyncsnapshotinterval: string
    --statesyncsnapshotkeeprecent: string
    --status: string
    --timeoutheight: string
    --title: string
    --trace
    --tracestore: string
    --transport: string
    --type: string
    --unarmoredhex
    --unsafe
    --unsafeentropy
    --unsafeskipupgrades: string
    --upgradeheight: string
    --upgradeinfo: string
    --v: string
    --vestingamount: string
    --vestingendtime: string
    --vestingstarttime: string
    --voter: string
    --wasmmemory_cache_size: string
    --wasmquery_gas_limit: string
    --wasmsimulation_gas_limit: string
    --website: string
    --withtendermint
    --xcrisisskipassertinvariants
    --yes (-y)
] {
    let $flags_nu = [
        $absolutetimeouts, $amino, $ascii, $b64, $commission, $computegpu,
        $consensuscreate_empty_blocks, $counttotal, $delayed, $device,
        $dryrun, $fast_sync, $force, $forzeroheight, $generateonly,
        $grpcenable, $grpconly, $grpcwebenable, $help, $hex, $iavldisablefastnode,
        $interactive, $interblockcache, $keepaddrbook, $latestheight, $ledger, $listnames,
        $long, $noadmin, $noautoincrement, $nobackup, $nosort, $offline, $overwrite,
        $p2ppex, $p2pseed_mode, $p2pupnp, $prove, $recover, $reverse, $rpcunsafe,
        $searchapi, $signatureonly, $trace, $unarmoredhex, $unsafe, $unsafeentropy,
        $withtendermint, $xcrisisskipassertinvariants, $yes
    ]
    let $flags_cli = ([
        '--absolute-timeouts', '--amino', '--ascii', '--b64', '--commission', '--compute-gpu',
        '--consensus.create_empty_blocks', '--count-total', '--delayed', '--device',
        '--dry-run', '--fast_sync', '--for-zero-height', '--force', '--generate-only',
        '--grpc-only', '--grpc-web.enable', '--grpc.enable', '--help', '--hex', '--iavl-disable-fastnode',
        '--inter-block-cache', '--interactive', '--keep-addr-book', '--latest-height', '--ledger', '--list-names',
        '--long', '--no-admin', '--no-auto-increment', '--no-backup', '--nosort', '--offline', '--overwrite',
        '--p2p.pex', '--p2p.seed_mode', '--p2p.upnp', '--prove', '--recover', '--reverse', '--rpc.unsafe',
        '--search-api', '--signature-only', '--trace', '--unarmored-hex', '--unsafe', '--unsafe-entropy',
        '--with-tendermint', '--x-crisis-skip-assert-invariants', '--yes'
    ])

    let $options_nu = [
        $abci, $account, $accountnumber, $address, $admin, $algo, $allowedmessages,
        $allowedvalidators, $amount, $bech, $broadcastmode, $chainid, $cointype,
        $commissionmaxchangerate, $commissionmaxrate, $commissionrate,
        $consensuscreate_empty_blocks_interval, $consensusdouble_sign_check_height,
        $cpuprofile, $db_backend, $db_dir, $denom, $denyvalidators, $deposit, $depositor,
        $description, $details, $events, $expiration, $feeaccount, $fees, $from, $gas,
        $gasadjustment, $gasprices, $genesis_hash, $genesistime, $gentxdir, $grpcaddress,
        $grpcwebaddress, $haltheight, $halttime, $hdpath, $height, $home, $identity, $index,
        $instantiateeverybody, $instantiatenobody, $instantiateonlyaddress, $invcheckperiod,
        $ip, $jailallowedaddrs, $keyringbackend, $keyringdir, $label, $limit, $log_format,
        $log_level, $maxmsgs, $minimumgasprices, $minretainblocks, $minselfdelegation,
        $moniker, $msgtype, $multisig, $multisigthreshold, $newmoniker, $node, $nodedaemonhome,
        $nodedirprefix, $nodeid, $note, $offset, $output, $outputdir, $outputdocument,
        $p2pexternaladdress, $p2pladdr, $p2ppersistent_peers, $p2pprivate_peer_ids, $p2pseeds,
        $p2punconditional_peer_ids, $packettimeoutheight, $packettimeouttimestamp, $page,
        $pagekey, $period, $periodlimit, $poolcoindenom, $priv_validator_laddr, $proposal,
        $proxy_app, $pruning, $pruninginterval, $pruningkeepevery,
        $pruningkeeprecent, $pubkey, $reserveacc, $rpcgrpc_laddr, $rpcladdr, $rpcpprof_laddr,
        $runas, $securitycontact, $sequence, $sequences, $signmode, $spendlimit, $startingipaddress,
        $statesyncsnapshotinterval, $statesyncsnapshotkeeprecent, $status, $timeoutheight, $title,
        $tracestore, $transport, $type, $unsafeskipupgrades, $upgradeheight, $upgradeinfo, $v,
        $vestingamount, $vestingendtime, $vestingstarttime, $voter, $wasmmemory_cache_size,
        $wasmquery_gas_limit, $wasmsimulation_gas_limit, $website
    ]
    let $options_cli = [
        '--abci', '--account', '--account-number', '--address', '--admin', '--algo', '--allowed-messages',
        '--allowed-validators', '--amount', '--bech', '--broadcast-mode', '--chain-id', '--coin-type',
        '--commission-max-change-rate', '--commission-max-rate', '--commission-rate',
        '--consensus.create_empty_blocks_interval', '--consensus.double_sign_check_height',
        '--cpu-profile', '--db_backend', '--db_dir', '--denom', '--deny-validators', '--deposit', '--depositor',
        '--description', '--details', '--events', '--expiration', '--fee-account', '--fees', '--from', '--gas',
        '--gas-adjustment', '--gas-prices', '--genesis-time', '--genesis_hash', '--gentx-dir',
        '--grpc-web.address', '--grpc.address', '--halt-height', '--halt-time', '--hd-path', '--height', '--home', '--identity', '--index',
        '--instantiate-everybody', '--instantiate-nobody', '--instantiate-only-address', '--inv-check-period',
        '--ip', '--jail-allowed-addrs', '--keyring-backend', '--keyring-dir', '--label', '--limit', '--log_format',
        '--log_level', '--max-msgs', '--min-retain-blocks', '--min-self-delegation', '--minimum-gas-prices',
        '--moniker', '--msg-type', '--multisig', '--multisig-threshold', '--new-moniker', '--node', '--node-daemon-home',
        '--node-dir-prefix', '--node-id', '--note', '--offset', '--output', '--output-dir', '--output-document',
        '--p2p.external-address', '--p2p.laddr', '--p2p.persistent_peers', '--p2p.private_peer_ids', '--p2p.seeds',
        '--p2p.unconditional_peer_ids', '--packet-timeout-height', '--packet-timeout-timestamp', '--page',
        '--page-key', '--period', '--period-limit', '--pool-coin-denom', '--priv_validator_laddr', '--proposal',
        '--proxy_app', '--pruning', '--pruning-interval', '--pruning-keep-every',
        '--pruning-keep-recent', '--pubkey', '--reserve-acc', '--rpc.grpc_laddr', '--rpc.laddr', '--rpc.pprof_laddr',
        '--run-as', '--security-contact', '--sequence', '--sequences', '--sign-mode', '--spend-limit', '--starting-ip-address',
        '--state-sync.snapshot-interval', '--state-sync.snapshot-keep-recent', '--status', '--timeout-height', '--title',
        '--trace-store', '--transport', '--type', '--unsafe-skip-upgrades', '--upgrade-height', '--upgrade-info', '--v',
        '--vesting-amount', '--vesting-end-time', '--vesting-start-time', '--voter', '--wasm.memory_cache_size',
        '--wasm.query_gas_limit', '--wasm.simulation_gas_limit', '--website'
    ]

    let $list_flags_out = (
        $flags_nu
        | enumerate
        | reduce -f [] {
            |i acc| if $i.item {
                $acc
                | append ($flags_cli | get $i.index)
            } else {
                $acc
            }
        }
    )

    let $list_options_out = (
        $options_nu
        | enumerate
        | reduce -f [] {
            |i acc| if not ($i.item | is-empty) {
                $acc
                | append ($options_cli | get $i.index)
                | append $i.item
            } else {
                $acc
            }
        }
    )
    # print $list_flags_out

    let $exec = ($exec | default $env.cy.exec)

    let $important_options = (
        $list_options_out
        | enumerate
        | reduce -f '' {
            |i acc| if ($i.item in ['--page', '--height', '--events']) {
                [$acc $i.item ($list_options_out | get ($i.index + 1))] | str join ''
            } else {
                $acc
            }
        } | '+' + $in
    )

    let $cfolder = $'($env.cy.path)/cache/cli_out/'
    let $command = $'($exec)_($rest | str join "_")($important_options | str replace "/" "")'
    let $ts1 = (date now | into int)

    # print $important_options
    let $filename = $'($cfolder)($command)-($ts1).json'

    let $cache_ls = (ls $cfolder)

    # print 'cached_files'
    let $cached_file = (
        if $cache_ls != null {
            # print '$cache_ls != null'

            let $a1 = (
                $cache_ls
                | where name =~ $'($command)'
                | inspect
            )

            if ($a1 | length) == 0 {
                # print 'here is null'
                null
            } else {
                $a1
                | sort-by modified --reverse
                | where modified > (date now | into int | $in - $seconds | into datetime)
                | get -i name.0
            }
        } else {
            null
        }
    )

    let $content = (
        if ($cached_file != null) {
            print 'cached used'
            open $cached_file
        } else  {
            print $'request command from cli, saving to ($filename)'
            print $'($exec) ($rest) --output json ($list_flags_out)'
            # let $out = (^($exec) $rest --output json $list_options_out $list_flags_out | from json)
            pu-add $'($exec) ($rest | str join " ") --output json ($list_options_out | str join " ") ($list_flags_out | str join " ") | save -r ($filename)'
            # let $out1 = do -i {^($exec) $rest --output json $list_flags_out | from json}
            # let $out = (^($exec) $rest --output json $list_options_out $list_flags_out | from json)
            # if $out != null {$out | save $filename}
            # $out

        }
    )

    $content
}

# https://github.com/nushell/nushell/blob/main/crates/nu-std/lib/mod.nu
# print a command name as dimmed and italic
def pretty-command [] {
    let command = $in
    return $"(ansi default_dimmed)(ansi default_italic)($command)(ansi reset)"
}

# give a hint error when the clip command is not available on the system
def check-clipboard [
    clipboard: string  # the clipboard command name
    --system: string  # some information about the system running, for better error
] {
    if (which $clipboard | is-empty) {
        error make --unspanned {
            msg: $"(ansi red)clipboard_not_found(ansi reset):
    you are running ($system)
    but
    the ($clipboard | pretty-command) clipboard command was not found on your system."
        }
    }
}

# Clipboard took from here https://github.com/nushell/nushell/blob/main/crates/nu-std/lib/mod.nu

# put the end of a pipe into the system clipboard.
#
# Dependencies:
#   - xclip on linux x11
#   - wl-copy on linux wayland
#   - clip.exe on windows
#
# Examples:
#     put a simple string to the clipboard, will be stripped to remove ANSI sequences
#     >_ "my wonderful string" | clip
#     my wonderful string
#     saved to clipboard (stripped)
#
#     put a whole table to the clipboard
#     >_ ls *.toml | clip
#     ╭───┬─────────────────────┬──────┬────────┬───────────────╮
#     │ # │        name         │ type │  size  │   modified    │
#     ├───┼─────────────────────┼──────┼────────┼───────────────┤
#     │ 0 │ Cargo.toml          │ file │ 5.0 KB │ 3 minutes ago │
#     │ 1 │ Cross.toml          │ file │  363 B │ 2 weeks ago   │
#     │ 2 │ rust-toolchain.toml │ file │ 1.1 KB │ 2 weeks ago   │
#     ╰───┴─────────────────────┴──────┴────────┴───────────────╯
#
#     saved to clipboard
#
#     put huge structured data in the clipboard, but silently
#     >_ open Cargo.toml --raw | from toml | clip --silent
#
#     when the clipboard system command is not installed
#     >_ "mm this is fishy..." | clip
#     Error:
#       × clipboard_not_found:
#       │     you are using xorg on linux
#       │     but
#       │     the xclip clipboard command was not found on your system.
def clip [
    --silent: bool  # do not print the content of the clipboard to the standard output
    --no-notify: bool  # do not throw a notification (only on linux)
    --expand (-e): bool  # auto-expand the data given as input
] {
    let input = (
        $in
        | if $expand { table --expand } else { table }
        | into string
    )

    match $nu.os-info.name {
        "linux" => {
            if ($env.WAYLAND_DISPLAY? | is-empty) {
                check-clipboard xclip --system $"('xorg' | pretty-command) on linux"
                $input | xclip -sel clip
            } else {
                check-clipboard wl-copy --system $"('wayland' | pretty-command) on linux"
                $input | wl-copy
            }
        },
        "windows" => {
            chcp 65001  # see https://discord.com/channels/601130461678272522/601130461678272524/1085535756237426778
            check-clipboard clip.exe --system $"('xorg' | pretty-command) on linux"
            $input | clip.exe
        },
        "macos" => {
            check-clipboard pbcopy --system macOS
            $input | pbcopy
        },
        _ => {
            error make --unspanned {
                msg: $"(ansi red)unknown_operating_system(ansi reset)
    '($nu.os-info.name)' is not supported by the ('clip' | pretty-command) command.

    please open a feature request in the 
    [issue tracker](char lparen)https://github.com/nushell/nushell/issues/new/choose(char rparen) 
    to add your operating system to the standard library."
            }
        },
    }

    if not $silent {
        print $input
        print $"(ansi white_italic)(ansi white_dimmed)saved to clipboard(ansi reset)"
    }

    if (not $no_notify) and ($nu.os-info.name == linux) {
        notify-send "std clip" "saved to clipboard"
    }
}

def agree [
    prompt
    --default-not (-n): bool
] {
    let prompt = if ($prompt | str ends-with '!') {
        $'(ansi red)($prompt)(ansi reset)'
    } else {
        $'($prompt)'
    }
    print $prompt
    
    if $default_not { [no yes] } else { [yes no] } 
    | input list 
    | inspect2 
    | $in in [yes]
}