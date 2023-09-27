# Cy - a tool for interactions wity cybergraphs
# https://github.com/cyber-prophet/cy
#
# Use:
# > overlay use ~/cy/cy.nu -p -r

use std assert equal
use std clip
use nu-utils [bar, cprint, "str repeat", to-safe-filename]

use log

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

    ['ipfs', 'bat', 'mdcat', 'rich', 'curl', 'pueue', 'cyber', 'pussy']
    | par-each {
        |i| if (which ($i) | is-empty) {
            $'($i) is missing'
        }
    }
    | do $intermid $in
}

export-env {
    banner2
    let $tested_versions = ['0.85.0']

    version
    | get version
    | if $in not-in $tested_versions {
        cprint $'This version of Cy was tested on ($tested_versions), and you have ($in).
        We suggest you to use one of the tested versions. If you installed *nushell*
        using brew, you can update it with the command *brew upgrade nushell*'
    }

    let $config = (open_cy_config_toml)

    $env.cy = (
        try {
            $config
            | merge (
                open ($config.path | path join config $'($config.config-name).toml')
            )
            | sort
        } catch {
            cprint $'A config file was not found. Run *cy config-new*'
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
        | if (
            (not $dont_follow_path) and (path-exists-safe $in)
        ) {
            open
        } else {}
    )

    if (not $dont_detect_cid) and (is-cid $text) {
        return $text
    }

    if $only_hash {
        $text
        | ipfs add -Q --only-hash
        | str replace (char nl) ''
        | return $in
    }

    let $cid = (
        if ($env.cy.ipfs-storage == 'kubo') or ($env.cy.ipfs-storage == 'both') {
            $text
            | ipfs add -Q
            | str replace (char nl) ''
        }
    )

    if ($env.cy.ipfs-storage == 'cybernode') or ($env.cy.ipfs-storage == 'both') {
        $text
        | curl --silent -X POST -F file=@- 'https://io.cybernode.ai/add'
        | from json
        | get cid
    } else { $cid }
}

#[test]
def test_pin_text_1 [] {
    # use ~/cy/cy.nu


    equal (pin-text 'cyber') 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
    equal (pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV') 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
    equal (
        pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --dont_detect_cid
    ) 'QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F'
}

#[test]
def test_pin_text_file_paths [] {
    # use ~/cy/cy.nu
    # use std assert equal
    "cyber" | save -f cyber.txt

    equal (pin-text 'cyber.txt' --dont_follow_path) 'QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6'
    equal (pin-text 'cyber.txt') 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'

    rm 'cyber.txt'
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
    # use std assert equal
    let expect = {
        from_text: cyber,
        to_text: bostrom,
        from: "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
        to: "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"
    }

    let result = (
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
            | upsert to (ipfs add $f.from_text -Q | str replace (char nl) '')
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
    # use std assert equal

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
    # use std assert equal

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
    # use std assert equal

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
        http get https://api.chucknorris.io/jokes/random
        | get value
        | $in + "\n\n" + 'via [Chucknorris.io](https://chucknorris.io)'
    )

    cprint -f '=' --indent 4 $quote

    link-texts --quiet 'chuck norris' $quote
}

# Add a random quote cyberlink to the temp table
def 'link-quote' [] {
    let quote = (
        http get -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=text
        | $in + "\n\n" + 'via [forismatic.com](https://forismatic.com)'
    )

    cprint -f '=' --indent 4 $quote

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

# Set the custom name for tmp-links csv table
export def-env 'tmp-links-name-set' [
    name: string
] {
    $env.cy.tmp_links_name = $name
}

# Set the custom name for tmp-links csv table
export def-env 'ber-force-update-set' [
    value: bool
] {
    $env.cy.ber_force_update = $value
}

def 'tmp-links-name' [] {
    $env.cy.tmp_links_name? | default 'temp'
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
#   timestamp: 20230701-134134
# - from_text: quote
#   to_text: |-
#     He who knows himself is enlightened. (Lao Tzu )
#
#     via [forismatic.com](https://forismatic.com)
#   from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
#   to: QmWoxYsWYuTP4E2xaQHr3gUZZTBC7HdNDVhis1BK9X3qjX
#   timestamp: 20230702-113842
export def 'tmp-view' [
    --quiet (-q) # Don't print info
    --no_timestamp
] {
    let $filename = ($env.cy.path | path join $'cyberlinks_(tmp-links-name).csv')
    let $tmp_links = (
        $filename
        | try {
            open
            | if $no_timestamp { reject timestamp } else {}
        } catch {
            [[from]; [null]] | first 0
        }
    )

    if (not $quiet) {
        let $links_count = ($tmp_links | length)

        if $links_count == 0 {
            cprint $'The temp cyberlinks table *($filename)* is empty.
            You can add cyberlinks to it manually or by using commands like *"cy link-texts"*'
        } else {
            cprint $'There are *($links_count) cyberlinks* in the temp table:'
        }
    }

    $tmp_links
}

# Append piped-in table to the temp cyberlinks table
export def 'tmp-append' [
    cyberlinks?: table          # cyberlinks table
    --quiet (-q)
] {
    $in
    | default $cyberlinks
    | upsert timestamp (now-fn)
    | prepend (tmp-view -q)
    | if $quiet { tmp-replace -q } else { tmp-replace }
}

# Replace the temp table with piped-in table
export def 'tmp-replace' [
    cyberlinks?: table          # cyberlinks table
    --quiet (-q)
] {
    $in
    | default $cyberlinks
    | save ($env.cy.path | path join $'cyberlinks_(tmp-links-name).csv') --force

    if (not $quiet) { tmp-view -q }
}

# Empty the temp cyberlinks table
export def 'tmp-clear' [] {
    let $filename = ($env.cy.path | path join $'cyberlinks_(tmp-links-name).csv')
    backup-fn $filename

    $'from_text,to_text,from,to,timestamp(char nl)'
    | save $filename --force
    # print 'TMP-table is clear now.'
}

#[test]
def test-tmps [] {
    # use std assert equal
    let $temp_name = (random chars)
    tmp-links-name-set ($temp_name)
    link-texts 'cyber' 'bostrom'

    [[from_text, to_text]; ['cyber-prophet' '🤘'] ['tweet' 'cy is cool!']]
    | tmp-append

    tmp-pin-columns;
    equal (
        tmp-view --no_timestamp
    ) [
        [from_text, to_text, from, to];
        [cyber, bostrom, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        [cyber-prophet, 🤘, "QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD", "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        [tweet, "cy is cool!", "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx", "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    tmp-link-all 'cy testing script'
    equal (
        tmp-view --no_timestamp
    ) [
        [from_text, to_text, from, to];
        ["cy testing script", bostrom, "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        ["cy testing script", 🤘, "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx", "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        ["cy testing script", "cy is cool!", "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx", "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    config-activate cy-testing1+cyber

    link-random -n 3
    link-random forismatic.com -n 3
    tmp-remove-existed

    equal (tmp-send-tx | get code) 0
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
    --column (-c): string = 'from'  # a column to use for values ('from' or 'to'). 'from' is default
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
    let $c = (
        $in
        | default ( tmp-view -q )
        | fill non-exist -v null
    )

    let dict = (
        $c
        | reduce -f [] {|it acc|
            $acc
            | if $it.from_text? not-in [null ''] { append $it.from_text } else {}
            | if $it.to_text? not-in [null ''] { append $it.to_text } else {}
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

    $c
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
        | par-each {
            |i| $i
            | upsert link_exist {
                |row| (link-exist  $row.from $row.to $env.cy.address)
            }
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
    let $c = (
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
    | upsert body.messages.links $c
    | save ($env.cy.path | path join temp tx-unsigned.json) --force
}

def 'tx-sign-and-broadcast' [] {

    let $params = (
        [
        --from $env.cy.address
        --chain-id $env.cy.chain-id
        --node $env.cy.rpc-address
        --output-document ($env.cy.path | path join temp tx-signed.json)
        ]
        | if $env.cy.keyring-backend? == 'test' {
            append ['--keyring-backend' 'test']
        } else {}
    )

    (
        ^($env.cy.exec) tx sign ($env.cy.path | path join temp tx-unsigned.json) $params
        | complete
        | if ($in.exit_code != 0) {
            error make {msg: 'Error signing the transaction!'}
        }
    )

    (
        ^($env.cy.exec) tx broadcast ($env.cy.path | path join temp tx-signed.json)
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

    let $c = ($in_cyberlinks | default (tmp-view -q))

    let $c_count = ($c | length)

    $c | tx-json-create-from-cybelinks

    let $_var = (
        tx-sign-and-broadcast
        | from json
        | select raw_log code txhash
    )

    let $filename = ($env.cy.path | path join cyberlinks_archive.csv)
    if $_var.code == 0 {
        open $filename
        | append (
            $c
            | upsert neuron $env.cy.address
        )
        | save $filename --force

        if ($in_cyberlinks == null) {
            tmp-clear
        }

        {'cy': $'($c_count) cyberlinks should be successfully sent'}
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
    $in | to tsv | clip --no-notify --silent --no-strip
}

# Paste a table from the clipboard to stdin (so it can be piped further)
export def 'tsv-paste' [] {
    pbpaste | from tsv
}

# Update Cy to the latest version
export def 'update-cy' [
    --branch: string@'nu-complete-git-branches' = 'dev'
] {
    cd $env.cy.path;
    git checkout $branch
    git pull --autostash -v
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
    --quiet
] {
    let $json = (
        if (is-neuron $address_or_nick) {
            $'{"active_passport":{"address":"($address_or_nick)"}}'
        } else {
            $'{"passport_by_nickname":{"nickname":"($address_or_nick)"}}'
        }
    )

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    let $params = ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']
    let $out = ber --exec 'cyber' --no_default_params query wasm contract-state smart $pcontract $json $params


    if $out.error? == null {
        $out
        | get data
        | merge $in.extension
        | reject extension approvals token_uri
    } else {
        if not $quiet {
            cprint --before 1 --after 2 $'No passport for *($address_or_nick)* is found'
        }
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
    open ($env.cy.path | path join graph neurons_dict.yaml)
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
    --all_neurons           # Update info about all neurons
    --threads (-t) = 30     # Number of threads to use for downloading
    --dont_save             # Don't update the file on a disk, just output the results
    --quiet (-q)            # Don't output results table
] {
    if $all_neurons {
        dict-neurons
    } else {
        graph-links-df
        | dfr select neuron
        | dfr unique
        | dfr join --left (dict-neurons --df) neuron neuron
        | dfr into-nu
        | reject index
    }
    | filter {|i| is-neuron $i.neuron}
    | if $passport or $all {
        par-each -t $threads {|i|
            $i | merge (passport-get $i.neuron --quiet)
            | upsert nick {
                |b| $b.nickname?
                | default ''
                | $in + $'_($b.neuron)'
            }
        }
    } else {}
    | if $balance or $all {
        par-each -t $threads {|i|
            $i | merge (
                tokens-balance-get $i.neuron
                | transpose -idr
            )
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
            let $yaml = ($env.cy.path | path join graph neurons_dict.yaml)
            backup-fn $yaml;

            dict-neurons
            | prepend $i
            | uniq-by neuron
            | save -f $yaml;

            $i
        } $in
    }
    | if $quiet { null } else { }
}

# Download a snapshot of cybergraph by graphkeeper
export def-env 'graph-download-snapshot' [
    --disable_update_parquet (-D)   # Don't update the particles parquet file
] {
    make_default_folders_fn

    let $path = ($env.cy.path | path join graph)
    let $cur_data_cid = (passport-get graphkeeper | get data -i)
    let $update_info = (
        ($path | path join update.toml)
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

    let $archives = (ls ($path | path join particles_arch/*.zip) | get name)
    let $last_archive = (
        $update_info
        | get -i last_archive
        | default ($archives | first)
    )

    (
        $archives
        | skip until {|x| $x == $last_archive}
        | each {
            |i| unzip -ojq $i -d ($path | path join particles safe);
            cprint $'*($i)* is unzipped'
        }
    )

    (
        try {open ($path | path join update.toml)} catch {{}}
        | upsert 'last_cid' $cur_data_cid
        | upsert 'last_archive' ($archives | last)
        | save -f ($path | path join update.toml)
    )

    cprint $'The graph data has been downloaded to the *"($path)"* directory'

    if (not $disable_update_parquet) {
        print 'Updating particles parquet'
        graph-update-particles-parquet --full_content
    }
}

# Download the latest cyberlinks from a hasura cybernode endpoint
export def 'graph-download-links' [] {
    def get_links_query [
        height
        multiplier
    ] {
        let $chunk_size = 1000

        $"{cyberlinks\(limit: ($chunk_size), offset: ($multiplier * $chunk_size), order_by: {height: asc},
        where: {height: {_gte: ($height)}}) {neuron particle_from particle_to height timestamp}}"
        | {'query': $in}
    }

    let $graphql_api = "https://titan.cybernode.ai/graphql/v1/graphql"
    let $path_csv = $'($env.cy.path)/graph/cyberlinks.csv'

    let $last_height = (
        if ($path_csv | path exists) {
            'a,b,c,height,t'
            | append (tail -n 1 ($path_csv))
            | str join (char nl)
            | from csv
            | get height.0
            | into int
            | $in + 1
        } else {
            $'neuron,particle_from,particle_to,height,timestamp(char nl)' # csv headers
            | save -r $path_csv;
            0
        }
    )

    for $mult in 0.. {
        let $links = (
            http post -t application/json $graphql_api (get_links_query $last_height $mult)
            | get data.cyberlinks
        );
        if $links != [] {
            $links | to csv --noheaders | save -r -a $path_csv
            print $'($links | length) was downloaded!'
        } else {
            break
        }
    }
}

# filter system particles out
def 'gp-filter-system' [
    column = 'particle'
] {
    dfr filter-with ( (dfr col $column) | dfr is-in (system_cids) | dfr expr-not )
}

# Output unique list of particles from piped in cyberlinks table
#
# > cy graph-to-particles --include_global | dfr into-nu | first 2 | to yaml
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
    --include_global        # Include column with global particles' df (that includes content)
    --include_particle_index         # Include local 'particle_index' column
    --is_first_neuron       # Check if 'neuron' and 'neuron_global' columns are equal
    --only_first_neuron (-o)
    --cids_only (-c)        # Output one column with CIDs only
    # --init_role             # Output if particle originally was in 'from' or 'to' column
] {
    let $c = ( graph-links-df | dfr into-lazy )

    let $c_columns = ($c | dfr columns)
    if ($to and $from) {
        error make {msg: 'you need to use only 'to', 'from' or none flags at all, none both of them'}
    }

    def graph-to-particles-keep-column [
        c
        --column: string
    ] {
        $c
        | dfr rename $'particle_($column)' particle
        | dfr drop $'particle_(col-name-reverse $column)'
        | dfr with-column [
            (dfr lit ($column) | dfr as 'init-role'),
        ]
    }

    let $dummy = (
        $c
        | dfr rename particle_from particle
        | dfr drop particle_to
        | dfr with-column (dfr lit 'a' | dfr as 'init-role')
        | dfr fetch 0  # Create dummy dfr to have something to appended to
    )

    (
        $dummy
        | if not $to {
            dfr append --col (
                graph-to-particles-keep-column $c --column from
            )
        } else {}
        | if not $from {
            dfr append --col (
                graph-to-particles-keep-column $c --column to
            )
        } else {}
        | dfr into-lazy
        | if ('link_local_index' in $c_columns) {
            dfr sort-by [link_local_index height]
        } else {
            dfr sort-by [height]
        }
        | dfr unique --subset [particle]
        | if not $include_system {
            gp-filter-system
        } else {}
        | if $cids_only {
            dfr select particle
        } else {
            if $include_particle_index {
                dfr with-column (
                    dfr arg-where ((dfr col height) != 0) | dfr as particle_index
                )
            } else {}
            | if $include_global {
                dfr join (graph-particles-df) particle particle -s '_global'
            } else {}
        }
        | dfr collect
    )
}

export def particles-only-first-neuron [
] {
    dfr join -s '_global' (
        graph-particles-df
        | dfr select particle neuron
    ) particle particle
    | dfr with-column (($in.neuron) == ($in.neuron_global)) --name 'is_first_neuron'
    | dfr filter-with $in.is_first_neuron
    | dfr drop neuron_global is_first_neuron
}

# Update the 'particles.parquet' file (it inculdes content of text files)
export def 'graph-update-particles-parquet' [
    --full_content  # include column with full content of particles
    --quiet (-q)    # don't print info about the saved parquet file
] {

    let $downloaded_particles = (
        ls -s ($env.cy.path | path join graph particles safe) # I use ls instead of glob to have the filesize column
        | reject modified type
        | upsert content {
            |i| open -r ($env.cy.path | path join graph particles safe $i.name)
            | str substring -g 0..4000
        }
        | dfr into-df
        | dfr with-column (
            $in.name
            | dfr str-slice 0 -l 46
        )
        | dfr rename name particle
        | dfr with-column (
            $in.content
            | dfr str-slice 0 -l 150
            | dfr replace-all -p (char nl) -r '⏎'
            | dfr rename content content_s
        )
        | if $full_content {} else {
            dfr drop content
        }
    )

    backup-fn ($env.cy.path | path join graph particles.parquet)

    (
        graph-to-particles --include_system
        | dfr join --left $downloaded_particles particle particle
        | dfr with-column (
            $in.content_s
            | dfr fill-null timeout
        )
        | dfr with-column ( # short name to make content_s unique
            $in.particle
            | dfr str-slice 39 # last 7 symbols of 46-symbol cid
            | dfr rename particle short_cid
        )
        | dfr with-column (
            dfr concat-str '|' [(dfr col content_s) (dfr col short_cid)]
        )
        | dfr drop short_cid
        | dfr to-parquet ($env.cy.path | path join graph particles.parquet)
        | print ($in | get 0 -i)
    )
}

# Filter the graph to chosen neurons only
export def 'graph-filter-neurons' [
    ...neurons_nicks: string@'nu-complete-neurons-nicks'
] {
    $neurons_nicks
    | dfr into-df
    | dfr join ( dict-neurons --df ) '0' nick
    | dfr select neuron
    | dfr join ( graph-links-df ) neuron neuron
}

# Append related cyberlinks to the piped in graph
export def 'graph-append-related' [
    --only_first_neuron (-o)
] {
    let $links_in = $in
    let $columns_in = ($links_in | dfr columns)
    let $step = (
        if 'step' in $columns_in {
            $links_in.step | dfr max | dfr into-nu | get 0.step | ($in // 2) + 1 | ($in * 2) - 1
        } else {
            1
        }
    )

    let $c = (
        $links_in
        | dfr into-lazy
        | if 'link_local_index' in $columns_in {} else {
            dfr with-column [
                (dfr arg-where ((dfr col height) != 0) | $in + 100_000_000 | dfr as link_local_index),
            ]
            | dfr with-column (dfr concat-str '' [(dfr col link_local_index) (dfr lit '')])
        }
        | if 'init-role' in $columns_in {} else {
            dfr with-column (dfr lit 'base' | dfr as 'init-role')
        }
        | if 'step' in $columns_in {} else {
            dfr with-column (dfr lit 0 | dfr as 'step')
        }
    )

    def append_related [
        from_or_to: string
        --step: int
    ] {
        $c
        | graph-to-particles --include_system
        | if $only_first_neuron {
            particles-only-first-neuron
        } else {}
        | dfr into-lazy
        | dfr select particle link_local_index init-role step
        | dfr rename particle $'particle_($from_or_to)'
        | dfr join (
            graph-links-df --not_in --exclude_system
            | dfr into-lazy
        ) $'particle_($from_or_to)' $'particle_($from_or_to)'
        | dfr with-column [
            (dfr concat-str '-' [
                (dfr col 'link_local_index')
                (dfr col 'init-role')
                (dfr col $'particle_($from_or_to)')
                (dfr lit ($from_or_to))
                (dfr col $'particle_(col-name-reverse $from_or_to)')
            ]),
            ((dfr col step) + (if $from_or_to == from {1} else {-1}))
        ]
    }

    $c
    | dfr append -c (append_related from --step ($step))
    | dfr append -c (append_related to --step ($step + 1))
    | dfr into-lazy
    | dfr sort-by [link_local_index height]
    | dfr unique --subset [particle_from particle_to]
    | dfr collect
}

# Output neurons stats based on piped in or the whole graph
export def 'graph-neurons-stats' [] {
    let c = (graph-links-df)
    let p = (graph-particles-df)

    let follows = (
        [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | dfr into-df
        | dfr join --left $c particle particle_from
        | dfr group-by neuron
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'follows')
        ]
        | dfr sort-by follows --reverse [true]
    )

    let $followers = (
        [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | dfr into-df
        | dfr join --left $c particle particle_from
        | dfr join $p particle_to particle
        | dfr with-column (
            $in | dfr select content_s | dfr replace -p '\|.*' -r ''
        )
        | dfr group-by content_s
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'followers')
        ]
        | dfr rename content_s neuron
    )

    let $tweets = (
        [['particle'];['QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx']] # tweet
        | dfr into-df
        | dfr join --left $c particle particle_from
        | dfr group-by neuron
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'tweets')
        ]
    )

    (
        $c
        | dfr group-by neuron
        | dfr agg [
            (dfr col timestamp | dfr count  | dfr as 'links_count')
            (dfr col timestamp | dfr min | dfr as 'first_link')
            (dfr col timestamp | dfr max | dfr as 'last_link')
        ]
        | dfr sort-by links_count --reverse [true]  # cygraph neurons activity
        | dfr join --left $followers neuron neuron
        | dfr join --left $follows neuron neuron
        | dfr join --left $tweets neuron neuron
        | dfr join --left ( dict-neurons --df ) neuron neuron
    )
}

# Export a graph into CSV file for import to Gephi
export def 'graph-to-gephi' [] {
    let $c = (graph-links-df)
    let $particles = (
        $c
        | graph-to-particles --include_system --include_global
    )

    let $t1_height_index = (
        $c.height
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
        $c
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
        | dfr to-csv ($env.cy.path | path join export !gephi_cyberlinks.csv)
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
        | save  -f ($env.cy.path | path join export !gephi_particles.csv)
    )
}

# Logseq export WIP
export def 'graph-to-logseq' [
    # --path: string
] {
    let $c = (graph-links-df | inspect2)
    let $particles = (
        $c
        | graph-to-particles --include_system --include_global
        | inspect2
    )

    let $path = ($env.cy.path) | path join export $'logseq_(date now | date format "%Y-%m-%d_%H-%M-%S")'
    mkdir ($path | path join pages)
    mkdir ($path | path join journals)

    $particles
    | dfr into-nu
    | par-each {|p|
        # print $p.particle
        $"author:: [[($p.nick)]]\n\n- (
            do -i {open ($env.cy.ipfs-files-folder | path join $'($p.particle).md')
            | default "timeout"
        } )\n- --- \n- ## cyberlinks from \n" |
        save ($path | path join pages $'($p.particle).md')
    }

    $c
    | dfr into-nu
    | each {|c|
        $"\t- [[($c.particle_to)]] ($c.height) [[($c.nick?)]]\n" |
        save -a ($path | path join pages $'($c.particle_from).md')
    }
}

# Output particles into txt formated feed
export def 'graph-to-txt-feed' [] {
    $in
    | graph-append-related --only_first_neuron
    | graph-to-particles
    | particles-only-first-neuron
    | graph-add-metadata --full_content
    # | dfr filter-with ($in.content_s | dfr is-null | dfr not)
    | dfr sort-by [link_local_index height]
    | dfr drop content_s neuron
    | dfr into-nu
    | reject index
    | do {|i| print ($i | get 0.init-role); $i} $in
    | each {|i| echo_particle_txt $i}
    | str join (char nl)
}

# Export graph in cosmograph format
export def 'graph-to-cosmograph' [] {
    $in
    | graph-add-metadata
    | dfr into-nu
    | reject index
    | save -f (
        $env.cy.path
        | path join 'export' $'cosmograph(now-fn).csv'
        | inspect2
    )
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
export def 'graph-add-metadata' [
    --full_content
    --include_text_only
] {
    let $c = (graph-links-df)
    let $p = (
        graph-particles-df
        | if $full_content {
            dfr select particle content_s content
        } else {
            dfr select particle content_s
        }
        | if $include_text_only {
            dfr filter-with (($in | dfr select content_s) =~ '"MIME|^timeout' | dfr not)
        } else { }
    )

    let $c_columns = ($c | dfr columns)

    let $c_out = (
        $c
        | if 'particle_to' in $c_columns {
            dfr join --left $p particle_to particle
            | dfr rename content_s content_s_to
        } else {}
        | if 'particle_from' in $c_columns {
            dfr join --left $p particle_from particle
            | dfr rename content_s content_s_from
        } else {}
        | if 'particle' in $c_columns {
            dfr join --left $p particle particle
        } else {}
        | if 'neuron' in $c_columns {
            dfr join --left (
                dict-neurons --df
                | dfr select neuron nick
            ) neuron neuron
        }
    )

    let $columns_order_target = ($c_out | dfr columns | reverse)

    $c_out
    | dfr select $columns_order_target
}

# Output a full graph, or pass piped in graph further
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
    $in
    | if ($not_in or ($in | describe | $in == 'nothing')) {
        graph-open-csv-make-df ($env.cy.path | path join graph cyberlinks.csv)
    } else {}
    | if $include_contracts {
        dfr append -c (
            graph-open-csv-make-df ($env.cy.path | path join graph cyberlinks_contracts.csv)
        )
    } else {}
    | if $exclude_system {
        dfr into-lazy
        | gp-filter-system particle_from
    } else { }
}

def 'graph-open-csv-make-df' [
    path: path
    --datetime
] {
    dfr open $path
    | if $datetime {
        dfr with-column (
            $in.timestamp
            | dfr as-datetime '%Y-%m-%dT%H:%M:%S' -n
            | dfr rename datetime timestamp
        )
    } else {}
}

export def 'graph-particles-df' [] {
    let $p = (dfr open ($env.cy.path | path join graph particles.parquet))
    $p
}

# Create a config JSON to set env variables, to use them as parameters in cyber cli
export def-env 'config-new' [
    # config_name?: string@'nu-complete-config-names'
] {
    print (check-requirements)
    make_default_folders_fn

    cprint -c green 'Choose the name of executable:'
    let $exec = (nu-complete-executables | input list -f | inspect2)

    let $addr_table = (
        ^($exec) keys list --output json
        | from json
        | flatten
        | select name address
        | upsert keyring main
        | append (
            ^($exec) keys list --output json --keyring-backend test
            | from json
            | flatten
            | select name address
            | upsert keyring test
        )
    )

    if ($addr_table | length) == 0 {
        let $error_text = (
            cprint --echo $'There are no addresses in the keyring of *($exec)*. To use Cy, you need to add one.
            You can find out how to add the key by running the command "*($exec) keys add -h*".
            After adding the key, come back and launch this wizard again.'
        )

        error make -u {msg: $error_text}
    }

    cprint -c green --before 1 'Select the address to send transactions from:'

    let $address = (
        $addr_table
        | input list -f
        | get address
        | inspect2
    )

    let $keyring = $addr_table | where address == $address | get keyring.0

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
        'keyring-backend': $keyring
        'passport-nick': $passport_nick
        'chain-id': $chain_id
        'ipfs-storage': $ipfs_storage
        'rpc-address': $rpc_address
    } | config-save $config_name
}

# View a saved JSON config file
export def 'config-view' [
    config_name?: string@'nu-complete-config-names'
    # --quiet (-q)
] {
    if $config_name == null {
        $env.cy
    } else {
        let $filename = ($env.cy.path | path join config $'($config_name).toml')
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
    let $filename = ($env.cy.path | path join config $'($config_name).toml')

    let $filename2 = (
        if not ($filename | path exists) {
            $filename
        } else {
            cprint -c green --before 1 $'($filename) exists. Do you want to overwrite it?'

            ['yes' 'no'] | input list
            | if $in == 'yes' {
                backup-fn $filename;
                $filename
            } else {
                ($env.cy.path | path join config $'(now-fn).toml')
            }
        }
    )


    $in_config
    | upsert config-name ($filename2 | path parse | get stem)
    | if (not $inactive) {
        config-activate
    } else {}
    | inspect2
    | save $filename2 -f

    print $'($filename2) is saved'
}

# Activate the config JSON
export def-env 'config-activate' [
    config_name?: string@'nu-complete-config-names'
] {
    let $config = ($in | default (config-view $config_name))
    let $config_path = ('~' | path expand | path join .cy_config.toml)
    let $config_toml = (
        open $config_path
        | merge $config
    )

    $env.cy = $config_toml

    cprint -c green_underline -b 1 'Config is loaded'
    (
        open $config_path
        | upsert 'config-name' ($config_toml | get 'config-name')
        | save $config_path -f
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
    query: string
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let $cid = (
        if (is-cid $query) {
            print $'searching (cid-read-or-download $query)'
            $query
        } else {
            (pin-text $query --only_hash)
        }
    )

    def search_or_back_request [
        type: string
    ] {
        ber query rank $type $cid $page $results_per_page
        | get -i result
        | if $in == null {
            null
        } else {
            select particle rank
            | par-each {
                |$r| $r
                | upsert particle (cid-read-or-download $r.particle)
            }
            | upsert source $type
            | sort-by rank -r -n
        }
    }

    print $'searching ($env.cy.exec) for ($cid)'

    (
        search_or_back_request search
        | append (search_or_back_request backlinks)
    )
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

    $results | save ($env.cy.path | path join cache search '($cid)-(date now|into int).json')

    clear; print $'Searching ($env.cy.exec) for ($cid)';

    serp1 $results

    watch ($env.cy.path | path join cache queue) {|| clear; print $'Searching ($env.cy.exec) for ($cid)'; serp1 $results}
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
    let $file = ($file | default ($env.cy.path | path join cache MIME_types.csv))
    $'($cid),($source),"($type)",($size),($status),(history session)(char nl)' | save -a $file
}

# Read a CID from the cache, and if the CID is absent - add it into the queue
export def 'cid-read-or-download' [
    cid: string
    --full  # output full text of a particle
] {
    do -i {open ($env.cy.ipfs-files-folder | path join $'($cid).md')}
    | default (
        pu-add $'cy cid-download ($cid)';
        'downloading'
    ) | if $full {} else {
        str substring 0..400
        | str replace (char nl) '↩' --all
        | $'($in)(char nl)(ansi grey)($cid)(ansi reset)'
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
    let $content = (do -i {open ($env.cy.ipfs-files-folder | path join $'($cid).md')})
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
        rm --force ($env.cy.path | path join cache queue $cid)
        'downloaded'
    } else if $status == 'not found' {
        cid-queue-add $cid '-'
        'not found'
        # error make {msg: $'($cid) is not found'}
    }
}

# Download a cid from kubo (go-ipfs cli) immediately
def 'cid-download-kubo' [
    cid: string
    --timeout = '300s'
    --folder: string
    --info_only = false # Don't download the file but write a card with filetype and size
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
            | str replace (char nl) ''
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
            | save -f ($folder | path join $'($cid).md')
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
        http get $'($gate_url)($cid)' -m 120 | save -f ($folder | path join $'($cid).md')
        return 'text'
        # log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '4.downloaded file'
    } else if ($type != null) {
        {'MIME type': $type, 'Size': $size} | sort -r | to toml | save -f ($folder | path join $'($cid).md')
        return 'non_text'
        # log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '4.downloaded info'
    } else {
        return 'not found'
    }
}

# Add a CID to the download queue
export def 'cid-queue-add' [
    cid: string
    symbol: string = '+'
] {
    let $path = ($env.cy.path | path join cache queue $cid)

    if not ($path | path exists) {
        touch $path
    } else {
        if $symbol != '+' {
            $symbol | save -a $path
        }
    }
}

# Watch the queue folder, and if there are updates, request files to download
export def 'watch-search-folder' [] {
    watch ($env.cy.path | path join cache search) {|| queue-check }
}

# Check the queue for the new CIDs, and if there are any, safely download the text ones
export def 'queue-check' [
    attempts = 0
    --info
    --quiet
    --threads: int = 15     # A number of threads to use for downloading
] {
    let $files = (ls -s ($env.cy.path | path join cache queue))

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

    let $filtered_count = ($filtered_files | length)

    if ($filtered_files == []) {
        return $'There are no files, that was attempted to download for less than ($attempts) times.'
    } else {
        print $'There are ($filtered_count) files that was attempted to be downloaded ($attempts) times already.'

        ($filtered_files | sort-by modified -r | sort-by size | get modified.0 -i)
        | print $'The latest file was added into the queue ($in)'
    }


    if not $info {
        $filtered_files
        | get name -i
        | enumerate
        | par-each -t $threads {
            |i| cid-download $i.item
            | if $nu.is-interactive {
                print -n $"( ansi -e '1000D' )( bar --width 60 --background yellow ($i.index / $filtered_count)) ($i.index):($in)"
            } else {}
        }
    }
}

# Clear the cache folder
export def 'cache-clear' [] {
    backup-fn ($env.cy.path | path join cache)
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
    | upsert karma {|i| $i.karma? | default 0 | into int}
}

# Get a balance for a given account
#
# > cy tokens-balance-get bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
# - denom: boot
#   amount: 348358
# - denom: hydrogen
#   amount: 486000000
# - denom: milliampere
#   amount: 25008
# - denom: millivolt
#   amount: 7023
export def 'tokens-balance-get' [
    address: string
    --height: int = 0
    --record
] {
    if not (is-neuron $address) {
        cprint $"*($address)* doesn't look like an address"
        return null
    }

    ber query bank balances $address [--height $height]
    | get balances -i
    | if $in == null {
        return
    } else if ($in == []) {
        token-dummy-balance
    } else {
        upsert amount {
            |b| $b.amount
            | into int
        }
    }
    | if $record {
        transpose -idr
    } else {}
}

def 'token-dummy-balance' [] {
    [{denom: boot, amount: 0}]
}

export def 'tokens-supply-get' [
    --height: int = 0
] {
    ber query bank total [--height $height]
    | get supply
    | upsert amount {|i| $i.amount | into int}
    | transpose -idr
}

export def 'tokens-pools-table-get' [
    --height: int = 0
    --short     # get only basic information
] {
    let $liquidity_pools = (ber query liquidity pools [--height $height])

    if $short {
        return $liquidity_pools
    }

    let $supply = (tokens-supply-get)

    $liquidity_pools
    | get pools
    | par-each {
        |b| $b
        | upsert balances {|i|
            tokens-balance-get --record $i.reserve_account_address
        }
    }
    | where balances != (token-dummy-balance | transpose -idr)
    | upsert balances {
        |i| $i.balances | select $i.reserve_coin_denoms # keep only pool's tokens
    }
    | reject reserve_coin_denoms
    | upsert pool_coin_amount_total {
        |i| $supply | get $i.pool_coin_denom
    }
    | upsert balances {
        |i| $i.balances
        | transpose
        | rename reserve_coin_denom reserve_coin_amount
    }
    | flatten | flatten
}

export def 'tokens-pools-convert-value' [
    --height: int = 0
] {
    let $in_table = $in

    (
        $in_table | where denom =~ '^pool'
    )
    | join -l (
        tokens-pools-table-get --height $height
        | select pool_coin_denom reserve_coin_denom reserve_coin_amount pool_coin_amount_total
    ) denom pool_coin_denom
    | upsert percentage {|i| $i.amount / $i.pool_coin_amount_total}
    | upsert amount {|i| $i.reserve_coin_amount * $i.percentage | math round}
    | upsert denom {|i| $i.reserve_coin_denom}
    | reject percentage pool_coin_denom reserve_coin_denom pool_coin_amount_total reserve_coin_amount
    | upsert state 'pool'
    | append (
        $in_table | where denom !~ '^pool'
    )
    | where amount > 0
}

export def 'tokens-delegations-table-get' [
    address: string
    --height: int = 0
    --sum
] {
    ber query staking delegations $address [--height $height]
    | get -i delegation_responses
    | if $in == null {return} else {}
    | each {|i| $i.delegation | merge $i.balance}
    | upsert amount {|i| $i.amount | into int}
    | upsert state delegated
    | if $sum {
        tokens-sum
    } else {}
}

export def 'tokens-rewards-get' [
    address: string
    --height: int = 0
    --sum
] {
    ber query distribution rewards $address [--height $height]
    | get total -i
    | if $in == null {return} else {}
    | upsert amount {|i| $i.amount | into int}
    | if $sum {
        tokens-sum
    } else {}
    | upsert state rewards
}

export def 'tokens-investmint-status-table' [
    address: string
    --h_liquid      # retrun amount of liquid H
    --quiet         # don't output amount of H liquid
    --height: int = 0
    --sum
] {
    let $account_vesting = (ber query account $address [--height $height])

    if $account_vesting == null {
        return
    }

    let $release_slots = (
        $account_vesting.vesting_periods.length
        | reduce -f [($account_vesting.start_time | into int)] {
            |i acc| $acc | append (($i | into int) + ($acc | last))
        }
        | skip
        | each {|i| 10 ** 9 * $i | into datetime}
        | wrap release_time
    )

    let $investmint_status = (
        $account_vesting.vesting_periods
        | reject length
        | merge $release_slots
        | where release_time > (date now)
        | flatten --all
        | upsert amount {|i| $i.amount | into int}
        | upsert state frozen
    );

    let $h_all = (
        tokens-balance-get $address --height $height
        | where denom == hydrogen
        | get amount.0
        | into int
    )

    let $hydrogen_liquid = (
        $investmint_status
        | where denom == 'hydrogen'
        | get amount
        | append 0
        | math sum
        | $h_all - $in
    )

    if ((not $quiet) or (not $h_liquid)) {
        print $'liquid hydrogen availible for investminting: ($hydrogen_liquid)'
    }

    if $h_liquid {
        $hydrogen_liquid
    } else {
        $investmint_status
        | if $sum {
            tokens-sum --state investminting
        } else {}
    }
}

export def 'tokens-routed-from' [
    address: string
    --height: int = 0
] {
    ber query grid routed-from $address [--height $height]
    | get -i value
    | if $in == null {return} else { }
    | upsert amount {|i| $i.amount | into int}
    | upsert state routed-from
}

#[test]
def test-tokens-routed-from [] {
    equal (tokens-routed-from bostrom1vu39vtn2ld3aapued6nwlhm7wpg2gj9zzlncek) null
    equal (tokens-routed-from bostrom1vu39vtn2ld3aapued6nwlhm7wpg2gj9zzlncej) []
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8) [
        [denom, amount, state]; [milliampere, 2000, routed-from], [millivolt, 103000, routed-from]
    ]
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 --height 10124681) [
        [denom, amount, state]; [milliampere, 2000, routed-from], [millivolt, 103000, routed-from]
    ]
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 --height 2000) []
}

# Check IBC denoms
#
# > cy tokens-ibc-denoms-table | first 2 | to yaml
# - path: transfer/channel-2
#   base_denom: uosmo
#   denom: ibc/13B2C536BB057AC79D5616B8EA1B9540EC1F2170718CAFF6F0083C966FFFED0B
#   amount: '59014043327'
# - path: transfer/channel-2/transfer/channel-0
#   base_denom: uatom
#   denom: ibc/5F78C42BCC76287AE6B3185C6C1455DFFF8D805B1847F94B9B625384B93885C7
#   amount: '150000'
export def 'tokens-ibc-denoms-table' [] {
    tokens-supply-get
    | transpose
    | rename denom amount
    | where denom =~ '^ibc'
    | upsert ibc_hash {|i| $i.denom | str replace 'ibc/' ''}
    | each {|i| $i
        | upsert temp_out {
            |i| ber --disable_update query ibc-transfer denom-trace $i.ibc_hash
            | get denom_trace
        }
    }
    | flatten
    | reject ibc_hash
    | sort-by path --natural
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
        ^($env.cy.exec) keys list --output json --keyring-backend test | from json
        | if not $test {
            append ( ^($env.cy.exec) keys list --output json | from json )
        } else {}
        | select name address
        | if ($name | is-empty) { } else {
            where name in $name
        }
        | par-each {
            |i| tokens-balance-get --record $i.address
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

export def 'tokens-balance-all' [
    $address
    --height: int = 0
] {
    let $invstiminted_frozen = (tokens-investmint-status-table $address --sum)
    (
        tokens-balance-get $address --height $height
        | if $in == (token-dummy-balance) {
            return
        } else {}
        | tokens-minus $invstiminted_frozen --state 'liquid'
        | append $invstiminted_frozen
        | append (tokens-rewards-get --sum $address)
        | append (tokens-delegations-table-get --sum $address)
        | append (tokens-routed-from $address)
        | tokens-pools-convert-value
        | sort-by amount -r
        | sort-by denom
    )
}

export def 'tokens-sum' [
    --state: string = '-'
] {
    $in
    | sort-by amount -r
    | group-by denom
    | values
    | each {
        |i| {}
        | upsert denom $i.denom.0
        | upsert amount ($i.amount | math sum)
        | upsert state (
            if $state == '-' {
                $i.state? | default null | uniq | str join '+'
            } else {
                $state
            }
        )
    }
}

def 'tokens-minus' [
    minus_table: table
    --state: string = '-'
] {
    append (
        $minus_table
        | if $in == null {return} else {}
        | upsert amount {|i| $i.amount * -1}
    )
    | tokens-sum --state $state
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
    | each {
        |i| $i
        | get node_info.id remote_ip node_info.listen_addr
    }
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
    --disable_update (-U)
    --quiet                                     # Don't output execution's result
    --no_default_params                         # Don't use default params (like output, chain-id)
] {
    let $executable = if $exec != '' {$exec} else {$env.cy.exec}
    let $sub_commands_and_args = (
        if $rest == [] {
            error make {msg: 'The "ber" function needs arguments'}
        } else {
            ($rest | flatten | flatten)         # to recieve params as a list from passport-get
        }
        | if $no_default_params {} else {
            append [
                '--node' $env.cy.rpc-address
                '--chain-id' $env.cy.chain-id   # todo chainid to choose
                '--output' 'json'
            ]
        }
    )

    let $json_path = (
        $executable
        | append ($sub_commands_and_args)
        | str join '_'
        | str replace -r '--node.*' ''
        | to-safe-filename --suffix '.json'
        | [$env.cy.path cache jsonl $in]
        | path join
    )

    log debug $'json path: ($json_path)'

    def 'request-save-output-exec-response' [] {
        log debug $'($executable) ($sub_commands_and_args | str join " ")'

        let $response = (
            do -i { ^($executable) $sub_commands_and_args }
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
        | save -f -r $json_path;

        if ('error' in ($response | columns)) {
            return
        }

        if not $quiet {$response}
    }

    let $last_data = (
        if ($json_path | path exists) {
            let $last_file = (open $json_path)

            $last_file
            | to json -r
            | $'($in)(char nl)'
            | save -a -r ($json_path | str replace '.json' '_arch.jsonl')

            $last_file
            | upsert update_time ($in.update_time | into datetime)
        } else {
            {'update_time': (0 | into datetime)}
        }
    )

    let $freshness = ((date now) - $last_data.update_time)

    let $update = (
        $force_update or
        ($env.cy.ber_force_update? | default false) or
        (($freshness > $cache_stale_refresh) and (not $disable_update))
    )

    if $update {
        request-save-output-exec-response
    } else if ('error' in ($last_data | columns)) {
        log debug $'last update ($freshness) was unsuccessfull, requesting for a new one';
        request-save-output-exec-response
    } else {
        if ($freshness > $cache_validity_duration) {
            pu-add -o 2 $'cy ber --exec ($executable) --force_update --quiet [($sub_commands_and_args | str join " ")]'
        }
        $last_data
    }
}

# query neuron addrsss by his nick
export def 'qnbn' [
    ...nicks: string@'nu-complete-neurons-nicks'
    --df
] {
    let neurons = (
        dict-neurons
        | select nick neuron
        | where nick in $nicks
        | select neuron
    )

    $neurons
    | if $df {
        dfr into-df
    } else {
        if ($in | length | $in == 1) {
            get neuron.0
        } else {}
    }
}

# An ordered list of cy commands
export def 'help' [
    --to_md (-m) # export table as markdown
] {
    let $text = (
        open ($env.cy.path | path join cy.nu) --raw
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

def open_cy_config_toml [] {
    let $config_path = ('~' | path expand | path join .cy_config.toml)
    if not ($config_path | path exists) {
        {
            'path': ('~' | path expand | path join cy)
            'ipfs-files-folder': ('~' | path expand | path join cy graph particles safe)
            'ipfs-download-from': 'gateway'
            'ipfs-storage': 'cybernode'
        } |
        save ($config_path | path expand)
    }

    open ($config_path | path expand)
}

def make_default_folders_fn [] {
    mkdir ($env.cy.path | path join temp)
    mkdir ($env.cy.path | path join backups)
    mkdir ($env.cy.path | path join config)
    mkdir ($env.cy.path | path join graph particles safe)
    mkdir ($env.cy.path | path join export)
    mkdir ($env.cy.path | path join gephi)
    mkdir ($env.cy.path | path join cache search)
    mkdir ($env.cy.path | path join cache queue)
    mkdir ($env.cy.path | path join cache queue_tasks)
    mkdir ($env.cy.path | path join cache cli_out)
    mkdir ($env.cy.path | path join cache jsonl)

    touch ($env.cy.path | path join graph update.toml)

    if (
        not ($env.cy.path | path join $'cyberlinks_(tmp-links-name).csv' | path exists)
    ) {
        'from,to'
        | save ($env.cy.path | path join $'cyberlinks_(tmp-links-name).csv')
    }

    if (
        not ($env.cy.path | path join cyberlinks_archive.csv | path exists)
    ) {
        'from,to,address,timestamp,txhash'
        | save ($env.cy.path | path join cyberlinks_archive.csv)
    }
}

def 'system_cids' [] {
    [
        'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx',
        'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx',
        'Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs'
    ]
}

# echo particle for publishing
export def 'echo_particle_txt' [
    i
    --markdown (-m)
] {
    let $indent = ($i.step | into int | $in * 4 | $in + 12)

    if $i.content == null {
        $'⭕️ ($i.timestamp), ($i.nick) - timeout - ($i.particle)'
    } else {
        $'🟢 ($i.timestamp), ($i.nick)(char nl)($i.content)(char nl)($i.particle)'
    }
    | ^rich (
        [
            '-w' (80 + $indent)
            '-'
            '-d' $'0,0,1,($indent)'
        ]
        | if $markdown {
            append '-m'
        } else {}
    )
}

def 'col-name-reverse' [
    column: string
] {
    match $column {
        'from' => {'to'},
        'to' => {'from'},
        _ => {''}
    }
}

def 'now-fn' [
    --pretty (-P)
] {
    if $pretty {
        date now | format date '%Y-%m-%d-%H:%M:%S'
    } else {
        date now | format date '%Y%m%d-%H%M%S'
    }
}

def 'backup-fn' [
    filename
] {
    let $basename1 = ($filename | path basename)
    let $path2 = ($env.cy.path | path join backups $'(now-fn)($basename1)')

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
    let $filename = (
        $command
        | to-safe-filename --prefix $'($priority)-' --suffix '.nu.txt'
        | [ $env.cy.path cache queue_tasks $in ]
        | path join
    )

    $command
    | save -f $filename
}

export def 'queue-tasks-check' [
    --threads: int = 10
] {
    glob /Users/user/cy/cache/queue_tasks/*.nu.txt
    | sort
    | par-each -t $threads {
        |i| execute-task $i
    }
}

def 'execute-task' [
    task
] {
    let $command = open $task
    rm $task
    nu -c $command --config $nu.config-path --env-config $nu.env-path
    print $task
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

def 'nu-complete-config-names' [] {
    ls ($env.cy.path | path join config) -s
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

def 'path-exists-safe' [
    path_to_check
] {
    try {($'($path_to_check)' | path exists)} catch {false}
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
