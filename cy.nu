# Cy - a tool for interactions with cybergraphs
# https://github.com/cyber-prophet/cy
#
# Use:
# > overlay use ~/cy/cy.nu -p -r

use std assert [equal greater]
use nu-utils [ bar, cprint, "str repeat", to-safe-filename, to-number-format, number-col-format,
    nearest-given-weekday, print-and-pass, clip, confirm, bar, normalize ]

use std log

export def main [] { help-cy }
# export def cy [] { help-cy }

export-env {
    # banner2
    let $tested_versions = ['0.91.0']

    version
    | get version
    | if $in not-in $tested_versions {
        cprint $'This version of Cy was tested on ($tested_versions), and you have ($in).
        We suggest you to use one of the tested versions. If you installed *nushell*
        using brew, you can update it with the command *brew upgrade nushell*'
    }

    let $config = (open_cy_config_toml)
    let $user_config_path = ($config.path | path join config $'($config.config-name? | default 'dummy').toml')

    $env.cy = (
        if ($user_config_path | path exists) {
            $config | merge ( open $user_config_path )
        } else {
            cprint $'A config file was not found. Run *cy config-new*'
            $config
        }
        | sort
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
    --only_hash         # calculate hash only, don't pin anywhere
    --dont_detect_cid   # work with CIDs as regular texts
    --follow_file_path  # check if `text_param` is a valid path, and if yes - try to open it
    --dont_save_particle_in_cache # don't save particle to local cache in cid.md file
]: [string -> string, nothing -> string] {
    let $text = (
        $in
        | default $text_param
        | into string
        | if (
            $env.cy.pin_text_follow_file_path? | default false | $in or $follow_file_path
        ) and (
            path-exists-safe $in
        ) {
            open
        } else {}
    )

    if not ($env.cy.pin_text_dont_detect_cid? | default false | $in or $dont_detect_cid) {
        if (is-cid $text) { return $text }
    }

    if ($env.cy.pin_text_only_hash? | default false | $in or $only_hash) {
        $text
        | ipfs add -Q --only-hash
        | str trim --char (char nl)
        | return $in
    }

    mut $cid = (
        if $env.cy.ipfs-storage in ['kubo' 'both'] {
            $text
            | ipfs add -Q
            | str trim --char (char nl)
        }
    )

    $cid = (
        if $env.cy.ipfs-storage in ['cybernode' 'both'] {
            $text
            | curl --silent -X POST -F file=@- 'https://io.cybernode.ai/add'
            | from json
            | get cid
        } else { $cid }
    )

    if not $dont_save_particle_in_cache {
        let $path = ($env.cy.ipfs-files-folder | path join $'($cid).md')

        if ($path | path exists | not $in) {
            $text | save -r $path
        }
    }

    $cid
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
    --quiet (-q)        # Don't output a cyberlink record after executing the command
    --only_hash         # calculate hash only, don't pin anywhere
    --dont_detect_cid   # work with CIDs as regular texts
    --follow_file_path  # check if `text_param` is a valid path, and if yes - try to open it
] [nothing -> record, nothing -> nothing] {
    $env.cy.pin_text_only_hash = ($env.cy.pin_text_only_hash? | default false ) or $only_hash
    $env.cy.pin_text_dont_detect_cid = ($env.cy.pin_text_dont_detect_cid? | default false ) or $dont_detect_cid
    $env.cy.pin_text_follow_file_path = ($env.cy.pin_text_follow_file_path? | default false ) or $follow_file_path

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
    ...rest: string # consecutive particles to cyberlink in a linkchain
]: [nothing -> table, list -> table] {
    let $elements = ($in | default $rest | flatten)
    let $count = ($elements | length)
    if $count < 2 {
        return $'($count) particles were submitted. We need 2 or more'
    }

    0..($count - 2) # The number of cid-paris to iterate through
    | each {
        |i| {from_text: ($elements | get $i), to_text: ($elements | get ($i + 1)) }
    }
    | links-pin-columns-2
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
    ...files: path          # filenames to pin to the local ipfs node
    --link_filenames (-n)   # Add filenames as a `from` link
    --include_extension     # Don't cut file extension (works only with --link_filenames)
    --disable_append (-D)   # Don't append links to the links table
    --quiet                 # Don't output results page
    --yes (-y)              # Confirm uploading files without request
]: [nothing -> table, nothing -> nothing] {
    if (ps | where name =~ ipfs | is-empty) {
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
    | if $yes or (confirm --default_not=true $in) { } else { return }

    let $results = (
        $files_col
        | par-each {|f| $f
            | upsert to_text $'pinned_file:($f.from_text)'
            | upsert to (ipfs add $f.from_text -Q | str replace (char nl) '')
            | if ($link_filenames) {
                if $include_extension {} else {
                    upsert from_text { $f.from_text | path parse | get stem }
                }
                | upsert from {|i| (pin-text $i.from_text)}
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
        link-files --link_filenames --yes --include_extension
    )

    cd ..;
    rm -r linkfilestest

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
    neuron: string          # neuron's address to follow
    --use_local_list_only   # follow a neuron locally only
]: [nothing -> record] {
    if not (is-neuron $neuron) {
        cprint $"*($neuron)* doesn't look like an address"
        return
    }

    $neuron | dict-neurons-add 'follow'

    if not $use_local_list_only {
        link-texts 'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx' $neuron
    }
}

#[test]
def test-follow [] {
    # use std assert equal
    equal {
        from_text: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx",
        to_text: "bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8",
        from: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx",
        to: "QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af"
    } (
        follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
    )
    equal (follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only) null
}

# Add a tweet and send it immediately (unless of disable_send flag)
#
# > cy links-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
# from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to_text: cyber-prophet is cool
# from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK
export def 'tweet' [
    text_to: string # text to tweet
    --disable_send (-D) # don't send tweet immideately, but put it into the temp table
]: [nothing -> record] {
    let $cid_from = 'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx' # pin-text 'tweet'

    if $disable_send {
        link-texts $cid_from $text_to
    } else {
        set-links-table-name $'tweet_(now-fn)'

        link-texts $cid_from $text_to;
        links-send-tx
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
def 'link-chuck' []: [nothing -> nothing] {
    let $quote = (
        http get -e https://api.chucknorris.io/jokes/random
        | get value
        | $in + "\n\n" + 'via [Chucknorris.io](https://chucknorris.io)'
    )

    cprint -f '=' --indent 4 $quote

    link-texts --quiet 'chuck norris' $quote
}

# Add a random quote cyberlink to the temp table
def 'link-quote' []: [nothing -> nothing] {
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
    --source: string@'nu-complete-random-sources' = 'forismatic.com' # choose the source to take random links from
]: [nothing -> nothing] {
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
    --no_timestamp # Don't output a timestamps column
]: [nothing -> table] {
    let $filename = (current-links-csv-path)
    let $links = (
        $filename
        | if ($in | path exists) {
            open
            | if $no_timestamp { reject timestamp } else {}
        } else {
            []
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
    --quiet (-q) # don't output the resulted temp links table
]: [table -> table, table -> nothing, record -> table, record -> nothing] {
    $in
    | upsert timestamp (now-fn)
    | prepend (links-view -q)
    | if $quiet { links-replace -q } else { links-replace }
}

# Replace the temp table with piped-in table
export def 'links-replace' [
    --quiet (-q) # don't output the resulted temp links table
]: [table -> table, table -> nothing] {
    $in
    | save (current-links-csv-path) --force

    if (not $quiet) { links-view -q }
}

# Swap columns from and to
export def 'links-swap-from-to' [
    --dont_replace (-D)     # don't replace the temp cyberlinks table, just output results
    --keep_original         # append results to original links
]: [nothing -> table, table -> table] {
    let $input = (inlinks-or-links)

    $input
    | rename --block {
        if ($in | str starts-with 'from') {
            str replace 'from' 'to'
        } else {
            str replace 'to' 'from'
        }
    }
    | if $keep_original {
        prepend $input
    } else { }
    | if $dont_replace { } else {
        links-replace
    }
}

# Empty the temp cyberlinks table
export def 'links-clear' []: [nothing -> nothing] {
    $'from_text,to_text,from,to,timestamp(char nl)'
    | save --force (current-links-csv-path | backup-and-echo --mv)
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
        [cyber, bostrom, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
            "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        [cyber-prophet, 🤘, "QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD",
            "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        [tweet, "cy is cool!", "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx",
            "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    links-link-all 'cy testing script'
    equal (
        links-view --no_timestamp
    ) [
        [from_text, to_text, from, to];
        ["cy testing script", bostrom, "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx",
            "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        ["cy testing script", 🤘, "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx",
            "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        ["cy testing script", "cy is cool!", "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx",
            "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    config-activate 42gboot+cyber

    link-random 3
    link-random 3 --source forismatic.com
    links-remove-existed-1by1

    equal (links-send-tx | get code) 0
}

# Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table
#
# > [[from_text, to_text]; ['cyber-prophet' null] ['tweet' 'cy is cool!']]
# | cy links-pin-columns | cy links-link-all 'master' --column 'to' --empty | to yaml
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
    --keep_original         # append results to original links
    --column (-c): string = 'from'  # a column to use for values ('from' or 'to'). 'from' is default
    --empty                 # fill cids in empty cells only
]: [nothing -> table, table -> table] {
    let $links = (inlinks-or-links)
    let $cid = (pin-text $text)

    $links
    | if $empty {
        each {
            if ( $in | get $column -i | is-empty ) {
                upsert $column $cid
                | upsert $'($column)_text' $text
            } else { }
        }
    } else {
        upsert $column $cid
        | upsert $'($column)_text' $text
    }
    | if $keep_original { prepend $links } else {}
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
]: [nothing -> table, table -> table] {
    let $links = (inlinks-or-links)

    let $dict = (
        $links.from_text?
        | append $links.to_text?
        | where $it not-in [null '']
        | if $in == [] {
            cprint 'No columns *"from_text"* or *"to_text"* found. Add at least one of them.' ;
            return
        } else {}
        | uniq
        | par-each -t $threads {|i| {$i: (pin-text $i)}}
        | reduce -f {} {|it acc| $acc | merge $it }
    )

    $links
    | each {|i| $i
        | if $i.from_text? != null {
            upsert from ( $dict | get -is $i.from_text )
        } else {}
        | if $i.to_text? != null {
            upsert to ( $dict | get -is $i.to_text )
        } else {}
    }
    | if $dont_replace {} else { links-replace }
}

export def 'links-pin-columns-2' [
    --dont_replace (-D) # Don't replace the links cyberlinks table
    --pin_to_local_ipfs       # Pin to local kubo
    --dont_detect_cid         # work with CIDs as regular texts
    --dont_save_particle_in_cache # don't save particles to local cache in cid.md file
]: [nothing -> table, table -> table] {
    let $links = (inlinks-or-links)

    let $temp_ipfs_folder = (cy-path temp ipfs_upload | path join (now-fn))
    mkdir $temp_ipfs_folder

    let $groups = (
        $links.from_text?
        | append $links.to_text?
        | where $it != null
        | if $in == [] {
            cprint 'No columns *"from_text"* or *"to_text"* found. Add at least one of them.' ;
            return
        } else {}
        | uniq
        | if $dont_detect_cid {} else {
            group-by {if (is-cid $in) {'cid'} else {'not-cid'}}
        }
    )

    let $lookup = (
        $groups
        | if $dont_detect_cid {} else {
            get not-cid
        }
        | enumerate
        | into string index
    )

    # Saving ininitial text files
    $lookup | each {|i| $i.item | save -r ($temp_ipfs_folder | path join $i.index)}

    cprint $'temp files saved to a local directory *($temp_ipfs_folder)*'

    mut $hash_associations = (
        if ($pin_to_local_ipfs) or (confirm $'Pin files to local kubo? If `no` only hashes will be calculated.') {
            ipfs add -r $temp_ipfs_folder
        } else {
            ipfs add -rn $temp_ipfs_folder
        }
        | lines
        | drop # remove the root folder's cid
        | parse '{s} {cid} {path}'
        | upsert index {|i| $i.path | path basename}
        | join -l $lookup index
        | select cid item
    );

    if not $dont_save_particle_in_cache {
        $hash_associations
        | each {|i|
            let $path = ($env.cy.ipfs-files-folder | path join $'($i.cid).md')
            if ($path | path exists | not $in) {
                $i.item | save $path
            }
        }
    }

    if ((not $dont_detect_cid) and ($groups.cid? != null)) {
        $hash_associations = (
            $groups.cid | wrap cid
            | merge ($groups.cid | wrap item)
            | append $hash_associations
        )
    }

    $links
    | reject -i from to # if text_from or text_to are absent, the resulting table is empty. Mabye use default?
    | join -l ($hash_associations | rename from from_text) from_text
    | join -l ($hash_associations | rename to to_text) to_text
    | if $dont_replace {} else { links-replace }
}

export def 'pin-file-or-folder-to-cybernode' [
    $path: path # the path to a folder or a file to pin
] {
    $env.cy.ipfs-storage = 'cybernode'

    let $paths = (
        match ($path | path type) {
            'dir' => {glob ($path | path join '*')}
            'file' => {[$path]}
            _ => {error make {msg: $'($path) is not a dir or a file'}}
        }
    )

    let $paths_length = $paths | length

    $paths
    | enumerate
    | par-each {|i|
        open -r $i.item | pin-text;
        print -n $'(char cr)($i.index)/($paths_length)'
    }

    print ''
}

# Check if any of the links in the links table exist
#
# > let $from = 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufA'
# > let $to = 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufB'
# > let $neuron = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
# > cy link-exist $from $to $neuron
# false
def 'link-exist' [
    from: string # particle from
    to: string # particle to
    neuron: string # neuron to check
]: [nothing -> bool] {
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
export def 'links-remove-existed-1by1' [
    --all_links # check all links in the temp table
]: [nothing -> table, nothing -> nothing] {
    let $links_view = (links-view -q)
    let $links_per_trans = (set-or-get-env-or-def --dont_set_env links-per-transaction)

    let $links_with_status = (
        $links_view
        | if $all_links {} else {
            print-and-pass {|l|
                if ($l | length | $in > $links_per_trans) {
                    cprint $'Only first ($links_per_trans) links are to be checked.
                        Add the *--all_links* flag to check them all.'
                }
            }
            | first $links_per_trans }
        | merge ($in | length | seq 0 $in | wrap index)
        | par-each {|i| $i
            | upsert link_exist {
                |row| print $row.index;
                (link-exist $row.from $row.to $env.cy.address)
            }
        }
        | sort-by index
    )

    let $existed_links = (
        $links_with_status
        | where link_exist?
    )

    let $existed_links_count = ($existed_links | length)

    if $existed_links_count > 0 {
        cprint $'*($existed_links_count) cyberlinks* was/were already created by *($env.cy.address)*'

        ($existed_links | select -i from_text from to_text to | each {|i| print $i})

        cprint -c red -a 2 'So they were removed from the temp table!'

        $links_with_status
        | where link_exist? != true
        | if $all_links {} else {
            append ($links_view | skip $links_per_trans)
        }
        | links-replace
    } else {
        cprint 'There are no cyberlinks in the temp table for the current address exist the cybergraph'
    }
}

# Remove existing links using graph snapshot data
export def 'links-remove-existed-2' [] {
    graph-receive-new-links

    let $existing_links = (
        graph-links-df
        | dfr filter-with ((dfr col neuron) == $env.cy.address)
        | dfr select particle_from particle_to
        | dfr with-column (dfr lit true | dfr as duplicate)
        | dfr into-lazy
    )


    links-view
    | dfr into-lazy
    | dfr join --left $existing_links [from to] [particle_from particle_to]
    | dfr filter-with (dfr col duplicate | dfr is-not-null)
    | dfr drop duplicate
    | dfr collect
    | dfr into-nu
    | reject index
    | links-replace
}


# Create a custom unsigned cyberlinks transaction
def 'tx-json-create-from-cyberlinks' [
    $links # removed type definition for the case of empty tables
] {
    let $links2 = ( $links | select from to | uniq )
    let $path = (cy-path temp tx-unsigned.json)

    tx-message-links $env.cy.address $links2
    | tx-create $in
    | save $path --force;

    $path
}

def 'tx-message-investmint' [
    neuron: string
    --h_amount: int
    --resource: string
    --length: int
] {
    {
        @type: "/cyber.resources.v1beta1.MsgInvestmint",
        neuron: $neuron,
        amount: {
            denom: hydrogen,
            amount: ($h_amount | int string)
        },
        resource: $resource,
        length: ($length | into string)
    }
}

def 'tx-message-links' [
    $neuron
    $links_table: table<from: string, to: string> # [[from, to]; ["", ""]]
] {
    { @type: "/cyber.graph.v1beta1.MsgCyberlink",
    neuron: $neuron,
    links: $links_table }
}

def 'tx-create' [
    message?
    --memo: string = 'cy'
    --gas = 23456789
    --fee = 2000
    --timeout_height = 0
] {
    let msg = (
        ($message | describe)
        | if ($in =~ '^list') {
            $message
        } else if ($in =~ '^record') {
            [$message]
        } else {
            error make {msg: $'Message should be record or list. Received ($in)'}
        }
    )

    {
        body: {
            messages: $msg,
            memo: $memo,
            timeout_height: ($timeout_height | into string),
            extension_options: [],
            non_critical_extension_options: []
        },
        auth_info: {
            signer_infos: [],
            fee: {
                amount: [ {denom: boot, amount: ($fee | into string)} ],
                gas_limit: ($gas | into string),
                payer: "",
                granter: ""
            }
        }, signatures: []
    }
}

def 'tx-authz' [
    $json_tx_path: path
] {
    let $out_path = (cy-path temp tx-unsigned-authz.json)

    let $current_json = (open $json_tx_path)

    $current_json
    | upsert body.messages.neuron $env.cy.authz
    | upsert body.messages {|i| [ {
        "@type": "/cosmos.authz.v1beta1.MsgExec",
        "grantee": ($current_json | get body.messages.neuron.0)
        "msgs": $i.body.messages
    } ] }
    | to json -r
    | save -rf $out_path

    $out_path
}

def 'tx-sign' [
    $unsigned_tx_path: path
] {
    let $out_path = (cy-path temp tx-signed.json)
    let $params = (
        [
            --from $env.cy.address
            --chain-id $env.cy.chain-id
            --node $env.cy.rpc-address
            --output-document $out_path
        ]
        | if $env.cy.keyring-backend? == 'test' {
            append ['--keyring-backend' 'test']
        } else {}
    )

    let $response = (
        do {^($env.cy.exec) tx sign $unsigned_tx_path ...$params}
        | complete
    )

    if $response.exit_code != 0 {
        $response.stderr
        | lines
        | first
        | error make --unspanned {msg: $in}
    }

    $out_path
}

def 'tx-broadcast' [
    $signed_tx_path
] {
    (
        ^($env.cy.exec) tx broadcast $signed_tx_path
        --broadcast-mode block
        --output json
        --node $env.cy.rpc-address
        | complete
        | if ($in.exit_code != 0 ) {
            error make { msg: 'exit code is not 0' }
        } else {
            get stdout | from json | select raw_log code txhash
        }
    )
}

# Create a tx from the piped in or temp cyberlinks table, sign and broadcast it
#
# > cy links-send-tx | to yaml
# cy: 2 cyberlinks should be successfully sent
# code: 0
# txhash: 9B37FA56D666C2AA15E36CDC507D3677F9224115482ACF8CAF498A246DEF8EB0
def 'links-send-tx' [ ] {
    let $links = links-view -q | first (
        set-or-get-env-or-def links-per-transaction
    )

    let $response = (
        tx-json-create-from-cyberlinks $links
        | if ($env.cy.authz? != null) {
            tx-authz $in
        } else {}
        | tx-sign $in
        | tx-broadcast $in
    )

    let $filename = (cy-path mylinks _cyberlinks_archive.csv)
    if $response.code == 0 {
        open $filename
        | append ( $links | upsert neuron $env.cy.address )
        | save $filename --force

        links-view -q | skip (
            set-or-get-env-or-def links-per-transaction
        ) | links-replace

        {'cy': $'($links | length) cyberlinks should be successfully sent'}
        | merge $response
        | select cy code txhash

    } else {
        print $response

        if $response.raw_log == 'not enough personal bandwidth' {
            print (query-links-bandwidth-neuron $env.cy.address)
            error make --unspanned {msg: (cprint --echo 'Increase your *Volts* balance or wait time.')}
        }
        if $response.raw_log =~ 'your cyberlink already exists' {
            error make --unspanned {msg: (cprint --echo 'Use *cy links-remove-existed-2*')}
        }

        cprint 'The transaction might be not sent.'
    }
}

def 'links-prepare-for-publishing' [] {
    let $links = (inlinks-or-links)

    let $filtered = (
        $links
        | where (is-cid ($it.from? | default ''))
        | where (is-cid ($it.to? | default ''))
        | where $it.from != $it.to
        | uniq-by from to
    )

    let $filtered_length = $filtered | length
    let $diff_length = ($links | length) - ($filtered_length)
    if $diff_length > 0 {
        cprint $'*($diff_length)* links from initial data were removed, because they were obsolete'
    }
    if $filtered_length == 0 {
        error make ( cprint --err_msg $'there are no cyberlinks to publish' )
    }

    $filtered
}

# Publish all links from the temp table to cybergraph
export def 'links-publish' [
    --links_per_trans: int
] {
    links-view -q
    | links-prepare-for-publishing
    | links-replace
    | length
    | $in // (set-or-get-env-or-def links-per-transaction $links_per_trans)
    | seq 0 $in
    | each {links-send-tx}
}

def 'inlinks-or-links' []: [nothing -> table, table -> table] {
    $in
    | if $in == null {links-view -q} else {}
    | fill non-exist -v null
}

# Copy a table from the pipe into the clipboard (in tsv format)
export def 'tsv-copy' [] {
    $in | to tsv | clip --no-notify --silent --no-strip
}

# Paste a table from the clipboard to stdin (so it can be piped further)
export def 'tsv-paste' [] {
    pbpaste | from tsv
}

# Update Cy and Nushell to the latest versions
export def 'update-cy' [
    --branch: string@'nu-complete-git-branches' = 'dev' # the branch to get updates from
] {
    # check if nushell is installed using brew
    if (brew list nushell | complete | get exit_code | $in == 0) {
        brew upgrade nushell;
    } else {
        if (which cargo | length | $in > 0) {
            cargo install --features=dataframe nu
        }
    }

    cd $env.cy.path;
    git stash
    git checkout $branch
    git pull
    git stash pop
    cd -
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
            {"active_passport":{"address":$address_or_nick}}
        } else {
            {"passport_by_nickname":{"nickname":$address_or_nick}}
        }
        | to json -r
    )

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    let $params = ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']

    ( caching-function query wasm contract-state smart $pcontract $json $params
        --retries 0 --exec 'cyber' --no_default_params )
    | if $in == null {
        if not $quiet { # to change for using $env
            cprint --before 1 --after 2 $'No passport for *($address_or_nick)* is found'
        }; return {nickname: '?'}
    } else {
        get data
        | merge $in.extension
        | reject extension approvals token_uri
    }
}

#[test]
def passport-get-test [] {
    equal (passport-get bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel) {nickname: ?}
    equal (passport-get bostrom1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa) {nickname: ?} # unexisting address
    equal (passport-get bostrom1de53jgxjfj5n84qzyfd7z44m9wrudygt524v6r | get nickname) 'graphkeeper'
}

# Set a passport's particle, data or avatar field for a given nickname
#
# > cy passport-set QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
# The particle field for maxim should be successfuly set to QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
export def 'passport-set' [
    cid: string                     # cid to set
    nickname?                       # Provide a passport's nickname. If null - the nick from config will be used.
    --field: string = 'particle'    # A passport's field to set: particle, data, new_avatar
    --verbose                       # Show the node's response
] {
    if not (is-cid $cid) {
        print $"($cid) doesn't look like a cid"
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

    let $json = $'{"update_data":{"nickname":"($nick)","($field)":"($cid)"}}'

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
            cprint $'The *($field)* field for *($nick)* should be successfuly set to *($cid)*'
        }
    } else {
        cprint $'The cid might not be set. You can check it with the command
        "*cy passport-get ($nick) | get ($field) | $in == ($cid)*"'
    }
}

# Output neurons dict
export def 'dict-neurons-view' [
    --df        # output as a dataframe
    --path      # output path of the dict
    --karma_bar # output karma bar
] {
    let $neurons_tags = (dict-neurons-tags --wide)

    (cy-path graph neurons_dict.yaml)
    | if $path {
        return $in
    } else {}
    | if ($in | path exists) {
        open $in
    } else { [[neuron nickname];
        ['bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8' 'maxim']] }
    | reject -i ...($neurons_tags | columns | where $it != 'neuron')
    | join --outer $neurons_tags neuron
    | if $karma_bar {
        default 0 karma
        | into float karma
        | normalize karma
        | upsert karma_norm_bar {|i| bar $i.karma_norm --width ('karma_norm_bar' | str length)}
        | move karma_norm karma_norm_bar --after karma
    } else {}
    | if $df {
        fill non-exist
        | reject -i addresses # quick fix for failing df conversion
        | to yaml
        | str replace -a 'null' "''" # dataframes errors on `object` type columns (that contains nulls)
        | from yaml
        | dfr into-df
    } else { }
}

#[test]
def dict-neurons-view-test-dummy [] {
    equal (dict-neurons-view; null) null
    equal (dict-neurons-view --df; null) null
    equal (dict-neurons-view --path) (cy-path graph neurons_dict.yaml)
}

# Add piped in neurons to YAML-dictionary with tag and category
export def 'dict-neurons-add' [
    tag: string = ''    # tag to add to neuron
    --category: string = 'default' # category of tag to write to dict
] {
    let $input = $in
    let $desc = ($input | describe)
    let $path_csv = (cy-path graph neurons_dict_tags.csv)

    if $input == null {
        error make {
            msg: 'you should pipe a list, a table or a dataframe containg `neuron` column to this command'
        }
    }

    let $candidate = (
        $input
        | if ($desc == 'list<string>') {
            wrap neuron
        } else if ($desc == 'dataframe') {
            dfr into-nu
        } else if ($desc == 'string') {
            [{neuron: $in}]
        } else { }
        | select neuron
    )

    let $validated_neurons = (
        $candidate
        | where (is-neuron $it.neuron)
    )

    $validated_neurons
    | upsert tag $tag
    | upsert category $category
    | upsert timestamp (date now | debug)
    | if ($path_csv | path exists) {
        to csv --noheaders
    } else {
        to csv
    }
    | save -ra $path_csv
}

# Ouput dict-neurons tags
export def 'dict-neurons-tags' [
    --path      # return the path of tags file
    --wide      # return wide table with categories as columns
    --timestamp # output the timestamp of the last neuron's update
] {
    let $path_csv = (cy-path graph neurons_dict_tags.csv)
    if $path { return $path_csv }

    if not ($path_csv | path exists) {
        [[neuron, tag, category, timestamp];
        ["bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8", follow, default, (date now | debug)]]
        | if $timestamp {} else {reject -i timestamp}
        | save $path_csv
    }

    open $path_csv
    | if $wide {
        reject -i timestamp
        | uniq-by neuron category
        | group-by category
        | items {|k v| $v | reject category | rename neuron $k}
        | reduce {|i acc| $acc | join --outer $i neuron}
    } else {}
}

# Fix some problems of cy (for example caused by updates)
export def 'doctor' [] {
    # fix column names in neurons_dict_tags (change introduced on 20231226)
    let $dict_n_tags_path = (cy-path graph neurons_dict_tags.csv)

    $dict_n_tags_path
    | if ($in | path exists) {
        open
        | if ($in | columns | 'value' in $in) {
            rename -c {value: tag}
            | save -f $dict_n_tags_path;

            print $'($dict_n_tags_path) updated'
        }
    }
}

# Update neurons YAML-dictionary
export def 'dict-neurons-update' [
    --passport              # Update passport data
    --balance               # Update balances data
    --karma                 # Update karma
    --all (-a)              # Update passport, balance, karma
    --neurons_from_graph    # Update info for neurons from graph, and not from current dict
    --threads (-t) = 30     # Number of threads to use for downloading
    --dont_save             # Don't update the file on a disk, just output the results
    --quiet (-q)            # Don't output results table
] {
    if $neurons_from_graph {
        graph-links-df
        | dfr select neuron
        | dfr unique
        | dfr join --left (dict-neurons-view --df) neuron neuron
        | dfr into-nu
        | reject index
    } else {
        dict-neurons-view
    }
    | filter {|i| is-neuron $i.neuron}
    | if $passport or $all {
        par-each -t $threads {|i|
            $i | merge (passport-get $i.neuron --quiet | reject -i 'owner')
        }
    } else {}
    | if $balance {
        par-each -t $threads {|i|
            $i | merge (
                tokens-balance-get $i.neuron
                | transpose -idr
            )
        }
    } else {}
    | if $karma or $all { # kamra_norm is calculated below
        par-each -t $threads {|i|
            $i | merge (query-rank-karma $i.neuron)
        }
    } else {}
    | par-each {
        upsert nick {|i|
            [
                ($i.my_alias? | if $in in [null ''] {null} else {$in + '_'})
                ($i.nickname?) # no nickname were parsed
                '@'
                ($i.neuron | str substring (-7..))
            ]
            | where $it not-in [null '']
            | str join
        }
    }
    | if $dont_save {} else {
        let $input = $in

        dict-neurons-view
        | prepend $input
        | uniq-by neuron
        | save -f (cy-path graph neurons_dict.yaml | backup-and-echo);

        $input
    }
    | if $quiet { null } else { }
}

# Download a snapshot of cybergraph
export def --env 'graph-download-snapshot' [
    --disable_update_parquet (-D)   # Don't update the particles parquet file
    --neuron: string = 'graphkeeper'
] {
    make_default_folders_fn

    set-cy-setting caching-function-force-update 'true'
    let $cur_data_cid = (passport-get $neuron | get data -i)
    set-cy-setting caching-function-force-update 'false'
    let $path = (cy-path graph $neuron)

    mkdir $path

    let $update_info = (
        $path
        | path join update.toml
        | if ($in | path exists) {open} else {{}}
    )
    let $last_data_cid = ($update_info | get -i last_cid)

    if ($last_data_cid == $cur_data_cid) {
        print 'no updates found'
        return
    }

    print '' 'Downloading cyberlinks.csv'
    ipfs get $'($cur_data_cid)/graph/cyberlinks.csv' -o $path

    # print '' 'Downloading cyberlinks.csv'
    # ipfs get $'($cur_data_cid)/graph/cyberlinks_contracts.csv' -o $path

    let $dict_name = 'neurons_dict.yaml'
    let $dict_path = ($path | path join neurons_dict.yaml)
    print '' $'Downloading ($dict_name)'

    (
        ipfs cat $'($cur_data_cid)/graph/neurons_dict.yaml'
        | from yaml
        | if ($dict_path | path exists) {
            prepend (open $dict_path)
            | uniq-by neuron
        } else {}
        | save -f $dict_path
    )

    print '' 'Downloading particles zips'
    ipfs get $'($cur_data_cid)/graph/particles/' -o $'($path)/particles_arch/'

    let $archives = (ls ($path | path join particles_arch/*.zip | into glob) | get name)
    let $last_archive = (
        $update_info
        | get -i last_archive
        | default ($archives | first)
    )

    cprint 'Unpacking particles archive(s)'
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

    # if (not $disable_update_parquet) {
    #     print 'Updating particles parquet'
    #     graph-update-particles-parquet
    # }
}

#[test]
def graph-download-snapshot-test-dummy [] {
    equal (graph-download-snapshot; null) null
}

def graph_columns [] {
    ['particle_from' 'particle_to' 'neuron' 'height' 'timestamp']
}

def get_links_hasura [
    height: int
    multiplier: int
    --chunk_size: int = 1000
] {
    let $graphql_api = (set-or-get-env-or-def 'indexer-graphql-endpoint')

    $"{cyberlinks\(limit: ($chunk_size), offset: ($multiplier * $chunk_size), order_by: {height: asc},
        where: {height: {_gt: ($height)}}) {(graph_columns | str join ' ')}}"
    | {'query': $in}
    | http post -t application/json $graphql_api $in
    | get data.cyberlinks
}

def 'get_links_clickhouse' [
    height: int
    multiplier: int
] {
    let $url = (set-or-get-env-or-def 'indexer-clickhouse-endpoint')
    let $auth = (set-or-get-env-or-def 'indexer-clickhouse-auth')
    let $chunk_size = (set-or-get-env-or-def 'indexer-clickhouse-chunksize')

    $'SELECT particle_from, particle_to, neuron, height, timestamp
        FROM spacebox.cyberlink
        WHERE height > ($height)
        ORDER BY height
        LIMIT ($chunk_size)
        OFFSET ($chunk_size * $multiplier)
        FORMAT TSVWithNames'
    | curl -s $url -H 'Accept-Encoding: gzip' -u $auth --data-binary @-
    | gunzip -c
    | from tsv
}

def graph_csv_get_last_height [
    path_csv: path
] {
    if ($path_csv | path exists) {
        (open $path_csv -r | lines | first)
        | append (tail -n 1 ($path_csv))
        | str join (char nl)
        | from csv
        | get height.0
        | into int
    } else {
        (graph_columns | str join ',') + (char nl) # csv headers
        | save -r $path_csv;

        0
    }
}

# Download the latest cyberlinks from a hasura cybernode endpoint
export def 'graph-receive-new-links' [
    filename?: string@'nu-complete-graph-csv-files' # graph csv filename in the 'cy/graph' folder
    --source: string@'nu-complete-graph-provider' = 'hasura'
] {
    let $cyberlinks_path = (set-or-get-env-or-def cyberlinks-csv-table $filename)
    let $path_csv = (cy-path graph $cyberlinks_path)
    let $last_height = (graph_csv_get_last_height $path_csv)

    mut $new_links_count = 0

    cprint $'Downloading using ($source)'

    for $mult in 0.. {
        let $links = (
            if $source == 'hasura' {
                get_links_hasura $last_height $mult
            } else if $source == 'clickhouse' {
                get_links_clickhouse $last_height $mult
            }
        )

        $new_links_count += ($links | length)

        if $links != [] {
            $links | to csv --noheaders | save -ra $path_csv

            cprint -a 0 $'(char cr)Since the last update (char lp)which was on ($last_height
                ) height(char rp) ($new_links_count) cyberlinks recieved!'
        } else {
            break
        }
    }
    print ''
}

#[test]
def graph-receive-new-links-test-dummy [] {
    equal (graph-receive-new-links; null) null
}

# download particles missing from local cache for followed neurons or the whole graph
export def 'graph-download-missing-particles' [
    --dont_update_parquet
    --whole_graph # download particles for whole graph
] {
    if not $dont_update_parquet {
        graph-update-particles-parquet
    }

    graph-receive-new-links

    let $follow_list = (dict-neurons-tags | where tag == follow | get neuron)
    let $block_list = (dict-neurons-tags | where tag == block | get neuron)

    let $particles = (
        graph-links-df
        | if $whole_graph {} else {
            if ($follow_list | is-empty) {
                let $input = $in;

                cprint "You don't have any neurons tagged `follow`, so we'll download only missing particles that
                `maxim` (the hot key of `cyber-prophet`). If you want to download all the missing particles for
                the whole cybergraph you can use the command: *graph-download-missing-particles --whole_graph*.
                If you want to add tag `follow` to some neurons you can use the command:
                *'bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8' | dict-neurons-add follow*";

                $input
                | dfr filter-with (
                    (dfr col neuron)
                    | dfr is-in ['bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8']
                )
            } else {
                dfr filter-with (
                    (dfr col neuron)
                    | dfr is-in $follow_list
                )
            }
        }
        | if ($block_list | is-empty) {} else {
            dfr filter-with ((dfr col neuron) | dfr is-in $block_list | dfr expr-not)
        }
        | graph-to-particles
        | graph-add-metadata
        | particles-filter-by-type --timeout
        | print-and-pass
        | dfr select particle
        | dfr into-nu
        | get particle
    )

    $particles | each {queue-cid-add $in}

    cprint --before 1 $'($particles | length) cids are added into queue'

    queue-cids-download
}

# filter system particles out
export def 'graph-filter-system-particles' [
    column = 'particle' # the column to look for system cids
    --exclude
] {
    dfr filter-with (
        (dfr col $column)
        | dfr is-in (system_cids)
        | if $exclude {dfr expr-not} else {}
    )
}

# merge two graphs together, add the `source` column
export def 'graph-merge' [
    df2
    --source_a: string = 'a'
    --source_b: string = 'b'
] {
    let $input = if ($in | dfr columns | 'source' in $in) { } else {
        dfr with-column (dfr lit $source_a | dfr as source)
    }

    let $df2_st = (
        $df2
        | if ($df2 | dfr columns | 'source' in $in) { } else {
            dfr with-column (dfr lit $source_b | dfr as source)
        }
    )

    $input
    | dfr join $df2_st [particle_from particle_to neuron] [particle_from particle_to neuron] --outer
    | dfr with-column (
        dfr when ((dfr col source) | dfr is-null) (dfr col source_x)
        | dfr when ((dfr col source_x) | dfr is-null) (dfr col source)
        | dfr otherwise (dfr concat-str '-' [(dfr col source) (dfr col source_x)])
        | dfr as source
    )
    | dfr with-column (
        dfr when ((dfr col height) | dfr is-null) (dfr col height_x)
        | dfr otherwise (dfr col height) | dfr as height
    )
    | dfr with-column (
        dfr when ((dfr col timestamp) | dfr is-null) (dfr col timestamp_x)
        | dfr otherwise (dfr col timestamp) | dfr as timestamp
    )
    | dfr drop height_x timestamp_x source_x
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
    --include_global        # Include column with global particles' df (that includes content)
    --include_particle_index         # Include local 'particle_index' column
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
export def 'particles-keep-only-first-neuron' [ ] {
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
    --quiet (-q)    # don't print info about the saved parquet file
    --all           # re-read all downloaded particles
] {
    let $parquet_path = cy-path graph particles.parquet
    let $particles_folder = $env.cy.ipfs-files-folder
    let $all_particles = (
        graph-links-df
        | graph-to-particles
        | graph-add-metadata
        | dfr select [particle neuron height timestamp content_s]
    )

    let $particles_wanted = (
        $all_particles
        | if $all {} else {
            particles-filter-by-type --timeout
        }
    )

    if not $quiet {
        cprint $'Cy is updating ($parquet_path). It will take a coulple of minutes.'
    }

    let $particles_on_disk = (glob ($particles_folder | path join '*.md') | path basename)

    let $particles_to_open = (
        $particles_wanted
        | dfr with-column ((dfr concat-str '.' [(dfr col particle) (dfr lit 'md')]) | dfr as name)
        | dfr join ($particles_on_disk | wrap name | dfr into-df) name name
        | dfr select name
        | dfr into-nu
        | select name
    )

    let $downloaded_particles = (
        $particles_to_open
        | upsert content_s {
            |i| open -r ($particles_folder | path join $i.name)
            | str substring -g 0..160
        }
        | dfr into-df
        | dfr with-column (
            $in.name
            | dfr str-slice 0 -l 46
        )
        | dfr rename name particle
        | dfr with-column (
            $in.content_s
            | dfr str-slice 0 -l 150
            | dfr replace-all -p (char nl) -r '⏎'
        )
    )

    (
        $particles_wanted
        | dfr drop 'content_s'
        | dfr join --left $downloaded_particles particle particle
        | dfr with-column (
            $in.content_s
            | dfr fill-null 'timeout|'
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
        | if $all {} else {
            dfr append -c (
                $all_particles
                | particles-filter-by-type --exclude --timeout
            )
        }
        | dfr sort-by height
        | dfr to-parquet ($parquet_path | backup-and-echo --mv)
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
    | dfr join ( dict-neurons-view --df ) '0' nick
    | dfr select neuron
    | dfr join ( $links ) neuron neuron
}

# Filter the graph to keep or exclude links from contracts
export def 'graph-filter-contracts' [
    --exclude
] {
    graph-links-df
    | dfr filter-with (
        $in.neuron =~ '.{64}'
        | if $exclude {dfr not} else {}
    )
}

# Append related cyberlinks to the piped in graph
export def 'graph-append-related' [
    --only_first_neuron (-o)
] {
    let $links_in = (
        $in | graph-select-standard-columns --extra_columns ['link_local_index' 'init-role' 'step']
    )
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
        | graph-to-particles
        | if $only_first_neuron {
            particles-keep-only-first-neuron
        } else {}
        | dfr into-lazy
        | dfr select particle link_local_index init-role step
        | dfr rename particle $'particle_($from_or_to)'
        | dfr join (
            graph-links-df --not_in
            | graph-filter-system-particles particle_from --exclude
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
            (dfr col timestamp | dfr count | dfr as 'links_count')
            (dfr col timestamp | dfr min | dfr as 'first_link')
            (dfr col timestamp | dfr max | dfr as 'last_link')
        ]
        | dfr sort-by links_count --reverse [true]  # cygraph neurons activity
        | dfr join --left $followers neuron neuron
        | dfr join --left $follows neuron neuron
        | dfr join --left $tweets neuron neuron
        | dfr fill-null 0
        | dfr join --left ( dict-neurons-view --df --karma_bar) neuron neuron
        | dfr select ($in | dfr columns | prepend [nickname links_count last_link] | uniq)
    )
}

# Output graph stats based on piped in or the whole graph
export def 'graph-stats' [] {
    let $links = (graph-links-df | dfr with-column (dfr lit a | dfr as dummyc))
    let $p = (graph-particles-df)
    let $p2 = ($links | graph-to-particles | graph-add-metadata)

    def dfr_countrows [] {
        dfr with-column (dfr lit 1) | dfr select literal | dfr sum | dfr into-nu | get literal.0
    }

    let $n_links_unique = ($links | dfr into-lazy | dfr unique --subset [particle_from particle_to] | dfr collect
        | dfr_countrows)

    let $n_particles_unique = ($p2 | dfr_countrows)

    let $n_particles_not_downloaded = ($p2 | particles-filter-by-type --timeout | dfr_countrows)

    let $n_particles_non_text = ($p2 | dfr filter-with ($in.content_s =~ '^"MIME type"')
        | dfr_countrows)

    let $follows = (
        $links
        | dfr filter-with (
            (dfr col particle_from)
            | dfr is-in ['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx'] # follow
        )
        | dfr_countrows
    )

    let $tweets = (
        $links
        | dfr filter-with (
            (dfr col particle_from)
            | dfr is-in ['QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx'] # tweet
        )
        | dfr_countrows
    )

    let $stats_by_source = (
        if ($links | dfr columns | 'source' in $in) {
            $links
            | dfr group-by source
            | dfr agg [(dfr col source | dfr count | dfr as source_count)]
            | dfr sort-by source
            | dfr into-nu
            | reject index
            | transpose -idr
            | {source: $in}
        } else {{}}
    )

    (
        $links
        | dfr group-by dummyc
        | dfr agg [
            (dfr col neuron | dfr n-unique | dfr as 'neurons')
            (dfr col timestamp | dfr count | dfr as 'links')
            (dfr col timestamp | dfr min | dfr as 'first')
            (dfr col timestamp | dfr max | dfr as 'last')
        ]
        | dfr into-nu
        | reject index dummyc
        | get 0
        | {links: $in}
        | upsert neurons {|i| $i.links.neurons}
        | move neurons --before links
        | reject links.neurons
        | upsert links.unique $n_links_unique
        | upsert links.follows $follows
        | upsert links.tweets $tweets
        | upsert particles.unique $n_particles_unique
        | upsert particles.text ($n_particles_unique - $n_particles_not_downloaded - $n_particles_non_text)
        | upsert particles.nontext $n_particles_non_text
        | upsert particles.not_downloaded $n_particles_not_downloaded
        | merge $stats_by_source
    )
}

# Export a graph into CSV file for import to Gephi
export def 'graph-to-gephi' [] {
    let $links = (graph-links-df)
    let $particles = (
        $links
        | graph-to-particles --include_global
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
        | save -f (cy-path export !gephi_particles.csv)
    )
}

# Logseq export WIP
export def 'graph-to-logseq' [
    # --path: string
] {
    let $links = (graph-links-df | print-and-pass)
    let $particles = (
        $links
        | graph-to-particles --include_global
        | print-and-pass
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
    | graph-add-metadata
    # | dfr filter-with ($in.content_s | dfr is-null | dfr not)
    | dfr sort-by [link_local_index height]
    | dfr drop content_s neuron
    | dfr into-nu
    | reject index
    | do {|i| print ($i | get 0.init-role); $i} $in
    | each {|i| echo_particle_txt $i}
}

# Export piped-in graph to a CSV file in cosmograph format
export def 'graph-to-cosmograph' [] {
    graph-add-metadata
    | dfr rename timestamp time
    | dfr select ($in | dfr columns | prepend [content_s_from content_s_to] | uniq)
    | dfr into-nu
    | reject index
    | save -f (
        cy-path 'export' $'cybergraph-in-cosmograph(now-fn).csv'
        | print-and-pass {|i| cprint $'You can upload the file to *https://cosmograph.app/run* ($i)'}
    )
}

# Export piped-in graph into graphviz format
export def 'graph-to-graphviz' [
    --options: string = ''
    --preset: string@nu-complete-graphviz-presets = ''
] {
    let $graph = (
        graph-add-metadata --escape-quotes
        | dfr select 'content_s_from' 'content_s_to'
        | $in.content_s_from + ' -> ' + $in.content_s_to + ';'
        | dfr into-nu
        | rename index links
        | get links
        | str join (char nl)
        | "digraph G {\n" + $options + "\n" + $in + "\n}"
    )

    if $preset == '' { $graph } else {
        let $filename = date now
            | format date "%Y%m%d_%H%M%S"
            | cy-path export $'graphviz_($preset)_($in).svg'

        let $params = ['-Tsvg' $'-o($filename)']

        $graph | ^($preset) ...$params
        $filename
    }
}

def 'nu-complete-graphviz-presets' [] {
    [ 'sfdp', 'dot' ]
}
# Add content_s and neuron's nicknames columns to piped in or the whole graph df
#
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
    --escape-quotes
] {
    let $links = (
        graph-links-df
        | graph-select-standard-columns --extra_columns ['particle', 'link_local_index', 'init-role', 'step']
    )
    let $p = (
        graph-particles-df
        | dfr select particle content_s
        | if $escape_quotes {
            dfr with-column (
                $in.content_s
                | dfr replace-all --pattern '"' --replace '\"'
                | dfr replace-all --pattern '^(.*)$' --replace '"$1"'
            )
        } else {}
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
        | dfr fill-null 'timeout|'
        | dfr drop height
        | dfr append $links.height
        | if 'neuron' in $links_columns {
            dfr join --left (
                dict-neurons-view --df
                | dfr select neuron nick
            ) neuron neuron
        } else {}
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
    filename?: string@'nu-complete-graph-csv-files' # graph csv filename in the 'cy/graph' folder or a path to the graph
    --not_in            # don't catch pipe in
    --exclude_system    # exclude system particles in from column (tweet, follow, avatar)
] {
    let $input = $in
    let $input_type = ($input | describe)
    let $cyberlinks_path = (set-or-get-env-or-def cyberlinks-csv-table $filename)

    if ($not_in or ($input_type == 'nothing')) {
        return (graph-open-csv-make-df (cy-path graph $cyberlinks_path))
    }

    let $df = (
        $input
        | if ($input_type =~ '^table') {
            dfr into-df
        } else if ($input_type in ['dataframe' 'lazyframe']) {
        } else {
            error make {msg:$'unknown input ($input_type)'}
        }
    )

    let $df_columns = ($df | dfr columns)
    let $existing_graph_columns = ($df_columns | where $it in [particle_from particle_to neuron])

    if (
        ($existing_graph_columns | length | $in == 3)
        or ('particle' in $df_columns)
    ) {
        $df
    } else {
        graph-open-csv-make-df (cy-path graph $cyberlinks_path)
        | dfr join --inner $df $existing_graph_columns $existing_graph_columns
    }
}


def 'graph-select-standard-columns' [
    standard_columns: list = [particle_from, particle_to, neuron, height, timestamp]
    --extra_columns: list = []
] {
    let $input = $in
    let $in_columns = ($input | dfr columns)
    let $out_columns = ($in_columns | where $it in ($standard_columns | append $extra_columns))

    $input
    | dfr select $out_columns
}

def 'graph-open-csv-make-df' [
    path: path
    --datetime
] {
    dfr open $path --infer-schema 10000
    | if $datetime {
        dfr with-column (
            $in.timestamp
            | dfr as-datetime '%Y-%m-%dT%H:%M:%S' -n
            | dfr rename datetime timestamp
        )
    } else {}
}

export def 'graph-particles-df' [] {
    (cy-path graph particles.parquet)
    | if ($in | path exists) {
        dfr open $in
    } else {
        cprint `particles.parquet doesn't exist. Use *graph-update-particles-parquet*`

        [ [index, particle, neuron, height, timestamp, content_s];
        [0, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt",
        490, "2021-11-05 14:11:41", "cyber|QK3oufV"]
        ] | dfr into-df
    }
}

export def 'particles-filter-by-type' [
    --exclude
    --media
    --timeout
] {
    let $input = $in
    let $filter_regex = (
        if $media {
            '"MIME'
        } else {}
        | if $timeout {
            append 'timeout\|'
        } else {}
        | str join '|'
        | '^' + $in
    )

    $input
    | dfr filter-with (
        $in.content_s =~ $filter_regex
        | if $exclude {dfr not} else {}
    )
}

# Create a config JSON to set env variables, to use them as parameters in cyber cli
export def --env 'config-new' [
    # config_name?: string@'nu-complete-config-names'
] {
    print (check-requirements)
    make_default_folders_fn

    cprint -c green 'Choose the name of executable:'
    let $exec = (nu-complete-executables | input list -f | print-and-pass)

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

    cprint -c green --before 1 $'Select the address from your ($exec) cli to send transactions from:'

    let $address = (
        $addr_table
        | input list -f
        | get address
        | print-and-pass
    )

    let $keyring = $addr_table | where address == $address | get keyring.0

    let $passport_nick = (
        passport-get $address
        | get nickname -i
    )

    if (not ($passport_nick | is-empty)) {
       cprint -c default_italic --before 1 $'Passport nick *($passport_nick)* will be used'
    }

    let $config_name = (
        $addr_table
        | select address name
        | transpose -rd
        | get $address
        | $'($in)($passport_nick | if $in == null {} else {'-' + $in})-($exec)'
    )

    let $chain_id = if ($exec == 'cyber') { 'bostrom' } else { 'space-pussy' }

    let $rpc_def = if ($exec == 'cyber') {
        'https://rpc.bostrom.cybernode.ai:443'
    } else {
        'https://rpc.space-pussy.cybernode.ai:443'
    }

    cprint -c green --before 1 'Select the address of RPC api for interacting with the blockchain:'
    let $rpc_address = (
        [$rpc_def 'other']
        | input list -f
        | if $in == 'other' {
            input 'enter the RPC address:'
        } else {}
        | print-and-pass
    )

    cprint -c green --before 1 'Select the ipfs service to store particles:'

    let $ipfs_storage = (
        set-cy-setting --output_value_only 'ipfs-storage'
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
        open (cy-path config $'($config_name).toml')
    }
    # | if $quiet {} else {print-and-pass}
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
                $filename | backup-and-echo
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
    | print-and-pass
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
        caching-function query rank search $cid $page 10
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
    let $cid = (pin-text $query --only_hash)

    def search_or_back_request [
        type: string
    ] {
        caching-function query rank $type $cid $page $results_per_page
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

    search_or_back_request search
    | append (search_or_back_request backlinks)
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

    watch (cy-path cache queue_cids_to_download) {|| clear; print $'Searching ($env.cy.exec) for ($cid)'; serp1 $results}
}

export def search-walk [
    query: string
    --results_per_page: int = 100
    --duration: duration = 2min
] {
    let $cid = (pin-text $query --only_hash)

    def serp [page: int] {
        caching-function query rank search $cid $page $results_per_page --cache_validity_duration $duration
        | upsert page $page
    }

    generate {
        result: [],
        page : -1,
        pagination: {total: $results_per_page}
    } {|i|
        {out: $i.result}
        | if ($i.pagination.total / $results_per_page - 1 | math ceil) > $i.page {
            upsert next (serp ($i.page + 1))
        } else {}
    }
    | flatten
    | into int rank
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
    --pretty
] {
    $results
    | get result
    | upsert particle {
        |i| cid-read-or-download $i.particle
    }
    | select particle rank
}

#[test]
def search-test-dummy [] {
    greater (search 'cy' | length) 0
}

# Obtain cid info
#
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
        ($type == null)
        or ($size == null)
        or (($type == 'text/html') and (($size == '157')))
    ) {
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
    ($env.cy.ipfs-files-folder | path join $'($cid).md')
    | if ($in | path exists) {
        open
    } else {
        queue-task-add $'cid-download ($cid)';
        'downloading'
    }
    | if $full {} else {
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

    let $task = $'cid-download ($cid) --source ($source) --info_only=($info_only) --folder "($folder)"'

    if ($content == null) or ($content == 'timeout') or $force {
        queue-task-add $task
        print 'downloading'
    }
}

# Download cid immediately and mark it in the queue
export def 'cid-download' [
    cid: string
    --source: string # kubo or gateway
    --info_only # Don't download the file by write a card with filetype and size
    --folder: string
] {
    let $folder = ($folder | default $env.cy.ipfs-files-folder)
    let $source = ($source | default $env.cy.ipfs-download-from)
    let $status = match $source {
        'gateway' => {cid-download-gateway $cid --info_only=$info_only --folder $folder}
        'kubo' => {cid-download-kubo $cid --info_only=$info_only --folder $folder}
    }

    if ($status) in ['text' 'non_text'] {
        rm --force (cy-path cache queue_cids_to_download $cid)
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
    --info_only # Don't download the file but write a card with filetype and size
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
            | file - --mime
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
        do -i {
            ipfs dag stat $cid --enc json --timeout $timeout | from json
        }
        | default {'Size': null}
        | merge {'MIME type': ($type | split row ';' | get -i 0)}
        | sort -r
        | to toml
        | save -f $file_path;
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
    --info_only # Don't download the file by write a card with filetype and size
] {
    let $file_path = ($folder | default $'($env.cy.ipfs-files-folder)' | path join $'($cid).md')
    let $meta = (cid-get-type-gateway $cid)
    let $type = ($meta | get -i type)
    let $size = ($meta | get -i size)

    if (
        (($type | default '') == 'text/plain; charset=utf-8') and (not $info_only)
    ) {
        # to catch response body closed before all bytes were read
        # {http get -e https://gateway.ipfs.cybernode.ai/ipfs/QmdnSiS36vggN6gHbeeoJUBSUEa7B1xTJTcVR8F92vjTHK
        # | save -f temp/test.md}
        try {
            http get -e $'($gate_url)($cid)' -m 120 | save -f $file_path
        } catch {
            return 'not found'
        }
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
    symbol: string = ''
] {
    let $path = (cy-path cache queue_cids_to_download $cid)

    if not ($path | path exists) {
        touch $path
    } else if $symbol != '' {
        $symbol | save -a $path
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
    let $files = ls -s (cy-path cache queue_cids_to_download)

    if ( ($files | length) == 0 ) {
        return 'there are no files in queue'
    }

    if not $quiet {
        cprint $'Overall count of files in queue is *($files | length)*'
        cprint $'*($env.cy.ipfs-download-from)* will be used for downloading'
    }

    let $filtered_files = (
        $files
        | where size <= (1 + $attempts | into filesize)
        | sort-by size
    )

    let $filtered_count = ($filtered_files | length)

    if ($filtered_files == []) {
        if not $quiet {
            print $'There are no files, that was attempted to download for less than ($attempts) times.'}
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
    | append (
        $filtered_files
        | where size >= 4b
        | where modified < (date now | $in - 5hr)
        | sort-by modified # old files first
    )
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

# remove from queue CIDs with many attempts
export def 'cache-clean-cids-queue' [
    attempts: int = 15      # limit a number of previous download attempts for cids in queue
] {
    let $files = ls (cy-path cache queue_cids_to_download)
    let $files_dead = cy-path cache queue_cids_dead

    $files
    | where size > ($attempts | into filesize)
    | get name
    | each {|i|
        try {
            mv $i $files_dead
        } catch {
            open $i | save -a (cy-path cache queue_cids_dead ($i | path basename))
            rm $i
        }
    }
}

# Clear the cache folder
export def 'cache-clear' [] {
    cy-path cache | backup-and-echo
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

    ^($exec) query block -n $env.cy.rpc-address
    | from json
    | get block.header
    | select height time chain_id
}

# Get a karma metric for a given neuron
#
# > cy query-rank-karma bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | to yaml
# karma: 852564186396
export def 'query-rank-karma' [
    neuron?: string
] {
    let $address = if $neuron == null {$env.cy.address} else {$neuron}
    caching-function query rank karma $address
    | default 0 karma
    | into int karma
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
    neuron?: string
    --height: int = 0
    --record
] {
    let $address = $neuron | default $env.cy.address
    if not (is-neuron $address) {
        cprint $"*($address)* doesn't look like an address"
        return null
    }

    caching-function query bank balances $address [--height $height]
    | get balances -i
    | if $in == null {
        return
    } else if ($in == []) {
        token-dummy-balance
    } else {
        into int amount
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
#
# > tokens-supply-get | select boot hydrogen milliampere | to yaml
# boot: 1187478088996451
# hydrogen: 320740400170941
# milliampere: 9760366733
export def 'tokens-supply-get' [
    --height: int = 0
] {
    caching-function query bank total [--height $height]
    | get supply
    | into int amount
    | transpose -idr
}

export def 'tokens-pools-table-get' [
    --height: int = 0
    --short     # get only basic information
] {
    let $liquidity_pools = (caching-function query liquidity pools [--height $height])

    if $short { return $liquidity_pools }

    let $supply = (tokens-supply-get --height $height)

    $liquidity_pools
    | get pools
    | each {|b| $b
        | upsert balances {|i|
            tokens-balance-get --height $height --record $i.reserve_account_address
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
    address?: string
    --height: int = 0
    --sum
] {
    caching-function query staking delegations ($address | default $env.cy.address) [--height $height]
    | get -i delegation_responses
    | if $in == null {return} else {}
    | each {|i| $i.delegation | merge $i.balance}
    | into int amount
    | upsert state delegated
    | if $sum {
        tokens-sum
    } else {}
}

export def 'tokens-rewards-get' [
    neuron?: string
    --height: int = 0
    --sum
] {
    let $address = $neuron | default $env.cy.address

    caching-function query distribution rewards $address [--height $height]
    | get total -i
    | if $in == null {return} else {}
    | if $in == [] {return} else {}
    | into int amount
    | if $sum {
        tokens-sum
    } else {}
    | upsert state rewards
}

export def 'tokens-investmint-status-table' [
    neuron?: string
    --h_liquid      # retrun amount of liquid H
    --quiet         # don't print amount of H liquid
    --height: int = 0
    --sum
] {
    let $address = $neuron | default $env.cy.address
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
        | into int amount
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

    if not $quiet {
        print $'liquid hydrogen availible for investminting: (
            $hydrogen_liquid | to-number-format --significant_integers 0)'
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
    neuron?: string
    --height: int = 0
] {
    let $address = $neuron | default $env.cy.address
    caching-function query grid routed-from $address [--height $height]
    | get -i value
    | if $in == null {return} else { }
    | into int amount
    | upsert state routed-from
}

export def 'tokens-routed-to' [
    neuron?: string
    --height: int = 0
] {
    let $address = $neuron | default $env.cy.address
    caching-function query grid routed-to $address [--height $height]
    | get -i value
    | if $in == null {return} else { }
    | into int amount
    | upsert state routed-to
}

#[test]
def test-tokens-routed-from [] {
    equal (tokens-routed-from bostrom1vu39vtn2ld3aapued6nwlhm7wpg2gj9zzlncek) null
    equal (tokens-routed-from bostrom1vu39vtn2ld3aapued6nwlhm7wpg2gj9zzlncej) []

    # seems like there is a mistake below
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8) [
        [denom, amount, state]; [milliampere, 3000, routed-from], [millivolt, 180000, routed-from]
    ]
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 --height 10124681) [
        [denom, amount, state]; [milliampere, 3000, routed-from], [millivolt, 180000, routed-from]
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
        | merge ( caching-function query ibc-transfer denom-trace $"'($i.ibc_hash)'" | get denom_trace )
    }
    | reject ibc_hash
    | upsert token {
        |i| $i.path         #denom compound
        | str replace -ra '[^-0-9]' ''
        | str trim -c '-'
        | if ($in | split row '-' | length | $in > 1) {
            $in + '🛑'
        } else {}
        | $'($i.base_denom)/($i.denom | str substring 62..68)/($in)'
    }
    | sort-by path --natural
    | reject path amount
    | if $full {} else {
        select denom token
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

# Get info about tokens from the on-chain-registry contract
#
# https://github.com/Snedashkovsky/on-chain-registry
export def 'tokens-info-from-registry' [
    chain_name: string = 'bostrom'
] {
    let $pcontract = 'bostrom1w33tanvadg6fw04suylew9akcagcwngmkvns476wwu40fpq36pms92re6u'
    let $json = ( {get_assets_by_chain: {chain_name: $chain_name}} | to json -r )
    let $params = ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']

    caching-function --exec 'cyber' --no_default_params query wasm contract-state smart $pcontract $json $params
    | get data.assets
    | upsert denom_units {|i| $i.denom_units?.exponent? | default [0] | math max}
    | select base symbol denom_units name description display traces -i
    | rename denom token
    | where token != null
}

export def 'tokens-price-in-h-naive' [
    --all_data
    --height: int = 0
]: nothing -> table {
    let $pools = (
        tokens-pools-table-get --height $height
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
]: table -> table {
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

export def 'tokens-in-token-naive' [
    token: string = 'ATOM'
    --price # leave price in h column
]: table -> table {
    let $input = $in
    let $denom = (
        tokens-info-from-registry | select token denom | transpose -idr | get $token
    )
    let $target_denom_price_in_h = (tokens-price-in-h-naive | transpose -idr | get $denom)
    let $column_name = $'amount_in_($token)_naive'

    $input
    | if ($in | columns | 'amount_in_h_naive' in $in) {} else {
        tokens-in-h-naive
    }
    | upsert $column_name {
        |i| $i.amount_in_h_naive / $target_denom_price_in_h
    }
    | move $column_name --before amount_in_h_naive
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
    | reject -i ...[
        hydrogen reserve_coin_denom reserve_coin_amount h_out_price price_in_h_naive source_amount
    ]
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
]: nothing -> int {
    if source_coin_amount == 0 {
        0
    } else {
        ( ($source_coin_amount * $target_coin_pool_amount * (1 - $pool_fee))
            / ($source_coin_pool_amount + 2 * $source_coin_amount) )
        | into int
    }
}

export def 'tokens-format' [
    --clean # display only formatted values
] {
    let $input = join -l (tokens-ibc-denoms-table) denom denom | fill non-exist -v ''

    let $columns = $input | columns

    $columns
    | where $it =~ 'amount_in_h'
    | if ($in | length | $in > 0) {
        reduce -f $input {|i acc| $acc | merge ($acc | number-col-format $i --decimals 0 --denom 'H')}
    } else {$input}
    # $input
    | upsert token {|i| if $i.token? != '' {$i.token} else {$i.denom}}
    | move token --before ($in | columns | first)
    | move denom --after ($in | columns | last)
    | upsert base_denom {|i| $i.token | split row '/' | get 0 }
    | join -l (tokens-denoms-decimals-dict) base_denom base_denom
    | default 0 decimals
    | upsert token {
        |i| $i.token
        | str replace $i.base_denom ($i.ticker? | default ($i.token | str upcase))
    }
    | if amount in $columns {
        upsert amount_f {
            |i| $i.amount / (10 ** $i.decimals)
            | to-number-format --integers 9 --decimals 0
        }
        | move amount_f --after token
    } else {}
    | reject -i base_denom ticker decimals
    | if $clean {reject denom amount} else {}
}

# Check balances for the keys added to the active CLI
#
# > cy balances --test | to yaml
# name: bot3f
# boot: 654582269
# hydrogen: 50
# address: bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel
export def 'balances' [
    ...address: string@'nu-complete key-names'
    --test      # Use keyring-backend test (with no password)
] {
    let $balances = (
        ^($env.cy.exec) keys list --output json --keyring-backend test | from json
        | if not $test {
            append ( ^($env.cy.exec) keys list --output json | from json )
        } else {}
        | select name address
        | uniq-by address
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

export def 'tokens-undelegations' [
    $neuron?: string
    --height: int = 0
    --sum
] {
    let $address = $neuron | default $env.cy.address

    caching-function query staking unbonding-delegations $address
    | get unbonding_responses
    | flatten --all
    | get balance
    | into int
    | math sum
}

export def 'tokens-balance-all' [
    $neuron?: string
    --height: int = 0
    --routes: string = 'from'
    --dont_convert_pools
] {
    let $address = $neuron | default $env.cy.address
    let $invstiminted_frozen = (tokens-investmint-status-table $address --sum --quiet)
    (
        tokens-balance-get $address --height $height
        | if $in == (token-dummy-balance) {
            return []
        } else {}
        | tokens-minus $invstiminted_frozen --state 'liquid'
        | append $invstiminted_frozen
        | append (tokens-rewards-get --sum $address)
        | append (tokens-delegations-table-get --sum $address)
        | append (
            if $routes == 'from' {
                tokens-routed-from $address
            } else {
                tokens-routed-to $address
            }
        )
        | if $dont_convert_pools {} else {
            tokens-pools-convert-value
        }
        | sort-by amount -r
        | sort-by denom
    )
}

export def 'tokens-sum' [
    --state: string = '-'
] {
    $in
    | if $in in [null []] {return [{denom: boot, amount: 0, state: 'dummy'}]} else {}
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
export def 'tokens-rewards-withdraw' [
    neuron?: string
] {
    let $address = $neuron | default $env.cy.address

    let $tx = (
        (^($env.cy.exec) tx distribution withdraw-all-rewards
            --from $address --fees 2000boot --gas 2000000 --output json --yes)
        | str replace "Default sign-mode 'direct' not supported by Ledger, using sign-mode 'amino-json'.\n" ''
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
        | upsert height $tx_height
        | join -l (
            query-staking-validators | rename -c {operator_address: validator_address}
        ) validator_address validator_address
        | reject delegator_address shares denom
        | rename validator delegated
        | select -i moniker delegated commission rewards jailed ...($in | columns)
        | where delegated > 0
        | join ($rewards | where denom == boot) -l validator validator
        | upsert percent {|i| ($i.rewards / $i.delegated) }
    );

    $result
    | upsert percent_rel {|i| $i.percent / ($result.percent | math max)}
    | move percent_rel --after commission
}

export def 'tokens-delegate-wizzard' [
    $neuron?: string
] {
    let $address = $neuron | default $env.cy.address
    let $boots_liquid: int = (
        tokens-balance-all $address
        | where state == liquid
        | where denom == boot
        | get amount.0
        | $in - 2_000_000 # a fraction for fees
    )

    ($boots_liquid | to-number-format --denom boot --significant_integers 0 | ansi strip)
    | cprint $'You have *($in)* liquid. How much of them would you like to delegate?'

    let $boots_to_delegate: string = (
        tokens-fraction-menu $boots_liquid --denom 'boot'
    )

    cprint $'Choose the validator to delegate *($boots_to_delegate)*.'
    let $operator = (
        validator-chooser --only_my_validators
        | append {moniker: 'load more'}
        | input list --fuzzy
        | if ($in | values | get 0 | $in == 'load more') {
            validator-chooser | input list --fuzzy
        } else {}
        | get operator_address
    )

    (
        ^$env.cy.exec tx staking delegate $operator $boots_to_delegate
        --from $env.cy.address ...(default-node-params)
    )
}

def tokens-fraction-menu [
    tokens_max: int
    --denom: string = ''
    --bins_list: list = [1 0.5 0.2]
] {
    $bins_list
    | wrap fraction
    | upsert $denom {|i| $i.fraction * $tokens_max | math floor | into int}
    | upsert fraction {|i| $i.fraction * 100 | into string | $in + '%'}
    | append {fraction: other, $denom: 0}
    | input list
    | get $denom
    | if $in == 0 {
        $tokens_max | tokens-fraction-input --denom $denom
    } else {
        $'($in)($denom)'
    }
    | print-and-pass
}

export def 'tokens-investmint-wizzard' [
    $neuron?: string
] {
    let $address = $neuron | default $env.cy.address
    $env.cy.caching-function-force-update = true
    let $times = (
        tokens-investmint-status-table $address
        | print-and-pass
        | window 2 --stride 2
        | each {|i| $i
            | reduce -f '' {|a acc| $acc + $'($a.amount)($a.denom) '}
            | wrap tokens
            | upsert release_time $i.release_time.0
        }
    )

    $env.cy.caching-function-force-update = false
    let $h_free = (
        tokens-investmint-status-table $address --h_liquid --quiet
        | if $in in [[] 0] {
            error make {msg: (cprint --echo $'no liquid hydrogen on *($address)* address')}
        } else {}
    )
    let $h_to_investmint = (tokens-fraction-menu $h_free --denom hydrogen --bins_list [0.5 1 0.2])

    let $resource_token = (
        ['Volt' 'Ampere']
        | input list
        | str downcase
        | 'milli' + $in
    )

    cprint --before 1 --after 2 'Choose the investminting period.
    In the list below fields that have `tokens` value are your currently used slots.
    The first value is always a tuesday after the next 2 weeks.'

    let $release_time = (
        $times
        | select release_time tokens
        | prepend (1..6 | each { {release_time: (nearest-given-weekday --weeks $in)} })
        | sort-by release_time
        | input list
        | get release_time
        | $in - (date now) | into int
        | $in / 10 ** 9 | into int
    )

    let $trans_unsigned = (
        cyber tx resources investmint $h_to_investmint $resource_token $release_time
        --from $address --fees 2000boot --gas 2000000 ...(default-node-params) --generate-only
    )

    print ($trans_unsigned | from json | to yaml)

    if (confirm '*Confirm transaction?*') {
        let $unsigned = cy-path temp 'tx_investmint_unsigned.json'
        let $signed: string = cy-path temp 'tx_investmint_signed.json'
        $trans_unsigned | save -rf $unsigned
        ^($env.cy.exec) tx sign $unsigned --from $address --output-document $signed --yes ...(default-node-params)

        ^($env.cy.exec) tx broadcast $signed ...(default-node-params) | from json | select txhash
    }
}

export def 'tokens-fraction-input' [
    --dust_to_leave: int = 50_000 # the amount of token to leave for paing fee
    --denom: string = ''
    --yes # proceed without confirmation
] {
    let $tokens = $in - $dust_to_leave

    while true {
        cprint $'you can enter integer value (char lp)like *4_000_000* or *4000000*(char rp) or percent
            from your liquid BOOTs (char lp)like *30%*(char rp)'

        let $input: string = input

        let $value: int = (
            $input
            | if ($in | str contains '%') {
                str replace '%' '' | into float | $in / 100 | $tokens * $in
            } else { str replace -ar '[^0-9]' '' }
            | into int
        )

        if ($value > $tokens) {
            cprint $'*($value)* is bigger than *($tokens)*'
        } else if ($value > 0) {
            if $yes or (
                confirm --dont_keep_prompt $"Is the amount *(
                    $value | to-number-format --denom $denom --significant_integers 0 | ansi strip
                )* correct? It is *($value / $tokens * 100 | math round -p 1)%* from *($tokens)*"
            ) {
                return $'($value)($denom)'
            }
        }
    }
}

# info about props current and past
export def 'governance-view-props' [
    id?: string@'nu-complete-props'
    --dont_format
] {
    caching-function query gov proposals
    | get proposals
    | if $id != null {where proposal_id == $id} else {}
    | each {|i| $i
        | into datetime voting_end_time submit_time deposit_end_time voting_start_time
        | if $in.status == 'PROPOSAL_STATUS_DEPOSIT_PERIOD' {
            reject final_tally_result voting_start_time voting_end_time
        } else {}
        | if $dont_format { } else {
            table -e | print $in
        }
    }
}

def 'governance-prop-summary' [] {
    let $tally_res = (
        $in
        | get -i final_tally_result
        | if $in == null {return} else {}
        | into int yes abstain no no_with_veto
    );
    let $98_total = ($tally_res | values | math sum);

    $tally_res
    | {'✅': $in.yes, '❌': $in.no, '🛑': $in.no_with_veto, '🦭': $in.abstain}
    | items {|k v| $'($k)(
        $v / $98_total * 100
        | to-number-format --denom "%" --decimals 1 --significant_integers 0
    )'}
    | str join '/'
    | ' | ' + $in
}

# Set the custom name for links csv table
export def --env 'set-links-table-name' [
    name: string
]: nothing -> nothing {
    $env.cy.links_table_name = $name
}

export def --env 'set-cy-setting' [
    key?: string@nu-complete-settings-variants
    value?: any@nu-complete-settings-variant-options
    --output_value_only
] {
    let $key_1 = if $key == null {
        nu-complete-settings-variants
        | each {{$in.value: $in.description}}
        | input list 'Select the setting that you want to change'
        | columns
        | get 0
    } else { $key }

    let $value_1 = (
        if $value == null {
            set-select-from-variants $key_1
        } else { $value }
        | if ($in in ['true', 'false']) { # input list errors on booleans on 0.87.1
            into bool
        } else {}
    )

    if $output_value_only {
        $value_1
    } else {
        $env.cy = ($env.cy | upsert $key_1 $value_1)
    }
}

def 'set-select-from-variants' [
    $key
] {
    let $key_record = open (cy-path kickstart settings-variants.yaml) | get -i $key

    if $key_record == null {
        input 'type your setting: '
    } else {
        cprint -h green $'*($key): ($key_record.description?)*'

        $key_record
        | get variants
        | input list
        | if ($in == 'other') {
            input 'type your setting: '
        } else {}
        | print-and-pass
    }
}

# set env a variable from argument, or get it's value, or get default
def --env 'set-or-get-env-or-def' [
    key
    value?
    --dont_set_env
] {
    let $val_ref = (
        $value
        | if $in != null {} else {
            $env.cy | get -i $key
        }
        | if $in != null {} else {
            let $key_record = (
                open (cy-path kickstart settings-variants.yaml)
                | get -i $key
            )

            let $def_value = $key_record | get -i variants.0

            match $key_record.type? {
                'int' => {$def_value | into int}
                'datetime' => {$def_value | into datetime}
                _ => {$def_value | into string}
            }
        }
    )

    if not $dont_set_env {
        $env.cy = ($env.cy | upsert $key $val_ref)
    }

    $val_ref
}

def 'current-links-csv-path' [
    name?: path
]: nothing -> path {
    $name
    | default ($env.cy.links_table_name?)
    | default 'temp'
    | cy-path mylinks $'($in).csv'
}

# Add the cybercongress node to bootstrap nodes
export def 'ipfs-bootstrap-add-congress' []: nothing -> nothing {
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
# persistent_peers = "7ad32f1677ffb11254e7e9b65a12da27a4f877d6@195.201.105.229:36656,d0518..."
export def 'validator-generate-persistent-peers-string' [
    node_address?: string
]: nothing -> string {
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

# Query all delegators to a specified validator
export def 'validator-query-delegators' [
    validator_or_moniker: string@'nu-complete-validators-monikers'
    --limit: int = 1000
] {
    let $validator = (
        if (is-validator $validator_or_moniker) {
            $validator_or_moniker
        } else {
            nu-complete-validators-monikers
            | select value description
            | transpose -idr
            | get $validator_or_moniker
        }
    )

    def res [
        page: int
    ] {
        caching-function query staking delegations-to $validator --limit $limit --page $page
        | upsert page $page
        | upsert length {|i| $i.delegation_responses | length}
    }

    let $start = {
        delegation_responses: [],
        page: 0,
        length: $limit
    }

    let $closure = {|i|
        {out: $i.delegation_responses}
        | if ($i.length == $limit) {
            upsert next (res ($i.page + 1))
        } else {}
    }

    generate $start $closure
    | flatten
    | flatten
    | into int amount
    | move denom amount --before validator_address
    | rename neuron
}

# Query tx by hash
export def 'query-tx' [
    hash: string
    --full_info # display all columns of a transaction
]: nothing -> record {
    def trans_status [i] {
        if $i.code == 0 {'Transaction has been processed! ✅'} else {
            $'Transaction has been rejected: the code ($i.code?)'}
    }

    caching-function --error [query tx --type hash $hash]
    | if ($in | columns | $in == [update_time]) {
        error make {msg: (cprint --echo $'No transaction with hash ($hash) is found')}
    } else {
        reject -i events
    }
    | print-and-pass {|i| trans_status $i}
    | if $full_info {
        select -i ...($in | columns | prepend [height code logs tx txhash])
    } else {
        select height code logs
    }
    | upsert trans_staus {|i| trans_status $i}
}

# Query tx by acc/seq
export def 'query-tx-seq' [
    neuron: string
    seq: int
]: nothing -> record {
    caching-function --disable_update [query tx --type=acc_seq $'($neuron)/($seq)']
    | reject -i events
}

# Query account
export def 'query-account' [
    neuron: string
    --height: int = 0
    --seq   # return sequence
]: nothing -> record {
    caching-function query account $neuron [--height $height]
    | if $seq {
        get base_vesting_account.base_account.sequence
        | into int
    } else {}
}

export def 'query-links-max-in-block' []: nothing -> int {
    ( query-links-bandwidth-params | get max_block_bandwidth ) / ( query-links-bandwidth-price )
    | into int
}

def 'query-links-bandwidth-price' []: nothing -> int {
    caching-function query bandwidth price | get price.dec | into float | $in * 1000 | into int # price in millivolt
}

def 'query-links-bandwidth-params' []: nothing -> record {
    caching-function query bandwidth params
    | get params
    | transpose key value
    | into float value
    | transpose -idr
}

# Query status of authz grants for address
#
# > query-authz-grants-by-granter (qnbn bb🔑) | first 2 | to yaml
# - expired: true
#   expiration: 2023-04-25 05:40:44 +00:00
#   grantee: bostrom1yrv70gskxcn04xu03rpywd044gvz9l0mmhad2d
#   msg: /cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward
#   granter: bostrom1mcslqq8ghtuf6xu987qtk64shy6rd86a2xtwu8
#   '@type': /cosmos.authz.v1beta1.GenericAuthorization
# - expired: true
#   expiration: 2023-04-25 05:42:25 +00:00
#   grantee: bostrom1yrv70gskxcn04xu03rpywd044gvz9l0mmhad2d
#   msg: /cosmos.staking.v1beta1.MsgDelegate
#   granter: bostrom1mcslqq8ghtuf6xu987qtk64shy6rd86a2xtwu8
#   '@type': /cosmos.authz.v1beta1.GenericAuthorization
export def 'query-authz-grants-by-granter' [
    neuron?
] {
    $neuron
    | if ($in != null) { } else { $env.cy.address }
    | caching-function query authz grants-by-granter $in
    | get grants
    | each {|i| $i | merge $i.authorization | reject authorization}
    | upsert expiration {|i| $i.expiration | into datetime}
    | sort-by expiration
    | upsert expired {|i| $i.expiration < (date now)}
    | select -i expired expiration grantee msg ...($in | columns)
}

# Query status of authz grants for address
#
# > query-authz-grants-by-grantee bostrom1sgy27lctdrc5egpvc8f02rgzml6hmmvh5wu6xk | to yaml
# - expired: true
#   expiration: 2023-05-05 11:43:49 +00:00
#   granter: bostrom1angqedc8vu2dxa2d2cx7z5jjzm6vjldgtqm005
#   msg: /cyber.resources.v1beta1.MsgInvestmint
#   grantee: bostrom1sgy27lctdrc5egpvc8f02rgzml6hmmvh5wu6xk
#   '@type': /cosmos.authz.v1beta1.GenericAuthorization
export def 'query-authz-grants-by-grantee' [
    neuron?
] {
    $neuron
    | if ($in != null) { } else { $env.cy.address }
    | caching-function query authz grants-by-grantee $in
    | get grants
    | each {|i| $i | merge $i.authorization | reject authorization}
    | upsert expiration {|i| $i.expiration | into datetime}
    | sort-by expiration
    | upsert expired {|i| $i.expiration < (date now)}
    | select -i expired expiration granter msg ...($in | columns)
}

export def 'authz-give-grant' [
    $neuron
    $message_type: string@"nu-complete-authz-types"
    $expiration: duration
] {
    (
        ^$env.cy.exec tx authz grant $neuron generic --msg-type $message_type
        --from $env.cy.address
        --expiration (date now | $in + $expiration | format date '%s' | into int)
        ...(default-node-params)
    )
}

export def 'query-links-bandwidth-neuron' [
    neuron?
]: nothing -> table {
    caching-function query bandwidth neuron ($neuron | default $env.cy.address) --cache_stale_refresh 5min
    | get neuron_bandwidth
    | select max_value remained_value
    | transpose param links
    | into int links
    | upsert links {|i| $i.links / (query-links-bandwidth-price) | math floor}
}

export def 'query-staking-validators' [] {
    let $vals_1_page = (caching-function query staking validators --count-total)

    let $offset_to_go = (
        $vals_1_page
        | get pagination.total
        | into int
        | $in // 100
        | 1..$in
        | each {|i| $i * 100}
    );

    let $all_validators = (
        $offset_to_go
        | each {|i| caching-function query staking validators --count-total --offset $i | get validators}
        | flatten
        | prepend $vals_1_page.validators
    );

    $all_validators
    | upsert moniker {|i| $i.description.moniker}
    | upsert commission {|i| $i.commission.commission_rates.rate | into float}
    | select moniker commission jailed tokens operator_address
    | into int tokens
    | sort-by tokens -r
}

export def 'validator-chooser' [
    --only_my_validators
] {
    query-staking-validators
    | rename -c {tokens: 'delegated_total'}
    | join -l (
        tokens-delegations-table-get
        | select validator_address amount
        | rename operator_address delegated_my
    ) operator_address operator_address
    | default 0 delegated_my
    | sort-by delegated_my delegated_total -r
    | move delegated_my delegated_total --before operator_address
    | if $only_my_validators {
        where delegated_my > 0
    } else {}
}

#[test]
def 'test-validator-chooser' [] {
    use std assert greater

    greater ( validator-chooser | length ) 1
}

# A wrapper, to cache CLI requests
export def --wrapped 'caching-function' [
    ...rest
    --exec: string = ''                         # The name of executable
    --cache_validity_duration: duration = 60min # Sets the cache's valid duration.
                                                # No updates initiated during this period.
    --cache_stale_refresh: duration = 7day      # Sets stale cache's usable duration.
                                                # Triggers background update and returns cache results.
                                                # If exceeded, requests immediate data update.
    --force_update
    --disable_update (-U)
    --quiet                                     # Don't output execution's result
    --no_default_params                         # Don't use default params (like output, chain-id)
    --error                                     # raise error instead of null in case of cli's error
    --retries: int
]: nothing -> record {
    if ($retries != null) {$env.cy.caching-function-max-retries = $retries}

    if $rest == [] { error make {msg: 'The "caching-function" function needs arguments'} }

    let $executable = if $exec != '' {$exec} else {$env.cy.exec}
    let $sub_commands_and_args = (
        $rest | flatten | flatten         # to recieve params as a list from passport-get
        | if $no_default_params {} else {
            append (default-node-params)
        }
    )

    let $json_path: path = (
        $executable
        | append ($sub_commands_and_args)
        | str join '_'
        | str replace -r '--node.*' ''
        | str trim -c '_'
        | to-safe-filename --suffix '.json'
        | [$env.cy.path cache jsonl $in]
        | path join
    )

    log debug $'json path: ($json_path)'

    let $last_data = (
        if ($json_path | path exists) {
            open $json_path
        } else {
            {'update_time': 0}
        }
        | into datetime update_time
    )

    let $freshness = ((date now) - $last_data.update_time)

    mut $update = (
        $force_update or
        ($env.cy.caching-function-force-update? | default false) or
        (($freshness > $cache_stale_refresh) and (not $disable_update))
    )

    if ('error' in ($last_data | columns)) {
        log debug $'last update ($freshness) was unsuccessfull, requesting for a new one';
        $update = true
    }

    if $update {
        (request-save-output-exec-response $executable $sub_commands_and_args $json_path $error $quiet
            --last_data $last_data)
    } else {
        if ($freshness > $cache_validity_duration) {
            queue-task-add -o 2 (
                $'caching-function --exec ($executable) --force_update [' +
                ($sub_commands_and_args | str join ' ') +
                '] | to yaml | lines | first 5 | str join "\n"'
            )
        };
        $last_data
    }
}

def 'request-save-output-exec-response' [
    executable: string
    sub_commands_and_args: list
    json_path: string
    error: bool = false
    quiet: bool = false
    --last_data: = {'update_time': 0}
] {
    log debug $'($executable) ($sub_commands_and_args | str join " ")'

    mut $retries = (
        $env.cy?.caching-function-max-retries?
        | default 5
        | $in + 1 # so if we set caching-function-max-retries to 1 only 1 retry would be made
    )

    mut $response = {}

    let $request = {
        do -i { ^($executable) ...$sub_commands_and_args }
        | complete
        | if $in.exit_code == 0 {
            get stdout
            | from json
            | insert update_time (date now)
        } else {
            {error: $in, update_time: (date now)}
        }
    }

    while $retries > 0 {
        $response = (do $request);

        if $response.error? == null {
            $retries = 0
        } else {
            sleep 2sec;
            $retries = $retries - 1
        }
    }

    $response
    | to json -r
    | save -fr $json_path;

    if ('error' in ($response | columns)) {
        if $error {
            error make {msg: ($response.error.stderr | lines | first)}
        } else {
            return
        }
    }

    $last_data
    | if ($in.update_time | into int) != 0 {
        to json -r
        | $'($in)(char nl)'
        | save -ar ($json_path | str replace '.json' '_arch.jsonl')
    }

    if not $quiet {$response}
}

#[test]
def caching-function-test [] {
    equal (
        caching-function query rank karma bostrom1smsn8u0h5tlvt3jazf78nnrv54aspged9h2nl9 | describe
    ) 'record<karma: string, update_time: date>'
    equal (
        caching-function query bank balances bostrom1quchyywzdxp62dq3rwan8fg35v6j58sjwnfpuu | describe
    ) ('record<balances: table<denom: string, amount: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
    equal (
        caching-function query bank balances bostrom1cj8j6pc3nda8v708j3s4a6gq2jrnue7j857m9t | describe
    ) ('record<balances: table<denom: string, amount: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
    equal (
        caching-function query staking delegations bostrom1eg3v42jpwf3d66v6rnrn9hedyd8qvhqy4dt8pc | describe
    ) ('record<delegation_responses: table<delegation: record<delegator_address: string, ' +
        'validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, ' +
        'pagination: record<next_key: nothing, total: string>, update_time: date>')
    equal (
        caching-function query staking delegations bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | describe
    ) ('record<delegation_responses: table<delegation: record<delegator_address: string, ' +
        'validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, ' +
        'pagination: record<next_key: nothing, total: string>, update_time: date>')
    equal (
        caching-function query rank top | describe
    ) ('record<result: table<particle: string, rank: string>, pagination: record<total: int>, ' +
        'update_time: date>')
    equal (
        caching-function query ibc-transfer denom-traces | describe
    ) ('record<denom_traces: table<path: string, base_denom: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
    equal (
        caching-function query liquidity pools --cache_validity_duration 0sec | describe
    ) ('record<pools: table<id: string, type_id: int, reserve_coin_denoms: list<string>, ' +
        'reserve_account_address: string, pool_coin_denom: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
}

# query neuron addrsss by his nick
export def 'qnbn' [
    ...nicks: string@'nicks-and-keynames'
    --df
    --force_list_output (-f)
] {
    let $dict_nicks = nicks-and-keynames | select value description | rename name neuron
    let $addresses = $nicks | where (is-neuron $it) | wrap neuron

    let $neurons = (
        if ($nicks | where (not (is-neuron $it)) | is-empty ) {
            []
        } else {
            $dict_nicks
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

export def 'crypto-prices' [] {
    http get 'https://api.coincap.io/v2/assets' | get data
}

# An ordered list of cy commands
export def 'help-cy' [
    --to_md (-m) # export table as markdown
] {
    cy-path cy.nu
    | open --raw
    | parse -r "(\n(# )(?<desc>.*?)(?:\n#[^\n]*)*\nexport (def|def --env) '(?<command>.*)')"
    | select command desc
    | upsert command {|row index| ('cy ' + $row.command)}
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

def is-validator [test: string] {
    $test =~ '^(bostrom|pussy)\w{46}$'
}

def is-connected []  {
    (do -i {http get https://duckduckgo.com/} | describe) == 'raw input'
}

def --env is-connected-interval [
    interval = 1min
]  {
    if ($env.internet-connected? | default (0 | into datetime)) > ((date now) - $interval) {
        # print 'skip'
        return true
    }

    if (is-connected) {
        $env.internet-connected = (date now)
        # print 'connected checked'
        return true
    } else {
        $env.internet-connected = null
        # print 'not connected'
        return false
    }
}

def open_cy_config_toml [] {
    let $config_path = ($nu.home-path | path join .cy_config.toml)
    if ($config_path | path exists) {
        open $config_path
    } else {
        let $config = {
            'path': ($nu.home-path | path join cy)
            'ipfs-files-folder': ($nu.home-path | path join cy graph particles safe)
            'ipfs-download-from': 'gateway'
            'ipfs-storage': 'both'
            'exec': 'cyber'
            'rpc-address': 'https://rpc.bostrom.cybernode.ai:443'
            'chain-id': 'bostrom'
        }

        $config | save $config_path
        $config
    }
}

def make_default_folders_fn [] {
    mkdir (cy-path backups)
    mkdir (cy-path cache cli_out)
    mkdir (cy-path cache jsonl)
    mkdir (cy-path cache queue_cids_dead)
    mkdir (cy-path cache queue_cids_to_download)
    mkdir (cy-path cache queue_tasks_failed)
    mkdir (cy-path cache queue_tasks_to_run)
    mkdir (cy-path cache search)
    mkdir (cy-path config)
    mkdir (cy-path export)
    mkdir (cy-path graph particles safe)
    mkdir (cy-path mylinks)
    mkdir (cy-path temp ipfs_upload)

    touch (cy-path graph update.toml)

    if ( current-links-csv-path | path exists | not $in ) {
        'from,to' | save (current-links-csv-path)
    }

    if ( cy-path mylinks _cyberlinks_archive.csv | path exists | not $in ) {
        'from,to,address,timestamp,txhash'
        # underscore is supposed to place the file first in the folder
        | save (cy-path mylinks _cyberlinks_archive.csv)
    }
}

def 'system_cids' [] {
    [
        'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx',
        'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx',
        'Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs'
    ]
}

def 'default-node-params' [] {
    [
        '--node' $env.cy.rpc-address
        '--chain-id' $env.cy.chain-id   # todo chainid to choose
        '--output' 'json'
    ]
}

# echo particle for publishing
export def 'echo_particle_txt' [
    i: string
    --markdown (-m)
] {
    let $indent = ($i.step | into int | $in * 4 | $in + 12)

    if $i.content == null {
        $'⭕️ ($i.timestamp), ($i.nick) - timeout - ($i.particle)'
    } else {
        $'🟢 ($i.timestamp), ($i.nick)(char nl)(char nl)($i.content_s)(char nl)(char nl)($i.particle)(char nl)(char nl)'
    }
    | mdcat -l --columns (80 + $indent) -
    | complete
    | get stdout
    | lines
    | each {|i| $"(' ' | str repeat $indent)($i)" | print $in}
    # | each {|b| $"((ansi grey) + ($i.step + 2 | into string) + (ansi reset) | str repeat $indent)($b)" | print $in}
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

def 'backup-and-echo' [
    filename?: path
    --quiet # don't echo the file-path back
    --mv # move the file to backup directory instead of copy
] {
    let $input = $in
    let $path = $filename | default $input
    let $backups_path = (cy-path backups $'(now-fn)($path | path basename)')

    if not ( $path | path exists ) {
        cprint $'*($path)* does not exist'
        return $path
    }

    if $mv {
        mv $path $backups_path
    } else {
        cp $path $backups_path
    }

    if not $quiet {
        $path
    }
}

export def 'queue-task-add' [
    command: string
    --priority (-o): int = 1
] {
    let $filename = (
        $command
        | to-safe-filename --prefix $'($priority)-' --suffix '.nu.txt'
        | cy-path cache queue_tasks_to_run $in
    )

    $'use (cy-path cy.nu) *; ($command)'
    | save -f $filename
}

export def --env 'queue-tasks-monitor' [
    --threads: int = 10
    --cids_in_run: int = 10 # a number of files to download in one command run. 0 - means all (default)
] {
    loop {
        glob (cy-path cache queue_tasks_to_run *.nu.txt)
        | sort
        | if (is-connected-interval 10min) {
            if ($in | length) == 0 {
                # queue-cids-download 10 --cids_in_run $cids_in_run --threads $threads --quiet;
            } else {
                par-each -t $threads {
                    |i| queue-execute-task $i
                };
            };
        };
        sleep 1sec
        print -n $"(char cr)⌛(date now | format date '%H:%M:%S') - to exit press `ctrl+c`"
    }
}

export def 'queue-execute-task' [
    task_path: path
] {
    let $command = (open $task_path)

    let $results = (
        do -i { nu --config $nu.config-path --env-config $nu.env-path $task_path }
        | complete
    )

    $results
    | if $in.exit_code == 0 {
        print -n $'(char nl)🔵 ($command)'
        print -n $'(char nl)($results.stdout)'
    } else {
        print -n $'(char nl)🛑 ($command)'
        $command + ';' | save -a (cy-path cache queue_tasks_failed ($task_path | path basename))
    }
    ^rm -f $task_path;
    log debug $'run ($command)'
}

# Check if all necessary dependencies are installed
export def check-requirements []: nothing -> nothing {

    ['ipfs', 'rich', 'curl', 'cyber', 'pussy']
    | each {
        if (which ($in) | is-empty) {
            $'($in) is missing'
        }
    }
    | if ($in | is-empty) {
        'all required apps are installed'
    }
}

export def --env 'use-recommended-nushell-settings' []: nothing -> nothing {
    $env.config.show_banner = false
    $env.config.table.trim.methodology = 'truncating'
    $env.config.completions.algorithm = 'fuzzy'
    $env.config.completions.quick = false
}

def 'nu-complete-random-sources' [] {
    ['chucknorris.io' 'forismatic.com']
}

def 'nu-complete-search-functions' [] {
    ['search-auto-refresh' 'search-with-backlinks', 'search-sync']
}

def 'nu-complete-neurons-nicks' [] {
    dict-neurons-view | get nick
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
def 'nu-complete key-names' [] {
    ^$env.cy.exec keys list --output json
    | from json
    | select name address
    | upsert name {|i| $i.name + 🔑}
    | rename value description
}

def 'nu-complete dict-nicks' [] {
    (dict-neurons-view)
    | select -i nickname neuron
    | uniq-by nickname
    | where nickname not-in [null '' '?']
    | rename value description
}

def 'nu-complete-settings-variants' [] {
    open (cy-path kickstart settings-variants.yaml)
    | items {|key value| {value: $key, description: $value.description?}}
}

def 'nu-complete-settings-variant-options' [
    context: string
] {
    open (cy-path kickstart settings-variants.yaml)
    | get -i ($context | str trim | split row ' ' | last)
    | get variants
}

def 'nicks-and-keynames' [] {
    (nu-complete key-names)
    | append (nu-complete dict-nicks)
}

def 'nu-complete-bool' [] {
    [true, false]
}

def 'nu-complete-props' [] {
    let term_size = (term size | get columns)

    governance-view-props --dont_format
    | reverse
    | each {|i| {
        value: $i.proposal_id,
        description: $'($i.content.title | str substring 0..$term_size)($i | governance-prop-summary)'
    }}
}

def 'nu-complete-authz-types' [] {
    open (cy-path dictionaries tx_message_types.csv)
    | get type
}

def 'nu-complete-validators-monikers' [ ] {
    query-staking-validators | select moniker operator_address | rename value description
}

export def 'nu-complete-graph-csv-files' [] {
    ls -s (cy-path graph '*.csv' | into glob)
    | sort-by modified -r
    | select name size
    | upsert size {|i| $i.size | into string}
    | rename value description
}

def 'nu-complete-graph-provider' [] {
    ['hasura' 'clickhouse']
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
    mut $table = ($in | default $tbl)

    for column in ($table | columns) {
        $table = ($table | default $value_to_replace $column)
    }

    $table
}

def 'path-exists-safe' [
    path_to_check
] {
    try { $path_to_check | path exists } catch {false}
}

def 'cy-path' [
    ...segments: string
]: nothing -> path {
    $segments
    | prepend $env.cy.path
    | path join
}

export def 'cp-banner' [
    index: int = 0
] {

    "
      ,o888888o.  `8.`8888.      ,8' 8 888888888o   8 8888888888   8 888888888o.
     8888     `88. `8.`8888.    ,8'  8 8888    `88. 8 8888         8 8888    `88.
  ,8 8888       `8. `8.`8888.  ,8'   8 8888     `88 8 8888         8 8888     `88
  88 8888            `8.`8888.,8'    8 8888     ,88 8 8888         8 8888     ,88
  88 8888             `8.`88888'     8 8888.   ,88' 8 888888888888 8 8888.   ,88'   8888888888
  88 8888              `8. 8888      8 8888888888   8 8888         8 888888888P'    ``````````
  88 8888               `8 8888      8 8888    `88. 8 8888         8 8888`8b
  `8 8888       .8'      8 8888      8 8888      88 8 8888         8 8888 `8b.
     8888     ,88'       8 8888      8 8888    ,88' 8 8888         8 8888   `8b.
      `8888888P'         8 8888      8 888888888P   8 888888888888 8 8888     `88.


  8 888888888o   8 888888888o.      ,o888888o.     8 888888888o   8 8888        8 8 8888888888 8888888 8888888888
  8 8888    `88. 8 8888    `88.  . 8888     `88.   8 8888    `88. 8 8888        8 8 8888             8 8888
  8 8888     `88 8 8888     `88 ,8 8888       `8b  8 8888     `88 8 8888        8 8 8888             8 8888
  8 8888     ,88 8 8888     ,88 88 8888        `8b 8 8888     ,88 8 8888        8 8 8888             8 8888
  8 8888.   ,88' 8 8888.   ,88' 88 8888         88 8 8888.   ,88' 8 8888        8 8 888888888888     8 8888
  8 888888888P'  8 888888888P'  88 8888         88 8 888888888P'  8 8888        8 8 8888             8 8888
  8 8888         8 8888`8b      88 8888        ,8P 8 8888         8 8888888888888 8 8888             8 8888
  8 8888         8 8888 `8b.    `8 8888       ,8P  8 8888         8 8888        8 8 8888             8 8888
  8 8888         8 8888   `8b.   ` 8888     ,88'   8 8888         8 8888        8 8 8888             8 8888
  8 8888         8 8888     `88.    `8888888P'     8 8888         8 8888        8 8 888888888888     8 8888
                                                                                                                   "
    # | ansi gradient --fgstart '0x7FFF00'
}
