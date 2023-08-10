# Cy - a tool for interactions wity cybergraphs
# https://github.com/cyber-prophet/cy
#
# Use:
# > overlay use ~/cy/cy.nu -p -r

# use std assert equal

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

    ['ipfs', 'bat', 'mdcat', 'curl', 'pueue', 'cyber', 'pussy']
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

    $env.cy = (
        try {
            $config
            | merge (
                open $'($config.path)/config/($config.config-name).toml'
            )
            | sort
        } catch {
            cprint $'A config file was not found. Run *"cy config-new"*'
            $config
        }
    )

    make_default_folders_fn
}

# Pin a text particle
#
# > cy pin-text 'cyber'
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#
# > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt'
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#
# > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt' --dont_follow_path
# QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
#
# > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#
# > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --dont_detect_cid
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

    if (not $dont_detect_cid) and (is-cid $text) {
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

#[test]
def test_link_texts [] {
    # use ~/cy/cy.nu
    use std assert equal
    let expect = {
        from_text: cyber,
        to_text: bostrom,
        from: "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
        to: "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"
    }

    let result = (
        tmp-clear;
        link-texts "cyber" "bostrom"
    )

    equal $expect $result
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
    ...rest: string
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
# - from_text: bostrom.txt
#   to_text: pinned_file:bostrom.txt
#   from: QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k
#   to: QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb
# - from_text: cyber.txt
#   to_text: pinned_file:cyber.txt
#   from: QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
#   to: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
# > cd ..; rm -r linkfilestest
export def 'link-files' [
    ...files: string        # filenames to add into the local ipfs node
    --link_filenames (-n)   # Add filenames as a from link
    --disable_append (-D)   # Don't append links to the tmp table
    --quiet                 # Don't output results page
    --yes (-y)              # Confirm uploading files without request
] {
    if (ps | where name =~ ipfs | length | $in == 0) {
        error make {msg: "ipfs service isn't running. Try 'brew services start ipfs'" }
    }
    
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

#[test]
def test-link-files [] {
    use std assert equal

    mkdir linkfilestest; cd linkfilestest
    'cyber' | save -f cyber.txt; 'bostrom' | save -f bostrom.txt

    let expect = [
        [from_text, to_text, from, to]; 
        [bostrom.txt, "pinned_file:bostrom.txt", 
        "QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        [cyber.txt, "pinned_file:cyber.txt", 
        "QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"]
    ]

    let result = (
        link-files --link_filenames --yes
    )

    cd ..; rm -r linkfilestest 

    equal $expect $result
}


# Create a cyberlink according to semantic construction of following a neuron
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
        cprint $"*($neuron)* doesn't look like an address"
        return
    }

    link-texts 'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx' $neuron
}

#[test]
def test-follow [] {
    use std assert equal

    let expect = {
        from_text: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx", 
        to_text: "bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8", 
        from: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx", 
        to: "QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af"
    }

    let result = (
        follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
    )

    equal $expect $result
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

#[test]
def test-tweet [] {
    use std assert equal

    let expect = {
        from_text: "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx", 
        to_text: "cyber-prophet is cool", 
        from: "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx",
        to: "QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK"
    }

    let result = (
        tmp-clear;
        tweet 'cyber-prophet is cool' --disable_send;
    )

    equal $expect $result
}

# Add a random chuck norris cyberlink to the temp table
def 'link-chuck' [] {
    let $quote = (
        http get https://api.chucknorris.io/jokes/random | get value |
        $in + "\n\n" + 'via [Chucknorris.io](https://chucknorris.io)'
    )

    cprint -f '=' $quote

    link-texts --quiet 'chuck norris' $quote
}

# Add a random quote cyberlink to the temp table
def 'link-quote' [] {
    let quote = (
        http get -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=text
        | $in + "\n\n" + 'via [forismatic.com](https://forismatic.com)'
    )

    cprint -f '=' $quote

    # link-texts 'quote' $quote
    link-texts --quiet 'quote' $quote
}

# Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)
#
# > cy link-random
# ==========================================================
# Chuck Norris IS Lukes father.
#
# via [Chucknorris.io](https://chucknorris.io)
# ==========================================================
#
# > cy link-random forismatic.com
# ==========================================================
# He who knows himself is enlightened.   (Lao Tzu )
#
# via [forismatic.com](https://forismatic.com)
# ==========================================================
export def 'link-random' [
    source?: string@'nu-complete-random-sources'
    -n: int = 1 # Number of links to append
] {
    1..$n 
    | each {|i|
        if $source == 'forismatic.com' {
            link-quote
        } else {
            link-chuck
        }
    };

    null
}

# View the temp cyberlinks table
#
# > cy tmp-view | to yaml
# There are 2 cyberlinks in the temp table:
# - from_text: chuck norris
#   to_text: |-
#     Chuck Norris IS Lukes father.
#
#     via [Chucknorris.io](https://chucknorris.io)
#   from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
#   to: QmSLPzbM5NVmXuYCPiLZiePAhUcDCQncYUWDLs7GkLqC7J
#   date_time: 20230701-134134
# - from_text: quote
#   to_text: |-
#     He who knows himself is enlightened. (Lao Tzu )
#
#     via [forismatic.com](https://forismatic.com)
#   from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
#   to: QmWoxYsWYuTP4E2xaQHr3gUZZTBC7HdNDVhis1BK9X3qjX
#   date_time: 20230702-113842
export def 'tmp-view' [
    --quiet (-q) # Don't print info
] {
    let $dummy = ([[from]; [null]] | first 0)

    let $tmp_links = (
        if (tmp-links-location-env) {
            $env.cy.tmp_links? | default $dummy
        } else {
            try {
                open $'($env.cy.path)/cyberlinks_temp.csv'
            } catch {
                $dummy
            }
        }
    )

    if (not $quiet) {
        let $links_count = ($tmp_links | length)

        if $links_count == 0 {
            cprint $'The temp cyberlinks table *"($env.cy.path)/cyberlinks_temp.csv"* is empty.
            You can add cyberlinks to it manually or by using commands like *"cy link-texts"*'
        } else {
            cprint $'There are *($links_count) cyberlinks* in the temp table:'
        }
    }

    $tmp_links
}

# Read the tmp-links table from the environment or from the csv file
export def-env 'tmp-links-location-set' [
    bool: bool
] {
    $env.cy.use_tmp_links_env = $bool
}

def 'tmp-links-location-env' [] {
    $env.cy.use_tmp_links_env? | default false
}

# Append piped-in table to the temp cyberlinks table
export def-env 'tmp-append' [
    cyberlinks?             # cyberlinks table
    --quiet (-q)
] {
    $in
    | default $cyberlinks
    | upsert date_time (now-fn)
    | prepend (tmp-view -q)
    | if $quiet { tmp-replace -q } else { tmp-replace }
}

# Replace the temp table with piped-in table
export def-env 'tmp-replace' [
    cyberlinks?             # cyberlinks table
    --quiet (-q)
] {
    let $cl = ($in | default $cyberlinks)

    if not (tmp-links-location-env) {
        $cl | save $'($env.cy.path)/cyberlinks_temp.csv' --force
    }

    $env.cy.tmp_links = if (tmp-links-location-env) {$cl}

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
            cprint 'No columns *"from_text"* or *"to_text"* found. Add at least one of them.' ;
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
#
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

        cprint $'*($existed_links_count) cyberlinks* was/were already created by *($env.cy.address)*'
        ($existed_links | select from_text from to_text to | each {|i| print $i})
        cprint -c red -a 2 'So they were removed from the temp table!'

        $links_with_status | filter {|x| not $x.link_exist} | tmp-replace
    } else {
        cprint 'There are no cyberlinks in the temp table for the current address exist the cybergraph'
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

# Create a tx from the piped in or temp cyberlinks table, sign and broadcast it
#
# > cy tmp-send-tx | to yaml
# cy: 2 cyberlinks should be successfully sent
# code: 0
# txhash: 9B37FA56D666C2AA15E36CDC507D3677F9224115482ACF8CAF498A246DEF8EB0
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
        {'cy': ('Use *"cy tmp-remove-existed"*' | cprint $in --echo) }
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
#
# > cy passport-get cyber-prophet | to yaml
# owner: bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
# addresses:
# - label: null
#   address: cosmos1sgy27lctdrc5egpvc8f02rgzml6hmmvhhagfc3
# avatar: Qmdwi54WNiu1phvMA2digYHRzQRHRkS1pKWAnpawjSWUZi
# nickname: cyber-prophet
# data: null
# particle: QmRumrGFrqxayDpySEkhjZS1WEtMyJcfXiqeVsngqig3ak
export def 'passport-get' [
    address_or_nick: string # Name of passport or neuron's address
] {
    def 'dump-passport' [] {
        let $input = $in

        let $yaml = $'($env.cy.path)/cache/yaml/passport-($address_or_nick).yaml'

        if ($yaml | path exists) {
            open -r $yaml
            | save -a $'($env.cy.path)/cache/yaml/archive/passport-($address_or_nick).yaml'
        }

        if $input != {} {
            {ts: (date now)}
            | merge $input
            | [$in]
            | save -f $yaml

            $input
        }
    }

    let $json = (
        if (is-neuron $address_or_nick) {
            $'{"active_passport":{"address":"($address_or_nick)"}}'
        } else {
            $'{"passport_by_nickname":{"nickname":"($address_or_nick)"}}'
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
        $out.stdout
        | from json
        | get data
        | merge $in.extension
        | reject extension approvals token_uri
        | dump-passport
    } else {
        cprint --before 1 --after 2 $'No passport for *($address_or_nick)* is found'
        {}
    }
}


# Set a passport's particle, data or avatar field for a given nickname
#
# > cy passport-set QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
# The particle field for maxim should be successfuly set to QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
export def 'passport-set' [
    particle: string
    nickname?                       # Provide a passport's nickname. If null - the nick from config will be used.
    --field: string = 'particle'    # A passport's field to set: particle, data, new_avatar
    --verbose                       # Show the node's response
] {
    if not (is-cid $particle) {
        print $"($particle) doesn't look like a cid"
        return
    }

    if $field not-in ['particle', 'data', 'new_avatar'] {
        print $'The field must be "particle", "data" or "new_avatar". You provided ($field)'
        return
    }

    let $nick = (
        $nickname
        | default $env.cy.passport-nick?
        | if ($in | is-empty) {
            print 'there is no nickname for passport set. To update the fields we need one.'
            return
        } else {}
    )

    let $json = $'{"update_data":{"nickname":"($nick)","($field)":"($particle)"}}'

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'

    let $params = [
        '--from' $env.cy.address
        '--node' 'https://rpc.bostrom.cybernode.ai:443'
        '--output' 'json'
        '--yes'
        '--broadcast-mode' 'block'
        '--gas' '23456789'
    ]

    do -i {
        ^cyber tx wasm execute $pcontract $json $params
    } | complete
    | if $in.exit_code == 0 {
        if $verbose {
            get stdout
            | from json
            | upsert raw_log {|i| $i.raw_log | from json}
            | select raw_log code txhash
        } else {
            cprint $'The *($field)* field for *($nick)* should be successfuly set to *($particle)*'
        }
    } else {
        cprint $'The particle might not be set. You can check it with the command
        "*cy passport-get ($nick) | get ($field) | $in == ($particle)*"'
    }
}


# Output neurons dict
export def 'dict-neurons' [
    --df        # output as a dataframe
] {
    open $'($env.cy.path)/graph/neurons_dict.yaml'
    | if $df {
        fill non-exist
        | dfr into-df
    } else { }
}

# Add neurons to YAML-dictionary WIP
export def 'dict-neurons-add' [] {
    let $i = $in

    let $desc = ($i | describe)

    let $candidate = (
        $i 
        | if ($desc == 'list<string>') {
            wrap neuron
        } else if ($desc == 'dataframe') {
            dfr into-nu
        } else {}
    )

    let $validated_neurons = (
        if ('neuron' in ($candidate | columns)) {
            $candidate 
            | where (is-neuron $it.neuron)
        } else {
            error make {msg: 'no neuron column is found'}
        }
    )

    dict-neuron 
    | par-each {|i| $i | merge ($validated_neurons | get -i $i.neuron)}
}

# Update neurons YAML-dictionary
export def 'dict-neurons-update' [
    --passport              # Update passport data
    --balance               # Update balances data
    --karma                 # Update karma
    --all (-a)              # Update passport, balance, karma
    --threads (-t) = 30     # Number of threads to use for downloading
    --dont_save             # Don't update the file on a disk, just output the results
    --quiet (-q)            # Don't output results table
] {
    graph-links-df
    | dfr select neuron
    | dfr unique
    | dfr join --left (dict-neurons --df) neuron neuron
    | dfr into-nu
    | filter {|i| is-neuron $i.neuron}
    | if $passport or $all {
        par-each -t $threads {|i|
            $i | merge (passport-get $i.neuron)
        }
    } else {}
    | if $balance or $all {
        par-each -t $threads {|i|
            $i | merge (balance-get $i.neuron)
        }
    } else {}
    | if $karma or $all {
        par-each -t $threads {|i|
            $i | merge (karma-get $i.neuron)
        }
    } else {}
    | upsert update_ts (date now)
    | if $dont_save {} else {
        do {
            |i|
            let $yaml = $'($env.cy.path)/graph/neurons_dict.yaml'
            backup-fn $yaml;

            dict-neurons
            | prepend $i
            | uniq-by neuron
            | save -f $yaml;

            $i
        } $in
    } | if $quiet { null } else { }
}

# Download a snapshot of cybergraph by graphkeeper
export def-env 'graph-download-snapshot' [
    --disable_update_parquet (-D)   # Don't update the particles parquet file
] {
    make_default_folders_fn

    let $path = $'($env.cy.path)/graph'
    let $cur_data_cid = (passport-get graphkeeper | get data -i)
    let $update_info = (
        $'($path)/update.toml'
        | if ($in | path exists) {open} else {{}}
    )
    let $last_data_cid = ($update_info | get -i last_cid)

    if ($last_data_cid == $cur_data_cid) {
        print 'no updates found'
        return
    }

    print 'Downloading cyberlinks.csv'
    ipfs get $'($cur_data_cid)/graph/cyberlinks.csv' -o $path
    print 'Downloading cyberlinks.csv'
    ipfs get $'($cur_data_cid)/graph/cyberlinks_contracts.csv' -o $path
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

    cprint $'The graph data has been downloaded to the *"($path)"* directory'

    if (not $disable_update_parquet) {
        print 'Updating particles parquet'
        graph-update-particles-parquet
    }
}

# Output unique list of particles from piped in cyberlinks table
#
# > cy graph-to-particles --include_content | dfr into-nu | first 2 | to yaml
# - index: 0
#   particle: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05
#   nick: mrbro_bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   particle_index: 0
#   size: 5
#   content_s: cyber
# - index: 1
#   particle: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05
#   nick: mrbro_bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   particle_index: 1
#   size: 11
#   content_s: fuckgoogle!
export def 'graph-to-particles' [
    --from                  # Use only particles from the 'from' column
    --to                    # Use only particles from the 'to' column
    --include_system (-s)   # Include tweets, follow and avatar paritlces
    --include_content       # Include column with particles' content
    --cids_only (-c)        # Output one column with CIDs only
] {
    let $c = (
        graph-links-df
        | dfr into-lazy
    )

    let $p = (dfr open $'($env.cy.path)/graph/particles.parquet')

    if ($to and $from) {
        print 'you need to use only one of two flags or none flags at all'
        return
    }

    (
        $c
        | dfr rename [particle_from particle_to] [particle init-role]
        | dfr fetch 0  # Create dummy dfr to have something to appended to
        | if not $to { dfr into-lazy
            | dfr append --col (
                | $c
                | dfr rename particle_from particle
                | dfr drop particle_to
                | dfr with-column [
                    (dfr lit 'from' | dfr as 'init-role'),
                ]
            )
        } else {}
        | if not $from { dfr into-lazy
            | dfr append --col (
                $c
                | dfr rename particle_to particle
                | dfr drop particle_from
                | dfr with-column [
                    (dfr lit 'to' | dfr as 'init-role'),
                ]
            )
        } else {} | dfr into-lazy
        | dfr sort-by height
        | dfr unique --subset [particle]
        | if not $include_system { dfr into-lazy
            | dfr filter-with (
                (dfr col particle)
                | dfr is-in (system_cids)
                | dfr expr-not
            )
        } else {}
        | if $cids_only { dfr into-lazy
            | dfr select particle
        } else { dfr into-lazy
            | dfr with-column (
                dfr arg-where ((dfr col height) != 0) | dfr as particle_index
            )
        }
        # not elegant solution to keep columns from particles and to have particle_index in this function
        | if $include_content { dfr into-lazy
            | dfr select particle
            | dfr join $p particle particle
        } else {} | dfr into-lazy
        | dfr collect
    )
}

# Update the 'particles.parquet' file (it inculdes content of text files)
export def 'graph-update-particles-parquet' [
    --full_content  # include column with full content of particles
    --quiet (-q)    # don't print info about the saved parquet file
] {

    let $ls_files = (
        ls -s $'($env.cy.path)/graph/particles/safe' # I use ls instead of glob to have the filesize column
        | reject modified type
        | upsert content {
            |i| open -r $'($env.cy.path)/graph/particles/safe/($i.name)'
        }
        | dfr into-df
        | dfr with-column (
            $in
            | dfr select name
            | dfr str-slice 0 -l 46
            | dfr rename name particle
        )
        | dfr with-column (
            $in
            | dfr select content
            | dfr str-slice 0 -l 150
            | dfr replace-all -p "\n" -r '⏎'
            | dfr rename content content_s
        )
        | if $full_content {} else {
            dfr drop content
        }
    )


    let $content_df2 = (
        graph-to-particles --include_system
        | dfr join --left $ls_files particle particle
    )

    let $m2_mask_null = (
        $content_df2
        | dfr select content_s
        | dfr is-null
    )

    backup-fn $'($env.cy.path)/graph/particles.parquet'

    (
        $content_df2
        | dfr with-column (
            $content_df2
            | dfr get content_s
            | dfr set 'timeout' --mask $m2_mask_null
            | dfr rename string content_s
        )
        | dfr with-column ( # short name to make content_s unique
            $in
            | dfr select particle
            | dfr str-slice 39
            | dfr rename particle short_cid
        )
        | dfr with-column (
            dfr concat-str '|' [(dfr col content_s) (dfr col short_cid)]
        )
        | dfr drop short_cid
        | dfr to-parquet $'($env.cy.path)/graph/particles.parquet'
        | print ($in | get 0 -i)
    )
}

# Filter the graph to chosen neurons only
export def 'graph-filter-neurons' [
    ...neurons_nicks: string@'nu-complete-neurons-nicks'
] {
    let $cyberlinks = (graph-links-df)

    $neurons_nicks
    | dfr into-df
    | dfr join ( dict-neurons --df ) '0' nick
    | dfr select neuron
    | dfr join $cyberlinks neuron neuron
}

# Append related cyberlinks to the piped in graph
export def 'graph-append-related' [] {
    let $c = (
        $in
        | dfr into-lazy
        | dfr with-column [
            (dfr lit '1' | dfr as 'step'),
            (dfr arg-where ((dfr col height) != 0) | dfr as link_local_index)
        ]
    )

    let $to_2 = (
        $c
        | graph-to-particles --include_system | dfr into-lazy
        | dfr select particle link_local_index
        | dfr rename particle particle_to
        | dfr join (
            graph-links-df --not_in --exclude_system
            | dfr into-lazy
        ) particle_to particle_to
        | dfr with-column [
            (dfr lit '2to' | dfr as 'step')
        ]
    )

    let $from_2 = (
        $c
        | graph-to-particles --include_system | dfr into-lazy
        | dfr select particle link_local_index
        | dfr rename particle particle_from
        | dfr join (
            graph-links-df --not_in --exclude_system
            | dfr into-lazy
        ) particle_from particle_from
        | dfr with-column [
            (dfr lit '2from' | dfr as 'step')
        ]
    )

    $c
    | dfr append -c $to_2
    | dfr append -c $from_2  | dfr into-lazy
    | dfr sort-by height
    | dfr unique --subset [neuron particle_from particle_to]
    | dfr collect

}

export def 'graph-neurons-stats' [] {
#neuron-stats-works
    let c = (graph-links-df)
    let p = (dfr open $'($env.cy.path)/graph/particles.parquet')

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
        | dfr join --left $followers neuron content_s
        | dfr join --left $follows neuron neuron
        | dfr join --left $tweets neuron neuron
        | dfr join --left ( dict-neurons --df ) neuron neuron
    )
}

# Export the entire graph into CSV file for import to Gephi
export def 'graph-to-gephi' [] {
    let $cyberlinks = (graph-links-df)
    let $particles = (
        $cyberlinks
        | graph-to-particles --include_system --include_content
    )

    let $t1_height_index = (
        $cyberlinks.height
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
        $cyberlinks
        | dfr join --left $t1_height_index height height
        | dfr with-column (
            dfr concat-str '' [
                (dfr lit '<[')
                (dfr col height_index)
                (dfr lit ($',($height_index_max)]>'))
            ]
            | dfr as Timeset
        )
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
        | dfr into-nu
        | reject index
        | move id label cid --before height
        | save $'($env.cy.path)/gephi/!particles.csv' -f
    )
}

# Logseq export WIP
export def 'graph-to-logseq' [
    # --path: string
] {
    let $cyberlinks = (graph-links-df | inspect2)
    let $particles = (
        $cyberlinks
        | graph-to-particles --include_system --include_content
        | inspect2
    )

    let $path = $'($env.cy.path)/logseq/(date now | date format "%Y-%m-%d_%H-%M-%S")/'
    mkdir $'($path)/pages'
    mkdir $'($path)/journals'

    $particles
    | dfr into-nu
    | par-each {|p|
        # print $p.particle
        $"author:: [[($p.nick)]]\n\n- (
            do -i {open $'($env.cy.ipfs-files-folder)/($p.particle).md'
            | default "timeout"
        } )\n- --- \n- ## cyberlinks from \n" |
        save $'($path)/pages/($p.particle).md'
    }

    $cyberlinks
    | dfr into-nu
    | each {|c|
        $"\t- [[($c.particle_to)]] ($c.height) [[($c.nick?)]]\n" |
        save $'($path)/pages/($c.particle_from).md' -a
    }
}

# Add content_s and neuron's nicknames columns to piped in or the whole graph df
# > cy graph-filter-neurons maxim_bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
# | cy graph-add-metadata | dfr into-nu | first 2 | to yaml
# - index: 0
#   neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
#   particle_from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
#   particle_to: QmaxuSoSUkgKBGBJkT2Ypk9zWdXor89JEmaeEB66wZUHYo
#   height: 87794
#   timestamp: 2021-11-11
#   content_s_from: tweet
#   content_s_to: '"MIME type" = "image/svg+xml"'
#   nick: maxim_bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
# - index: 1
#   neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
#   particle_from: Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs
#   particle_to: QmYnLm5MFGFwcoXo65XpUyCEKX4yV7HbCAZiDZR95aKr4t
#   height: 88371
#   timestamp: 2021-11-11
#   content_s_from: avatar
#   content_s_to: '"MIME type" = "image/svg+xml"'
#   nick: maxim_bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
export def 'graph-add-metadata' [] {
    let $c = (graph-links-df)
    let $p = (
        dfr open $'($env.cy.path)/graph/particles.parquet'
        | dfr select particle content_s
    )

    let $columns = ($c | dfr columns)

    $c
    | if 'particle_from' in $columns {
        dfr join --left $p particle_from particle
        | dfr rename content_s content_s_from
    } else {}
    | if 'particle_to' in $columns {
        dfr join --left $p particle_to particle
        | dfr rename content_s content_s_to
    } else {}
    | if 'particle' in $columns {
        dfr join --left $p particle particle
    } else {}
    | if 'neuron' in $columns {
        dfr join --left (
            dict-neurons --df
            | dfr select neuron nick
        ) neuron neuron
    }
}

# Output full graph, or pass piped in graph
#
# > cy graph-links-df | dfr into-nu | first 1 | to yaml
# - index: 0
#   particle_from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   particle_to: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05
export def 'graph-links-df' [
    --not_in            # don't catch pipe in
    --exclude_system    # exclude system particles in from column (tweet, follow, avatar)
    --include_contracts # include links from contracts (including passport)
] {
    if $not_in {
        dfr open $'($env.cy.path)/graph/cyberlinks.csv'
    } else {
        $in | default (dfr open $'($env.cy.path)/graph/cyberlinks.csv')
    }
    | if $include_contracts {
        dfr append -c (
            dfr open $'($env.cy.path)/graph/cyberlinks_contracts.csv'
        )
    } else {}
    | if $exclude_system {
        dfr into-lazy
        | dfr filter-with (
            (dfr col particle_from)
            | dfr is-in (system_cids)
            | dfr expr-not
        )
    } else { }
}

export def 'graph-particles-df' [] {
    let $p = (dfr open $'($env.cy.path)/graph/particles.parquet')
    $p
}

# Create a config JSON to set env variables, to use them as parameters in cyber cli
export def-env 'config-new' [
    # config_name?: string@'nu-complete-config-names'
] {
    cprint -c green 'Choose the name of executable:'
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

    cprint -c green --before 1 'Select the address to send transactions from:'

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
        | get nickname -i
    )

    if (not ($passport_nick | is-empty)) {
       cprint -c default_italic --before 1 $'Passport nick *($passport_nick)* will be used'
    }

    let $chain_id_def = (if ($exec == 'cyber') {
            'bostrom'
        } else {
            'space-pussy'
        }
    )

    let $chain_id = ($chain_id_def)


    let $rpc_def = if ($exec == 'cyber') {
        'https://rpc.bostrom.cybernode.ai:443'
    } else {
        'https://rpc.space-pussy.cybernode.ai:443'
    }

    cprint -c green --before 1 'Select the address of RPC api for interacting with the blockchain:'
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

    cprint -c green --before 1 'Select the ipfs service to store particles:'

    let $ipfs_storage = (
        [cybernode, kubo, both]
        | input list -f
        | inspect2
    )

    {
        'config-name': $config_name
        'exec': $exec
        'address': $address
        'passport-nick': $passport_nick
        'chain-id': $chain_id
        'ipfs-storage': $ipfs_storage
        'rpc-address': $rpc_address
    } | config-save $config_name

    make_default_folders_fn
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
            cprint -c green --before 1 $'($file_name) exists. Do you want to overwrite it?'

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

    $env.cy = $config_toml

    cprint -c green_underline -b 1 'Config is loaded'
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
        ber query rank search $cid $page 10
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
                $"($particle | mdcat --columns 100 -)(char nl)(ansi grey)($i.particle)(ansi reset)"
            } else {
                $"Non-text particle. Is not supported yet.(char nl)(ansi grey)($i.particle)(ansi reset)"
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
        ber query rank search $cid $page $results_per_page
        | get result
        | upsert particle {
            |i| cid-read-or-download $i.particle
        }
        | select particle rank
        | upsert source 'search'
    )

    let $back = (
        ber query rank backlinks $cid $page $results_per_page
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
        error make {msg: $'($cid) is not found'}
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

    if (do -i {pueue status -g d} | complete | $in.exit_code != 0) {
        return 'Tasks queue manager is turned off. Launch it with "brew services start pueue" or "pueued -d" command'
    }

    if ( ($files | length) == 0 ) {
        return 'there are no files in queue'
    }

    cprint $'Overall count of files in queue is *($files | length)*'

    cprint $'*($env.cy.ipfs-download-from)* will be used for download'

    let $filtered_files = (
        $files
        | where size <= (1 + $attempts | into filesize)
        | sort-by size
    )

    if ($filtered_files == []) {
        return $'There are no files, that was attempted to download for less than ($attempts) times.'
    } else {
        ($filtered_files | length)
        | print $'There are ($in) files that was attempted to be downloaded ($attempts) times already.'

        ($filtered_files | sort-by modified -r | sort-by size | get modified.0 -i)
        | print $'The latest file was added into the queue ($in)'
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

# Get a current height for the active network in config
#
# > cy query-current-height | to yaml
# height: '9010895'
# time: 2023-07-11T11:37:40.708298734Z
# chain_id: bostrom
export def 'query-current-height' [
    exec?: string@'nu-complete-executables'
] {
    let $exec = ($exec | default $env.cy.exec)
    # print $'current height for ($exec)'
    ^($exec) query block -n $env.cy.rpc-address
    | from json
    | get block.header
    | select height time chain_id
}

# Get a karma metric for a given neuron
#
# > cy karma-get bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | to yaml
# karma: 852564186396
export def 'karma-get' [
    address: string
] {
    ber query rank karma $address
    | upsert karma {|i| $i.karma | into int}
}

# Get a balance for a given account
#
# > cy balance-get bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
# boot: 348358
# hydrogen: 486000000
# milliampere: 25008
# millivolt: 7023
export def 'balance-get' [
    address: string
] {
    if not (is-neuron $address) {
        cprint $"*($address)* doesn't look like an address"
        return null
    }

    # let exec = match ($address | str substring 0..4) {
    #     'pussy' => { 'pussy' },
    #     'bostr' => { 'cyber' }
    # }

    (
        ber query bank balances $address
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
#
# > cy balances --test | to yaml
# name: bot3f
# boot: 654582269
# hydrogen: 50
# address: bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel
export def 'balances' [
    ...name: string@'nu-complete keys values'
    --test      # Use keyring-backend test (with no password)
] {
    let $balances = (
        ^($env.cy.exec) (
            [keys list --output json]   # Params for CLI
            | if $test {
                append [--keyring-backend test]
            } else { }
        )
        | from json
        | select name address
        | if ($name | is-empty) { } else {
            where name in $name
        }
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

    $balances
    | each {|i| $dummy1 | merge $i}
    | sort-by name
    | if (($in | length) > 1) { } else {
        into record
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
#
# > cy ibc-denoms | first 2 | to yaml
# - path: transfer/channel-2
#   base_denom: uosmo
#   denom: ibc/13B2C536BB057AC79D5616B8EA1B9540EC1F2170718CAFF6F0083C966FFFED0B
#   amount: '59014043327'
# - path: transfer/channel-2/transfer/channel-0
#   base_denom: uatom
#   denom: ibc/5F78C42BCC76287AE6B3185C6C1455DFFF8D805B1847F94B9B625384B93885C7
#   amount: '150000'
export def 'ibc-denoms' [] {
    let $bank_total = (
        ber query bank total # here we obtain only the first page of report
    )

    let $denom_trace1 = (
        $bank_total
        | get supply
        | where denom =~ '^ibc'
        | upsert ibc_hash {|i| $i.denom | str replace 'ibc/' ''}
        | par-each {|i| $i
            | upsert temp_out {
                |i| ber query ibc-transfer denom-trace $i.ibc_hash
                | get denom_trace
            }
        }
    )

    $denom_trace1.temp_out | merge $denom_trace1 | reject ibc_hash temp_out | sort-by path --natural
}

# Dump the peers connected to the given node to the comma-separated 'persistent_peers' list
# Nodes list for https://rpc.bostrom.cybernode.ai:443
#
# 70 peers found
# persistent_peers = "7ad32f1677ffb11254e7e9b65a12da27a4f877d6@195.201.105.229:36656,d0518ce9881a4b0c5872e5e9b7c4ea8d760dad3f@85.10.207.173:26656"
export def 'validator-generate-persistent-peers-string' [
    node_address?: string
] {
    let $node_address = ($node_address | default $'($env.cy.rpc-address)')
    if $node_address == $env.cy.rpc-address {
        cprint -a 2 $"Nodes list for *($env.cy.rpc-address)*"
    }

    let $peers = (http get $'($node_address)/net_info' | get result.peers)

    cprint -a 2 $"*($peers | length)* peers found"

    $peers
    | each {|i| $i
    | get node_info.id remote_ip node_info.listen_addr}
    | each {
        |i| $'($i.0)@($i.1):($i.2 | split row ":" | last)'
    }
    | str join ','
    | $'persistent_peers = "($in)"'
}

# A wrapper, to cache CLI requests
export def 'ber' [
    ...rest
    --exec: string = ''
    --cache_validity_duration: duration = 60min # Sets the cache's valid duration. No updates initiated during this period.
    --cache_stale_refresh: duration = 7day      # Sets stale cache's usable duration. Triggers background update and returns cache results. If exceeded, requests immediate data update.
    --force_update
    --quiet
    --no_default_params                         # Don't use default params (like output, chain-id)
] {
    let $executable = if $exec != '' {$exec} else {$env.cy.exec}
    let $jsonl_path = (
        $executable
        | append $rest
        | str join '_'
        | str replace -a '[^A-Za-z0-9_А-Яа-я]' '_'
        | str replace -a '_+' '_'
        | $'($env.cy.path)/cache/jsonl/($in).jsonl'
    )

    def 'request-and-save-exec-response' [] {
        let $cmd = (
            $rest
            | if $no_default_params {} else {
                append [
                    '--output' 'json'
                    '--node' $env.cy.rpc-address
                    '--chain-id' 'bostrom'
                ]
            }
        )

        let $response = (
            do -i {
                ^($executable) $cmd
            }
            | complete
            | if $in.exit_code == 0 {
                get stdout
                | from json
                | insert update_time (date now)
            } else {
                {error: $in, update_time: (date now)}
            }
        )

        $response
        | to json -r
        | $'($in)(char nl)'
        | save -a -r $jsonl_path;

        if not $quiet {$response}
    }

    let $last_data = (
        if ($jsonl_path | path exists) {
            ^tail -n 1 $jsonl_path
            | from json
            | upsert update_time ($in.update_time | into datetime)
        } else {
            {'update_time': (0 | into datetime)}
        }
    )

    let $freshness = ((date now) - $last_data.update_time)

    if ($force_update or ($freshness > $cache_stale_refresh)) {
        request-and-save-exec-response
    } else {
        if ($freshness > $cache_validity_duration) {
            cprint $'Using cache data, updated *($freshness | format duration day) ago*. Update is requested.'
            pu-add -o 2 $'cy ber --exec ($executable) --force_update --quiet ($rest | str join " ")'
        };

        $last_data
    }
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
    mkdir $'($env.cy.path)/cache/jsonl/'

    touch $'($env.cy.path)/graph/update.toml'

    if (
        not ($'($env.cy.path)/cyberlinks_temp.csv' | path exists)
    ) {
        'from,to'
        | save $'($env.cy.path)/cyberlinks_temp.csv'
    }

    if (
        not ($'($env.cy.path)/cyberlinks_archive.csv' | path exists)
    ) {
        'from,to,address,timestamp,txhash'
        | save $'($env.cy.path)/cyberlinks_archive.csv'
    }
}

def 'system_cids' [] {
    [
        'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx',
        'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx',
        'Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs'
    ]
}

# Print string colourfully
export def 'cprint' [
    ...text_args
    --color (-c): any = 'default'
    --highlight_color (-h): any = 'green_bold'
    --frame_color (-r): any = 'dark_gray'
    --frame (-f): string        # A symbol (or a string) to frame text
    --before (-b): int = 0      # A number of new lines before text
    --after (-a): int = 1       # A number of new lines after text
    --echo (-e)                 # Echo text string instead of printing
] {
    def compactit [] {
        $in
        | str replace -a '(\n[\t ]*(\n[\t ]*)+)' '⏎'
        | str replace -a '\n?[\t ]+' ' '    # remove single line breaks used for code formatting
        | str replace -a '⏎' "\n\n"
        | lines
        | each {|i| $i | str trim}
        | str join "\n"
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
        let $line = (
            ' '
            | fill -a r -w $width -c $frame
            | $'(ansi $frame_color)($in)(ansi reset)'
        )

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
        $text_args
        | str join ' '
        | compactit
        | colorit
        | if $frame != null {
            frameit
        } else {}
        | if $echo { } else { newlineit }
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
        ^cp $filename $path2
        # print $'Previous version of ($filename) is backed up to ($path2)'
    } else {
        cprint $'*($filename)* does not exist'
    }
}

export def 'pu-add' [
    command: string
    --priority (-o): int = 1
] {
    do {pueue add -p -o $priority -- $'nu -c "($command)" --config "($nu.config-path)" --env-config "($nu.env-path)"'}
    | null
}

def 'inspect2' [
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
    dict-neurons | get nick
}

def 'nu-complete-neurons-nicknames' [] {
    dict-neurons | get nickname | where $it != ""
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