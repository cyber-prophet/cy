# Cy - a tool for interactions with cybergraphs
# https://github.com/cyber-prophet/cy
#
# Use:
# > overlay use ~/cy/cy.nu -p -r

use std assert [equal greater]
use std clip
use nu-utils [bar, cprint, "str repeat", to-safe-filename, to-number-format, number-col-format]

use log

export def main [] { help-cy }
# export def cy [] { help-cy }

# Check if all necessary dependencies are installed
export def check-requirements [] {

    let $intermid = {
        |x| if ($x | length | $in == 0) {
            'all needed apps are installed'
        } else {
            $x
        }
    }

    ['ipfs', 'rich', 'curl', 'cyber', 'pussy']
    | each {
        |i| if (which ($i) | is-empty) {
            $'($i) is missing'
        }
    }
    | do $intermid $in
}

export-env {
    # banner2
    let $tested_versions = ['0.86.0']

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
# > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt' --follow_file_path
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
    --follow_file_path # treat existing file paths as reuglar texts
] : [string -> string, nothing -> string] {
    let $text = (
        $in
        | default $text_param
        | into string
        | if (
            ($follow_file_path) and (path-exists-safe $in)
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

    equal (pin-text 'cyber.txt') 'QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6'
    equal (pin-text 'cyber.txt' --follow_file_path) 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'

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
    text_from: string
    text_to: string
    --disable_append (-D) # Disable adding the cyberlink into the temp table
    --quiet (-q) # Don't output the cyberlink record after executing the command
] [nothing -> record, nothing -> nothing] {
    let $row = {
        'from_text': $text_from
        'to_text': $text_to
        'from': (pin-text $text_from)
        'to': (pin-text $text_to)
    }

    if not $disable_append {
        $row | links-append --quiet
    }

    if not $quiet {$row}
}

#[test]
def test_link_texts [] {
    # use ~/cy/cy.nu
    # use std assert equal
    equal {
        from_text: cyber,
        to_text: bostrom,
        from: "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
        to: "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"
    } (
        link-texts "cyber" "bostrom"
    )
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
] : [nothing -> table] {
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
    ...files: path        # filenames to add into the local ipfs node
    --link_filenames (-n)   # Add filenames as a from link
    --disable_append (-D)   # Don't append links to the links table
    --quiet                 # Don't output results page
    --yes (-y)              # Confirm uploading files without request
] : [nothing -> table, nothing -> nothing] {
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
    | if $yes or (agree -n true $in) { } else { return }

    let $results = (
        $files_col
        | par-each {|f| $f
            | upsert to_text $'pinned_file:($f.from_text)'
            | upsert to (ipfs add $f.from_text -Q | str replace (char nl) '')
            | if ($link_filenames) {
                upsert from (pin-text $f.from_text)
                | move from --before to
            } else { reject from_text }
        }
    )

    if not $disable_append { $results | links-append --quiet }
    if not $quiet { $results }
}

#[test]
def test-link-files [] {
    # use std assert equal

    mkdir linkfilestest; cd linkfilestest
    'cyber' | save -f cyber.txt; 'bostrom' | save -f bostrom.txt

    let $expect = [
        [from_text, to_text, from, to];
        [bostrom.txt, "pinned_file:bostrom.txt",
        "QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        [cyber.txt, "pinned_file:cyber.txt",
        "QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"]
    ]

    let $result = (
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
    neuron: string
] : [nothing -> record] {
    if not (is-neuron $neuron) {
        cprint $"*($neuron)* doesn't look like an address"
        return
    }

    link-texts 'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx' $neuron
}

#[test]
def test-follow [] {
    # use std assert equal

    let $expect = {
        from_text: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx",
        to_text: "bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8",
        from: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx",
        to: "QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af"
    }

    let $result = (
        follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
    )

    equal $expect $result
}

# Add a tweet and send it immediately (unless of disable_send flag)
#
# > cy links-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
# from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to_text: cyber-prophet is cool
# from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK
export def 'tweet' [
    text_to: string
    --disable_send (-D)
] : [nothing -> record] {
    # let $cid_from = pin-text 'tweet'
    let $cid_from = 'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx'

    if $disable_send {
        link-texts $cid_from $text_to
    } else {
        link-texts $cid_from $text_to -D | [$in] | links-send-tx $in
    }
}

#[test]
def test-tweet [] {
    # use std assert equal

    let $expect = {
        from_text: "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx",
        to_text: "cyber-prophet is cool",
        from: "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx",
        to: "QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK"
    }

    let $result = (
        links-clear;
        tweet 'cyber-prophet is cool' --disable_send;
    )

    equal $expect $result
}

# Add a random chuck norris cyberlink to the temp table
def 'link-chuck' [] : [nothing -> nothing] {
    let $quote = (
        http get -e https://api.chucknorris.io/jokes/random
        | get value
        | $in + "\n\n" + 'via [Chucknorris.io](https://chucknorris.io)'
    )

    cprint -f '=' --indent 4 $quote

    link-texts --quiet 'chuck norris' $quote
}

# Add a random quote cyberlink to the temp table
def 'link-quote' [] : [nothing -> nothing] {
    let $quote = (
        http get -e -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=text
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
    n: int = 1 # Number of links to append
    --source: string@'nu-complete-random-sources' = 'forismatic.com'
] : [nothing -> nothing] {
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
# > cy links-view | to yaml
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
export def 'links-view' [
    --quiet (-q) # Don't print info
    --no_timestamp
] : [nothing -> table] {
    let $filename = (current-links-csv-path)
    let $links = (
        try {
            open $filename
            | if $no_timestamp { reject timestamp } else {}
        } catch {
            [[from]; [null]] | first 0
        }
    )

    if (not $quiet) {
        let $links_count = ($links | length)

        if $links_count == 0 {
            cprint $'The temp cyberlinks table *($filename)* is empty.
            You can add cyberlinks to it manually or by using commands like *"cy link-texts"*'
        } else {
            cprint $'There are *($links_count) cyberlinks* in the temp table:'
        }
    }

    let $links_columns = ($links | columns)

    $links
    | if 'from_text' in $links_columns {
        into string from_text
    } else {}
    | if 'to_text' in $links_columns {
        into string to_text
    } else {}
}

# Append piped-in table to the temp cyberlinks table
export def 'links-append' [
    --quiet (-q)
] : [table -> table, table -> nothing] {
    $in
    | upsert timestamp (now-fn)
    | prepend (links-view -q)
    | if $quiet { links-replace -q } else { links-replace }
}

# Replace the temp table with piped-in table
export def 'links-replace' [
    --quiet (-q)
] : [table -> table, table -> nothing] {
    $in
    | save (current-links-csv-path) --force

    if (not $quiet) { links-view -q }
}

# Empty the temp cyberlinks table
export def 'links-clear' [] : [nothing -> nothing] {
    let $filename = (current-links-csv-path)
    backup-fn $filename

    $'from_text,to_text,from,to,timestamp(char nl)'
    | save $filename --force
}

#[test]
def test-tmps [] {
    # use std assert equal
    let $temp_name = (random chars)
    set-links-table-name ($temp_name)
    link-texts 'cyber' 'bostrom'

    [[from_text, to_text]; ['cyber-prophet' '🤘'] ['tweet' 'cy is cool!']]
    | links-append

    links-pin-columns;
    equal (
        links-view --no_timestamp
    ) [
        [from_text, to_text, from, to];
        [cyber, bostrom, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        [cyber-prophet, 🤘, "QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD", "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        [tweet, "cy is cool!", "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx", "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    links-link-all 'cy testing script'
    equal (
        links-view --no_timestamp
    ) [
        [from_text, to_text, from, to];
        ["cy testing script", bostrom, "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        ["cy testing script", 🤘, "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx", "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        ["cy testing script", "cy is cool!", "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx", "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    config-activate 42gboot+cyber

    link-random 3
    link-random 3 --source forismatic.com
    links-remove-existed

    equal (links-send-tx | get code) 0
}

# Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table
#
# > [[from_text, to_text]; ['cyber-prophet' null] ['tweet' 'cy is cool!']]
# | cy links-pin-columns | cy links-link-all 'master' --column 'to' --non_empty | to yaml
# - from_text: cyber-prophet
#   to_text: master
#   from: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
#   to: QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW
# - from_text: tweet
#   to_text: cy is cool!
#   from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
#   to: QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8
export def 'links-link-all' [
    text: string            # a text to upload to ipfs
    --dont_replace (-D)     # don't replace the temp cyberlinks table, just output results
    --column (-c): string = 'from'  # a column to use for values ('from' or 'to'). 'from' is default
    --non_empty             # fill non-empty only
] : [nothing -> table, table -> table] {
    $in
    | default (links-view -q)
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
    | if $dont_replace {} else { links-replace }
}

# Pin values from column 'text_from' and 'text_to' to an IPFS node and fill according columns with their CIDs
#
# > [{from_text: 'cyber' to_text: 'cyber-prophet'} {from_text: 'tweet' to_text: 'cy is cool!'}]
# | cy links-pin-columns | to yaml
# - from_text: cyber
#   to_text: cyber-prophet
#   from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   to: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
# - from_text: tweet
#   to_text: cy is cool!
#   from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
#   to: QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8
export def 'links-pin-columns' [
    --dont_replace (-D) # Don't replace the links cyberlinks table
    --threads: int = 3  # A number of threads to use to pin particles
] : [nothing -> table, table -> table] {
    let $links = (
        $in
        | default ( links-view -q )
        | fill non-exist -v null
    )

    let $dict = (
        $links
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
        | par-each -t $threads {|i| {$i: (pin-text $i)}}
        | reduce -f {} {|it acc|
            $acc
            | merge $it
        }
    )

    $links
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
    } | if $dont_replace {} else { links-replace }
}

# Check if any of the links in the links table exist
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
] : [nothing -> bool] {
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
export def 'links-remove-existed' [] : [nothing -> table, nothing -> nothing] {
    let $links_with_status = (
        links-view -q
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

        $links_with_status | filter {|x| not $x.link_exist} | links-replace
    } else {
        cprint 'There are no cyberlinks in the temp table for the current address exist the cybergraph'
    }
}

# Create a custom unsigned cyberlinks transaction
def 'tx-json-create-from-cybelinks' [] {
    let $links = (
        $in
        | select from to
        | uniq
    )

    let $transaction_body = (
        '{"body":{"messages":[
        {"@type":"/cyber.graph.v1beta1.MsgCyberlink",
        "neuron":"","links":[{"from":"","to":""}]}
        ],"memo":"cy","timeout_height":"0",
        "extension_options":[],"non_critical_extension_options":[]},
        "auth_info":{"signer_infos":[],"fee":
        {"amount":[],"gas_limit":"23456789","payer":"","granter":""}},
        "signatures":[]}' | from json
    )

    $transaction_body
    | upsert body.messages.neuron $env.cy.address
    | upsert body.messages.links $links
    | save (cy-path temp tx-unsigned.json) --force
}

def 'transaction-template' [
    --memo: string = 'cy'
    --timeout_height: string = '0'
    --gas_limit: string = '234567890'
    --payer: string = ''
    --granter: string = ''
]: table -> record {
    let $messages = $in

    { body: {
        messages: $messages,
        memo: $memo,
        timeout_height: $timeout_height,
        extension_options: [],
        non_critical_extension_options: []
    }, auth_info: {
        signer_infos: [], fee: {amount: [], gas_limit: $gas_limit, payer: $payer, granter: $granter}
    }, signatures: [] }
}

def 'tx-sign-and-broadcast' [] {

    let $params = (
        [
        --from $env.cy.address
        --chain-id $env.cy.chain-id
        --node $env.cy.rpc-address
        --output-document (cy-path temp tx-signed.json)
        ]
        | if $env.cy.keyring-backend? == 'test' {
            append ['--keyring-backend' 'test']
        } else {}
    )

    (
        ^($env.cy.exec) tx sign (cy-path temp tx-unsigned.json) $params
        | complete
        | if ($in.exit_code != 0) {
            error make {msg: 'Error signing the transaction!'}
        }
    )

    (
        ^($env.cy.exec) tx broadcast (cy-path temp tx-signed.json)
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
# > cy links-send-tx | to yaml
# cy: 2 cyberlinks should be successfully sent
# code: 0
# txhash: 9B37FA56D666C2AA15E36CDC507D3677F9224115482ACF8CAF498A246DEF8EB0
def 'links-send-tx' [
    $links_param?
] {
    if not (is-connected) {
        error make {msg: 'there is no internet!'}
    }

    if ($links_param | describe | $in =~ '^(table|list)') and ($links_param | length | $in > 100) {
        error-make-cy '*$links_param* length is bigger than 100, use links-add'
    }

    let $links = $links_param | default (links-view -q | first 100)

    let $links_count = ($links | length)

    $links | tx-json-create-from-cybelinks

    let $response = (
        tx-sign-and-broadcast
        | from json
        | select raw_log code txhash
    )

    let $filename = (cy-path mylinks _cyberlinks_archive.csv)
    if $response.code == 0 {
        open $filename
        | append ( $links | upsert neuron $env.cy.address )
        | save $filename --force

        if ($links_param == null) {
            links-view -q | skip 100 | links-replace
        }

        {'cy': $'($links_count) cyberlinks should be successfully sent'}
        | merge $response
        | select cy code txhash

    } else {
        print $response

        if $response.raw_log == 'not enough personal bandwidth' {
            print (query-links-bandwidth-neuron $env.cy.address)
            error-make-cy --unspanned 'Increase your *Volts* balance or wait time.'
        }
        if $response.raw_log =~ 'your cyberlink already exists' {
            error-make-cy --unspanned 'Use *cy links-remove-existed*'
        }

        cprint 'The transaction might be not sent.'
    }
}


# Publish all links in the temp table to cybergraph
export def 'links-publish' [] {
    links-view -q
    | length
    | if $in == 0 {
        error make ( cprint --err_msg $'
        there are no cyberlinks in the *(current-links-csv-path)* file' )
    } else { }
    | $in // 100
    | seq 0 $in
    | each {links-send-tx}
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
            $'`{"active_passport":{"address":"($address_or_nick)"}}`'   # not sure about backticks here
        } else {
            $'`{"passport_by_nickname":{"nickname":"($address_or_nick)"}}`'
        }
    )

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    let $params = ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']

    ber --exec 'cyber' --no_default_params query wasm contract-state smart $pcontract $json $params
    | if $in == null {
        if not $quiet {
            cprint --before 1 --after 2 $'No passport for *($address_or_nick)* is found'
        }
        {}
    } else {
        get data
        | merge $in.extension
        | reject extension approvals token_uri
    }
}

#[test]
def passport-get-test [] {
    equal (passport-get bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel) {}
    equal (passport-get bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85ted) {}
    equal (passport-get bostrom1de53jgxjfj5n84qzyfd7z44m9wrudygt524v6r | get nickname) 'graphkeeper'
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
    (cy-path graph neurons_dict.yaml)
    | if ($in | path exists) {
        open
    } else { [[neuron];['bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8']] }
    | if $df {
        fill non-exist
        | if ('addresses' in ($in | columns)) {
            reject addresses # quick fix for failing df conversion
        } else {}
        | to yaml
        | str replace -a 'null' "''"
        | from yaml
        | dfr into-df
    } else { }
}

#[test]
def dict-neurons-test-dummy [] {
    equal (dict-neurons; null) null
    equal (dict-neurons --df; null) null
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
            let $yaml = (cy-path graph neurons_dict.yaml)
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
export def --env 'graph-download-snapshot' [
    --disable_update_parquet (-D)   # Don't update the particles parquet file
] {
    make_default_folders_fn

    let $path = (cy-path graph)
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

#[test]
def graph-download-snapshot-test-dummy [] {
    equal (graph-download-snapshot; null) null
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
    let $path_csv = (cy-path graph cyberlinks.csv)

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

#[test]
def graph-download-links-test-dummy [] {
    equal (graph-download-links; null) null
}

# filter system particles out
def 'gp-filter-out-system-particles' [
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
    let $links = ( graph-links-df | dfr into-lazy )

    let $links_columns = ($links | dfr columns)
    if ($to and $from) {
        error make {msg: 'you need to use only "to", "from" or none flags at all, none both of them'}
    }

    def graph-to-particles-keep-column [
        c
        --column: string
    ] {
        $links
        | dfr rename $'particle_($column)' particle
        | dfr drop $'particle_(col-name-reverse $column)'
        | dfr with-column [
            (dfr lit ($column) | dfr as 'init-role'),
        ]
    }

    let $dummy = (
        $links
        | dfr rename particle_from particle
        | dfr drop particle_to
        | dfr with-column (dfr lit 'a' | dfr as 'init-role')
        | dfr fetch 0  # Create dummy dfr to have something to appended to
    )

    (
        $dummy
        | if not $to {
            dfr append --col (
                graph-to-particles-keep-column $links --column from
            )
        } else {}
        | if not $from {
            dfr append --col (
                graph-to-particles-keep-column $links --column to
            )
        } else {}
        | dfr into-lazy
        | if ('link_local_index' in $links_columns) {
            dfr sort-by [link_local_index height]
        } else {
            dfr sort-by [height]
        }
        | dfr unique --subset [particle]
        | if not $include_system {
            gp-filter-out-system-particles
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
# In the piped in particles df leave only particles appeared for the first time
export def 'particles-keep-only-first-neuron' [
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
        ls -s (cy-path graph particles safe) # I use ls instead of glob to have the filesize column
        | reject modified type
        | upsert content {
            |i| open -r (cy-path graph particles safe $i.name)
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

    backup-fn (cy-path graph particles.parquet)

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
        | dfr to-parquet (cy-path graph particles.parquet)
        | print ($in | get 0 -i)
    )
}

# Filter the graph to chosen neurons only
export def 'graph-filter-neurons' [
    ...neurons_nicks: string@'nu-complete-neurons-nicks'
] {
    let $links = ( graph-links-df )

    $neurons_nicks
    | dfr into-df
    | dfr join ( dict-neurons --df ) '0' nick
    | dfr select neuron
    | dfr join ( $links ) neuron neuron
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

    let $links = (
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
        $links
        | graph-to-particles --include_system
        | if $only_first_neuron {
            particles-keep-only-first-neuron
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

    $links
    | dfr append -c (append_related from --step ($step))
    | dfr append -c (append_related to --step ($step + 1))
    | dfr into-lazy
    | dfr sort-by [link_local_index height]
    | dfr unique --subset [particle_from particle_to]
    | dfr collect
}

# Output neurons stats based on piped in or the whole graph
export def 'graph-neurons-stats' [] {
    let $links = (graph-links-df)
    let $p = (graph-particles-df)

    let $follows = (
        [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | dfr into-df
        | dfr join --left $links particle particle_from
        | dfr group-by neuron
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'follows')
        ]
        | dfr sort-by follows --reverse [true]
    )

    let $followers = (
        [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | dfr into-df
        | dfr join --left $links particle particle_from
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
        | dfr join --left $links particle particle_from
        | dfr group-by neuron
        | dfr agg [
            (dfr col timestamp | dfr count | dfr as 'tweets')
        ]
    )

    (
        $links
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
    let $links = (graph-links-df)
    let $particles = (
        $links
        | graph-to-particles --include_system --include_global
    )

    let $t1_height_index = (
        $links.height
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
        $links
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
        | dfr to-csv (cy-path export !gephi_cyberlinks.csv)
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
        | save  -f (cy-path export !gephi_particles.csv)
    )
}

# Logseq export WIP
export def 'graph-to-logseq' [
    # --path: string
] {
    let $links = (graph-links-df | inspect2)
    let $particles = (
        $links
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

    $links
    | dfr into-nu
    | each {|c|
        $"\t- [[($links.particle_to)]] ($links.height) [[($links.nick?)]]\n" |
        save -a ($path | path join pages $'($links.particle_from).md')
    }
}

# Output particles into txt formated feed
export def 'graph-to-txt-feed' [] {
    $in
    | graph-append-related --only_first_neuron
    | graph-to-particles
    | particles-keep-only-first-neuron
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
    let $links = (graph-links-df)
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

    let $links_columns = ($links | dfr columns)

    let $c_out = (
        $links
        | if 'particle_to' in $links_columns {
            dfr join --left $p particle_to particle
            | dfr rename content_s content_s_to
        } else {}
        | if 'particle_from' in $links_columns {
            dfr join --left $p particle_from particle
            | dfr rename content_s content_s_from
        } else {}
        | if 'particle' in $links_columns {
            dfr join --left $p particle particle
        } else {}
        | if 'neuron' in $links_columns {
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
        graph-open-csv-make-df (cy-path graph cyberlinks.csv)
    } else {}
    | if $include_contracts {
        dfr append -c (
            graph-open-csv-make-df (cy-path graph cyberlinks_contracts.csv)
        )
    } else {}
    | if $exclude_system {
        dfr into-lazy
        | gp-filter-out-system-particles particle_from
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
    let $p = (dfr open (cy-path graph particles.parquet))
    $p
}

# Create a config JSON to set env variables, to use them as parameters in cyber cli
export def --env 'config-new' [
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
        | $'($in)-($exec)'
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
        let $filename = (cy-path config $'($config_name).toml')
        open $filename
    }
    # | if $quiet {} else {inspect2}
}

# Save the piped-in JSON into config file
export def --env 'config-save' [
    config_name: string@'nu-complete-config-names'
    --inactive # Don't activate current config
] {
    let $in_config = ($in | upsert config-name $config_name)
    let $filename = (cy-path config $'($config_name).toml')

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
                (cy-path config $'(now-fn).toml')
            }
        }
    )

    $in_config
    | upsert config-name ($filename2 | path parse | get stem)
    | upsert config-path ($filename2)
    | if (not $inactive) {
        config-activate
    } else {}
    | inspect2
    | save $filename2 -f

    print $'($filename2) is saved'
}

# Activate the config JSON
export def --env 'config-activate' [
    config_name?: string@'nu-complete-config-names'
] {
    let $config = ($in | default (config-view $config_name))
    let $config_path = ($nu.home-path | path join .cy_config.toml)
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
    --page (-p): int = 0
    --results_per_page (-r): int = 10
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
    --page (-p): int = 0
    --results_per_page (-r): int: int = 10
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
    query: string
    --page (-p): int = 0
    --results_per_page (-r): int = 10
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

    $results | save (cy-path cache search '($cid)-(date now|into int).json')

    clear; print $'Searching ($env.cy.exec) for ($cid)';

    serp1 $results

    watch (cy-path cache queue) {|| clear; print $'Searching ($env.cy.exec) for ($cid)'; serp1 $results}
}

# Use the built-in node search function in cyber or pussy
export def 'search' [
    query
    --page (-p): int = 0
    --results_per_page (-r): int = 10
    --search_type: string@'nu-complete-search-functions' = 'search-with-backlinks'
] {
    # todo `use match`
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

#[test]
def search-test-dummy [] {
    greater (search 'cy' | length) 0
}

# Obtain cid info
# > cy cid-get-type-gateway QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV | to yaml
# type: text/plain; charset=utf-8
# size: '5'
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
    --file: path = ''
] {
    let $file_path = ($file | if $in == '' {cy-path cache MIME_types.csv} else {})
    $'($cid),($source),"($type)",($size),($status),(history session)(char nl)' | save -a $file_path
}

# Read a CID from the cache, and if the CID is absent - add it into the queue
export def 'cid-read-or-download' [
    cid: string
    --full  # output full text of a particle
] {
    do -i {open ($env.cy.ipfs-files-folder | path join $'($cid).md')}
    | default (
        queue-task-add $'cid-download ($cid)';
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
        queue-task-add $'cid-download ($cid) --source ($source) --info_only ($info_only) --folder '($folder)''
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
        rm --force (cy-path cache queue $cid)
        'downloaded'
    } else if $status == 'not found' {
        queue-cid-add $cid '-'
        'not found'
        # error make {msg: $'($cid) is not found'}
    }
}

# Download a cid from kubo (go-ipfs cli) immediately
def 'cid-download-kubo' [
    cid: string
    --timeout = '300s'
    --folder: path
    --info_only: bool = false # Don't download the file but write a card with filetype and size
] {
    log debug $'cid to download ($cid)'
    let $file_path = ($folder | default $env.cy.ipfs-files-folder | path join $'($cid).md')
    let $type = (
        do {^ipfs cat --timeout $timeout -l 400 $cid}
        | complete
        | if ($in == null) or ($in.exit_code == 1) {
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
        if (
            ipfs get --progress=false --timeout $timeout -o $file_path $cid
            | complete # complete here is to hide ipfs get err output, as it sends there information
            | $in.exit_code == 0
        ) {
            return 'text'
        } else {
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
            | save -f $file_path
        )
        return 'non_text'
    }
}

#[test]
def cid-download-kubo-test-dummy [] {
    equal (cid-download-kubo 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV') 'text'
}

# Download a cid from gateway immediately
def 'cid-download-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --folder: string
    --info_only: bool = false # Don't download the file by write a card with filetype and size
] {
    let $file_path = ($folder | default $'($env.cy.ipfs-files-folder)' | path join $'($cid).md')
    let $meta = (cid-get-type-gateway $cid)
    let $type = ($meta | get -i type)
    let $size = ($meta | get -i size)

    if (
        (($type | default '') == 'text/plain; charset=utf-8') and (not $info_only)
    ) {
        http get -e $'($gate_url)($cid)' -m 120 | save -f $file_path
        return 'text'
    } else if ($type != null) {
        {'MIME type': $type, 'Size': $size} | sort -r | to toml | save -f $file_path
        return 'non_text'
    } else {
        return 'not found'
    }
}

#[test]
def cid-download-gateway-test-dummy [] {
    equal (cid-download-gateway QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV) 'text'
}

# Add a CID to the download queue
export def 'queue-cid-add' [
    cid: string
    symbol: string = '+'
] {
    let $path = (cy-path cache queue $cid)

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
    watch (cy-path cache search) {|| queue-cids-download }
}

# Check the queue for the new CIDs, and if there are any, safely download the text ones
export def 'queue-cids-download' [
    attempts: int = 0       # limit a number of previous download attempts for cids in queue
    --info                  # don't download data, just check queue
    --quiet                 # don't print information
    --threads: int = 15     # a number of threads to use for downloading
    --cids_in_run: int = 0 # a number of files to download in one command run. 0 - means all (default)
] {
    let $files = (ls -s (cy-path cache queue))

    if ( ($files | length) == 0 ) {
        return 'there are no files in queue'
    }

    if not $quiet {
        cprint $'Overall count of files in queue is *($files | length)*'
        cprint $'*($env.cy.ipfs-download-from)* will be used for download'
    }

    let $filtered_files = (
        $files
        | where size <= (1 + $attempts | into filesize)
        | sort-by size
    )

    let $filtered_count = ($filtered_files | length)

    if ($filtered_files == []) {
        if not $quiet {print $'There are no files, that was attempted to download for less than ($attempts) times.'}
        return
    } else {
        if not $quiet {
            print $'There are ($filtered_count) files that was attempted to be downloaded ($attempts) times already.'

            ($filtered_files | sort-by modified -r | sort-by size | get modified.0 -i)
            | print $'The latest file was added into the queue ($in)'
        }
    }

    if $info {return}

    ($filtered_files | where size < 4b | sort-by modified -r | sort-by size) # new small files first
    | append ($filtered_files | where size >= 4b | sort-by modified) # old files first
    | get name -i
    | if $cids_in_run > 0 {
        first $cids_in_run
    } else {}
    | enumerate
    | par-each -t $threads {
        |i| cid-download $i.item
        | if $nu.is-interactive {
            print -n $'(if ($in == "not found") {'-'} else {'+'})'
            # print -n $"( ansi -e '1000D' )( bar --width 60 --background yellow ($i.index / $filtered_count)) ($i.index):($in)"
        } else {}
    }
}

# Clear the cache folder
export def 'cache-clear' [] {
    backup-fn (cy-path cache)
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

# Unexisting addresses make cyber fail. To catch this I use token-dummy-balance
def 'token-dummy-balance' [] {
    [{denom: boot, amount: 0}]
}

# Get supply of all tokens in a network
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
    | if $in == [] {return} else {}
    | upsert amount {|i| $i.amount | into int}
    | if $sum {
        tokens-sum
    } else {}
    | upsert state rewards
}

export def 'tokens-investmint-status-table' [
    address: string
    --h_liquid      # retrun amount of liquid H
    --quiet         # don't print amount of H liquid
    --height: int = 0
    --sum
] {
    let $account_vesting = (query-account $address --height $height)

    if ($account_vesting | get -i vesting_periods) == null {
        return []
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
        | if ($in | length | $in > 0) {
            get amount.0 | into int
        } else { 0 }
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
        | append null   # if no investmint slots are busy, the command should return a list
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

export def 'tokens-routed-to' [
    address: string
    --height: int = 0
] {
    ber query grid routed-to $address [--height $height]
    | get -i value
    | if $in == null {return} else { }
    | upsert amount {|i| $i.amount | into int}
    | upsert state routed-to
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
export def 'tokens-ibc-denoms-table' [
    --full # return all the columns
] {
    tokens-supply-get
    | transpose
    | rename denom amount
    | where denom =~ '^ibc'
    | upsert ibc_hash {|i| $i.denom | str replace 'ibc/' ''}
    | each {
        |i| $i
        | merge ( ber query ibc-transfer denom-trace $"'($i.ibc_hash)'" | get denom_trace )
    }
    | reject ibc_hash
    | upsert denom_f {
        |i| $i.path         #denom compound
        | str replace -ra '[^-0-9]' ''
        | str trim -c '-'
        | $'($i.base_denom)/($i.denom | str substring 62..68)/($in)'
    }
    | sort-by path --natural
    | reject path amount
    | if $full {} else {
        select denom denom_f
    }
}

export def 'tokens-denoms-decimals-dict' [] {
    # eventually should be on contract bostrom15phze6xnvfnpuvvgs2tw58xnnuf872wlz72sv0j2yauh6zwm7cmqqpmc42
    # but now on git
    http get 'https://raw.githubusercontent.com/cybercongress/cyb/master/src/utils/tokenList.js'
    | str replace -r -m '(?s).*(\[.*\]).*' '$1'
    | from nuon
    | rename -c {'coinMinimalDenom': 'base_denom'}
    | rename -c {'denom': 'ticker'}
    | rename -c {'coinDecimals': 'decimals'}
    | select base_denom ticker decimals
    | append [
        # [base_denom, ticker, coinDecimals];
        {base_denom: usomm, ticker: SOMM, decimals: 6}
        {base_denom: ucre, ticker: CRE, decimals: 6}
        {base_denom: boot, ticker: mBOOT, decimals: 6}
        {base_denom: pussy, ticker: gPUSSY, decimals: 9}
        {base_denom: hydrogen, ticker: mH, decimals: 6}
        {base_denom: tocyb, ticker: mTOCYB, decimals: 6}
    ]
    | reverse
    | uniq-by base_denom
}

export def 'tokens-price-in-h-naive' [
    --all_data
]: nothing -> table {
    let $pools = (
        tokens-pools-table-get
        | select reserve_coin_amount reserve_account_address reserve_coin_denom
        | into float reserve_coin_amount
    )

    $pools
    | where reserve_coin_denom == hydrogen
    | rename hydrogen
    | join -l ($pools | where reserve_coin_denom != hydrogen) reserve_account_address
    | reject reserve_account_address
    | insert price_in_h_naive {|i| $i.hydrogen / $i.reserve_coin_amount}
    | if $all_data {} else {select reserve_coin_denom_ price_in_h_naive}
    | rename -c {reserve_coin_denom_: denom}
    | append {denom: hydrogen price_in_h_naive: 1.0}
}

export def 'tokens-in-h-naive' [
    --price # leave price in h column
] {
    join (tokens-price-in-h-naive) denom denom -l
    | default 0 price_in_h_naive
    | upsert amount_in_h_naive {
        |i| $i.amount * $i.price_in_h_naive
    }
    | if $price {} else {
        reject price_in_h_naive
    }
    | move amount_in_h_naive --before amount
}

export def 'tokens-in-h-swap-calc' [
    percentage: float = 0.3
] {
    let $input = $in | join -l (tokens-price-in-h-naive --all_data) denom denom

    let $with_h_pools = $input | where price_in_h_naive? != null
    let $no_h_pools = $input | where price_in_h_naive? == null

    # You can use any percent here
    let percent_formatted = $percentage * 100 | math round | into string | $in + '%'

    $with_h_pools
    | upsert source_amount {|i| $i.amount * $percentage }
    | each {|i| tokens-price-in-h-real-record $i}
    | move h_out_amount --before amount
    | upsert $'price_in_h_slip($percent_formatted)' {
        |i| ($i.h_out_price - $i.price_in_h_naive) / $i.price_in_h_naive * 100
    }
    | move $'price_in_h_slip($percent_formatted)' --after price_in_h_naive
    | append $no_h_pools
    | fill non-exist 0.0
    | rename -c {h_out_amount: $'amount_in_h_swap($percent_formatted)'}
    # | rename -c {source_amount: $'amount_source($percent_formatted)'}
    | reject ($in | columns | where $it in [
        hydrogen reserve_coin_denom reserve_coin_amount h_out_price price_in_h_naive source_amount
    ])
}

def 'tokens-price-in-h-real-record' [
    row: record
] {
    if $row.denom == 'hydrogen' {
        return ($row | upsert h_out_amount {|i| $i.source_amount} | upsert h_out_price 1.0)
    }

    if $row.hydrogen? == null {
        return $row
    }

    $row
    | upsert h_out_price {|i|
        swap_calc_price -s $i.source_amount -T $i.hydrogen -S $i.reserve_coin_amount
    }
    | upsert h_out_amount {|i|
        $i.h_out_price * $i.source_amount
    }
}

def swap_calc_price [
    --source_coin_amount (-s): float
    --target_coin_pool_amount (-T): float
    --source_coin_pool_amount (-S): float
    --pool_fee (-f): float = 0.003
] {
    if $source_coin_amount == 0 {
        $target_coin_pool_amount / $source_coin_pool_amount
    } else {
        ( (($target_coin_pool_amount | into float) * (1 - $pool_fee))
            / (($source_coin_pool_amount | into float) + 2 * ($source_coin_amount | into float)) )
    }

}

def swap_calc_amount [
    --source_coin_amount (-s): float
    --target_coin_pool_amount (-T): float
    --source_coin_pool_amount (-S): float
    --pool_fee (-f): float = 0.003
] {
    if source_coin_amount == 0 {
        0
    } else {
        ( ($source_coin_amount * $target_coin_pool_amount * (1 - $pool_fee))
            / ($source_coin_pool_amount + 2 * $source_coin_amount) )
        | into int
    }
}

export def 'tokens-format' [] {
    let $input = join -l (tokens-ibc-denoms-table) denom denom | fill non-exist

    let $columns = $input | columns

    $columns
    | where $it =~ 'amount_in_h'
    | if ($in | length | $in > 0) {
        reduce -f $input {|i acc| $acc | merge ($acc | number-col-format $i --decimals 0 --denom 'H')}
    } else {$input}
    # $input
    | upsert denom_f {|i| if $i.denom_f? != null {$i.denom_f} else {$i.denom}}
    | move denom_f --before ($in | columns | first)
    | move denom --after ($in | columns | last)
    | upsert base_denom {|i| $i.denom_f | split row '/' | get 0 }
    | join -l (tokens-denoms-decimals-dict) base_denom base_denom
    | default 0 decimals
    | upsert denom_f {
        |i| $i.denom_f
        | str replace $i.base_denom ($i.ticker? | default ($i.denom_f | str upcase))
    }
    | if amount in $columns {
        upsert amount_f {
            |i| $i.amount / (10 ** $i.decimals)
            | to-number-format --integers 9 --decimals 2
        }
        | move amount_f --after denom_f
    } else {}
    | reject ($in | columns | where $it in [base_denom ticker decimals])
}

# Check balances for the keys added to the active CLI
#
# > cy balances --test | to yaml
# name: bot3f
# boot: 654582269
# hydrogen: 50
# address: bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel
export def 'balances' [
    ...address: string@'nu-complete keys values'
    --test      # Use keyring-backend test (with no password)
] {
    let $balances = (
        ^($env.cy.exec) keys list --output json --keyring-backend test | from json
        | if not $test {
            append ( ^($env.cy.exec) keys list --output json | from json )
        } else {}
        | select name address
        | if ($address | is-empty) { } else {
            where address in $address
        }
        | par-each {
            |i| tokens-balance-get --record $i.address
            | merge $i
        }
    )

    let $default_columns = (
        $balances | columns | prepend 'name' | uniq
        | reverse | prepend ['address'] | uniq
        | reverse | reduce -f {} {|i acc| $acc | merge {$i : 0}}
    )

    $balances
    | each {|i| $default_columns | merge $i}
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
            return []
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
    | if $in in [null []] {return} else {}
    | sort-by amount -r
    | group-by denom
    | values
    | each {
        |i| {}
        | upsert denom $i.denom.0
        | upsert amount ($i.amount | into float | math sum | into int)
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

# Withdraw rewards, make stats
export def 'rewards-withdraw' [
    neuron?: string
] {
    let $address = $neuron | default $env.cy.address

    let $tx = (
        ^($env.cy.exec) tx distribution withdraw-all-rewards --from $address --fees 2000boot --gas 2000000 --output json --yes
        | from json
    )

    if $tx.code? != 0 { cprint '*tx.code != 0*' }
    print ($tx | select code txhash)

    let $tx_hash = $tx | get txhash

    print 'Waiting for 20 seconds to query for transaction info from the node'
    sleep 20sec

    rewards-withdraw-tx-analyse $tx_hash
}

export def 'rewards-withdraw-tx-analyse' [
    tx_hash: string
] {
    let $tx = query-tx $tx_hash

    let $tx_height = $tx | get height | into int | $in - 1
    let $tx_neuron = $tx | get tx.body.messages.0.delegator_address

    let $rewards = (
        $tx
        | get logs
        | each {|i| $i
            | get -i events
            | where type == withdraw_rewards
            | get attributes.0 -i
            | transpose -r
            | upsert amount {|i| $i.amount | split row ',' }
            | flatten
        }
        | flatten
        | insert denom {|i| $i.amount | str replace -r '\d+' '$1'}
        | insert rewards {|i| $i.amount | str replace -r '\D+' '$1' | into int}
        | reject amount
    )

    let $result = (
        tokens-delegations-table-get $tx_neuron --height $tx_height
        | reject delegator_address shares denom
        | rename validator delegated
        | where delegated > 0
        | join ($rewards | where denom == boot) -l validator validator
        | upsert percent {|i| (($i.rewards) / $i.delegated) }
    );

    $result
    | upsert percent_rel {|i| $i.percent / ($result.percent | math max)}
}

# Set the custom name for links csv table
export def --env 'set-links-table-name' [
    name: string
] : nothing -> nothing {
    $env.cy.links_table_name = $name
}

# Force ber to update results with every request
export def --env 'set-ber-force-update' [
    value?: bool
] : nothing -> bool {
    $env.cy.ber_force_update = (
        if $value == null {
            not ($env.cy.ber_force_update? | default false)
        } else {$value}
        | inspect2
    )
}

export def 'current-links-csv-path' [
    name?: path
] : nothing -> path {
    $name
    | default ($env.cy.links_table_name?)
    | default 'temp'
    | cy-path mylinks $'($in).csv'
}

# Add the cybercongress node to bootstrap nodes
export def 'ipfs-bootstrap-add-congress' [] : nothing -> nothing {
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
] : nothing -> string {
    let $node_address = ($node_address | default $'($env.cy.rpc-address)')
    if $node_address == $env.cy.rpc-address {
        cprint -a 2 $"Nodes list for *($env.cy.rpc-address)*"
    }

    let $peers = (http get -e $'($node_address)/net_info' | get result.peers)

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

# Query tx by hash
export def 'query-tx' [
    hash: string
] : nothing -> record {
    ber --disable_update --error [query tx --type hash $hash]
    | reject events
}

# Query tx by acc/seq
export def 'query-tx-seq' [
    neuron: string
    seq: int
] : nothing -> record {
    ber --disable_update [query tx --type=acc_seq $'($neuron)/($seq)']
    | if 'events' in ($in | columns) {
        reject events
    } else {}
}

# Query account
export def 'query-account' [
    neuron: string
    --height: int = 0
    --seq   # return sequence
] : nothing -> record {
    ber query account $neuron [--height $height]
    | if $seq {
        get base_vesting_account.base_account.sequence
        | into int
    } else {}
}

export def 'query-links-max-in-block' [] : nothing -> int {
    ( query-links-bandwidth-params | get max_block_bandwidth ) / ( query-links-bandwidth-price )
    | into int
}

def 'query-links-bandwidth-price' [] : nothing -> int {
    ber query bandwidth price | get price.dec | into float | $in * 1000 | into int # price in millivolt
}

def 'query-links-bandwidth-params' [] : nothing -> record {
    ber query bandwidth params
    | get params
    | transpose key value
    | upsert value {|i| $i.value | into float}
    | transpose -idr
}

export def 'query-links-bandwidth-neuron' [
    neuron?
] nothing - table {
    ber query bandwidth neuron ($neuron | default $env.cy.address) --cache_stale_refresh 5min
    | get neuron_bandwidth
    | select max_value remained_value
    | transpose param links
    | upsert links {|i| $i.links | into int | $in / (query-links-bandwidth-price) | math floor}
}


# A wrapper, to cache CLI requests
export def --wrapped 'ber' [
    ...rest
    --exec: string = ''                         # The name of executable
    --cache_validity_duration: duration = 60min # Sets the cache's valid duration. No updates initiated during this period.
    --cache_stale_refresh: duration = 7day      # Sets stale cache's usable duration. Triggers background update and returns cache results. If exceeded, requests immediate data update.
    --force_update
    --disable_update (-U)
    --quiet                                     # Don't output execution's result
    --no_default_params                         # Don't use default params (like output, chain-id)
    --error                                     # raise error instead of null in case of cli's error
] : nothing -> record {
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
            if $error {
                error make {msg: ($response.error.stderr | lines | first)}
            } else {
                return
            }
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
        } else {
            {'update_time': 0}
        } | into datetime update_time
    )

    let $freshness = ((date now) - $last_data.update_time)

    let $update = (
        $force_update or
        ($env.cy.ber_force_update? | default false) or
        ($last_data.update_time == (0 | into datetime)) or
        (($freshness > $cache_stale_refresh) and (not $disable_update))
    )

    if $update {
        request-save-output-exec-response
    } else if ('error' in ($last_data | columns)) {
        log debug $'last update ($freshness) was unsuccessfull, requesting for a new one';
        request-save-output-exec-response
    } else {
        if ($freshness > $cache_validity_duration) {
            queue-task-add -o 2 $'ber --exec ($executable) --force_update --quiet [($sub_commands_and_args | str join " ")]'
        }
        $last_data
    }
}

#[test]
def ber-test [] {
    equal (
        ber query rank karma bostrom1smsn8u0h5tlvt3jazf78nnrv54aspged9h2nl9 | describe
    ) 'record<karma: string, update_time: date>'
    equal (
        ber query bank balances bostrom1quchyywzdxp62dq3rwan8fg35v6j58sjwnfpuu | describe
    ) 'record<balances: table<denom: string, amount: string>, pagination: record<next_key: nothing, total: string>, update_time: date>'
    equal (
        ber query bank balances bostrom1cj8j6pc3nda8v708j3s4a6gq2jrnue7j857m9t | describe
    ) 'record<balances: table<denom: string, amount: string>, pagination: record<next_key: nothing, total: string>, update_time: date>'
    equal (
        ber query staking delegations bostrom1eg3v42jpwf3d66v6rnrn9hedyd8qvhqy4dt8pc | describe
    ) 'record<delegation_responses: table<delegation: record<delegator_address: string, validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, pagination: record<next_key: nothing, total: string>, update_time: date>'
    equal (
        ber query staking delegations bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | describe
    ) 'record<delegation_responses: table<delegation: record<delegator_address: string, validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, pagination: record<next_key: nothing, total: string>, update_time: date>'
    equal (
        ber query rank top  | describe
    ) 'record<result: table<particle: string, rank: string>, pagination: record<total: int>, update_time: date>'
    equal (
        ber query ibc-transfer denom-traces  | describe
    ) 'record<denom_traces: table<path: string, base_denom: string>, pagination: record<next_key: nothing, total: string>, update_time: date>'
    equal (
        ber query liquidity pools  | describe
    ) 'record<pools: table<id: string, type_id: int, reserve_coin_denoms: list<string>, reserve_account_address: string, pool_coin_denom: string>, pagination: record<next_key: nothing, total: string>, update_time: date>'}

# query neuron addrsss by his nick
export def 'qnbn' [
    ...nicks: string@'nu-complete keys-nicks'
    --df
    --force_list_output (-f)
] {
    let $addresses = $nicks | where (is-neuron $it) | wrap neuron

    let $neurons = (
        if ($nicks | where (not (is-neuron $it)) | is-empty ) {
            []
        } else {
            nicks-and-keynames
            | where name in $nicks
            | select neuron
            | uniq-by neuron
        }
    )

    $neurons
    | append $addresses
    | if $df {
        dfr into-df
    } else if ($in | length | $in == 1) and (not $force_list_output) {
        get neuron.0
    } else {}
}

# An ordered list of cy commands
export def 'help-cy' [
    --to_md (-m) # export table as markdown
] {
    let $text = (
        open (cy-path cy.nu) --raw
        | parse -r "(\n(# )(?<desc>.*?)(?:\n#[^\n]*)*\nexport (def|def.env) '(?<command>.*)')"
        | select command desc
        | upsert command {|row index| ('cy ' + $row.command)}
    )

    $text
    | if $to_md { to md } else { }
}

def 'banner' [] {
    print $"
     ____ _   _
    / ___\) | | |
   \( \(___| |_| |
    \\____)\\__  |   (ansi yellow)cy(ansi reset) nushell module is loaded
         \(____/    have fun🔵"
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
    let $config_path = ($nu.home-path | path join .cy_config.toml)
    if not ($config_path | path exists) {
        {
            'path': ($nu.home-path | path join cy)
            'ipfs-files-folder': ($nu.home-path | path join cy graph particles safe)
            'ipfs-download-from': 'gateway'
            'ipfs-storage': 'cybernode'
        }
        | save $config_path
    }

    open $config_path
}

def make_default_folders_fn [] {
    mkdir (cy-path temp)
    mkdir (cy-path backups)
    mkdir (cy-path config)
    mkdir (cy-path graph particles safe)
    mkdir (cy-path export)
    mkdir (cy-path gephi)
    mkdir (cy-path cache search)
    mkdir (cy-path cache queue)
    mkdir (cy-path cache queue_tasks)
    mkdir (cy-path cache cli_out)
    mkdir (cy-path cache jsonl)
    mkdir (cy-path mylinks)

    touch (cy-path graph update.toml)

    if ( current-links-csv-path | path exists | not $in ) {
        'from,to' | save (current-links-csv-path)
    }

    if ( cy-path mylinks _cyberlinks_archive.csv | path exists | not $in ) {
        'from,to,address,timestamp,txhash'
        | save (cy-path mylinks _cyberlinks_archive.csv) # underscore is supposed to place the file first in the folder
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
    date now
    | format date (
        if $pretty {'%Y-%m-%d-%H:%M:%S'} else {'%Y%m%d-%H%M%S'}
    )
}

def 'backup-fn' [
    filename
] {
    let $basename = ($filename | path basename)
    let $backups_path = (cy-path backups $'(now-fn)($basename)')

    if (
        $filename
        | path exists
    ) {
        ^cp $filename $backups_path
        # print $'Previous version of ($filename) is backed up to ($backups_path)'
    } else {
        cprint $'*($filename)* does not exist'
    }
}

export def 'queue-task-add' [
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

export def 'queue-tasks-monitor' [
    --threads: int = 10
    --cids_in_run: int = 10 # a number of files to download in one command run. 0 - means all (default)
] {
    loop {
        glob (cy-path cache queue_tasks *.nu.txt)
        | sort
        | if ($in | length) == 0 {
            queue-cids-download 10 --cids_in_run $cids_in_run --threads $threads --quiet;
            print ''
        } else {
            par-each -t $threads {
                |i| execute-task $i
            };
            print ''
        };
        sleep 1sec
    }
}

def 'execute-task' [
    task_path: path
] {
    let $command = open $task_path

    do -i {
        nu -c $'use (cy-path cy.nu); ($command)' --config $nu.config-path --env-config $nu.env-path
    }
    | complete
    | get exit_code
    | if $in == 0 {
        rm $task_path -f;
        print -n '🔵'
    } else {
        print -n '⭕'
    }

    log debug $'run ($command)'
}

def 'inspect2' [
    callback?: closure
] {
    let $input = $in

    if $callback == null {
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
    ls (cy-path config)
    | sort-by modified
    | select name
    | where ($it.name | path parse | get extension) == 'toml'
    | upsert address {|i| open $i.name | get address}
    | sort-by name -r
    | upsert name {|i| $i.name | path parse | get stem}
    | rename value description
}

def 'nu-complete-git-branches' [] {
    ['main', 'dev']
}

def 'nu-complete-executables' [] {
    ['cyber' 'pussy']
}

# Helper function to use addresses for completions in --from parameter
def 'nu-complete keys values' [] {
    cyber keys list --output json | from json | select name address | rename description value
}

def 'nicks-and-keynames' [] {
    ^$env.cy.exec keys list --output json
    | from json
    | select name address
    | rename name neuron
    | upsert name {|i| $i.name + 🔑}
    | append (dict-neurons | select nickname neuron | rename name neuron | uniq-by name)
}

def 'nu-complete keys-nicks' [] {
    nicks-and-keynames
    | get name
    | where $it not-in [null '']
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
    let $prompt = if ($prompt | str ends-with '!') {
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

def 'error-make-cy' [
    msg: string
    --unspanned (-u) # remove the origin label from the error
] {
    {msg: (cprint --echo $msg)}
    | error make --unspanned $in
}

def 'cy-path' [
    ...segments: string
]: nothing -> path {
    [$env.cy.path]
    | append $segments
    | path join
}
