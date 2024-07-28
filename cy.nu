# Cy - a tool for interacting with Cybergraphs
# https://github.com/cyber-prophet/cy
#
# Use:
# > overlay use -pr ~/cy/cy.nu

use std assert [equal greater]
use cy/nu-utils [ bar, cprint, "str repeat", to-safe-filename, to-number-format, number-col-format,
    nearest-given-weekday, print-and-pass, clip, confirm, normalize, path-modify]
use cy/cy-internals.nu *
use cy/cy-complete.nu *
use cy/queue.nu *

export def main [] { help-cy }
# export def cy [] { help-cy }

export-env {export1}

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
# > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
# QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F
export def 'pin-text' [
    text_param?: string
    --only_hash # calculate hash only, don't pin anywhere
    --ignore_cid # work with CIDs as regular texts, don't use them as they are
    --follow_file_path # check if `text_param` is a valid path, and if yes - try to open it
    --skip_save_particle_in_cache # don't save particle to local cache in cid.md file #totest
]: [string -> string, nothing -> string] {
    let $text = if $text_param == null {} else {$text_param}
        | into string
        | if (
            $env.cy.pin_text_follow_file_path? == true or $follow_file_path
        ) and (
            path-exists-safe $in
        ) { open } else {}

    if not ($env.cy.pin_text_ignore_cid? == true or $ignore_cid) {
        if (is-cid $text) { return $text }
    }

    if $env.cy.pin_text_only_hash? == true or $only_hash {
        $text
        | ipfs add -Q --only-hash
        | str trim --char (char nl)
        | return $in
    }

    let $cid = if $env.cy.ipfs-storage in ['kubo' 'both'] {
            $text
            | ipfs add -Q
            | str trim --char (char nl)
        }
        | if $env.cy.ipfs-storage in ['cybernode' 'both'] {
            $text
            | curl --silent -X POST -F file=@- 'https://io.cybernode.ai/add'
            | from json
            | get cid -i
            | if $in == null {
                error make {msg: "cybernode didn't respond with cid. Check your internet" }
            } else {}
        } else { }

    if not $skip_save_particle_in_cache {
        let $path = $env.cy.ipfs-files-folder | path join $'($cid).md'

        if not ($path | path exists) {
            $text | save -r $path
        }
    }

    $cid
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
    --quiet (-q) # Don't output a cyberlink record after executing the command
    --only_hash # calculate hash only, don't pin anywhere
    --ignore_cid # work with CIDs as regular texts
    --follow_file_path # check if `text_param` is a valid path, and if yes - try to open it
] [nothing -> record, nothing -> nothing] {
    if $only_hash {$env.cy.pin_text_only_hash = true}
    if $ignore_cid {$env.cy.pin_text_ignore_cid = true}
    if $follow_file_path {$env.cy.pin_text_follow_file_path = true}

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
    let $elements = $in | default $rest | flatten
    let $count = $elements | length
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
    ...files: path # filenames of files to pin to the local ipfs node
    --link_filenames (-n) # Add filenames as a `from` link
    --include_extension # Include a file extension (works only with `--link_filenames`)
    --disable_append (-D) # Don't append links to the links table
    --quiet # Don't output results page
    --yes (-y) # Confirm uploading files without request
]: [nothing -> table, nothing -> nothing] {
    if (ps | where name =~ ipfs | is-empty) {
        error make {msg: "ipfs service isn't running. Try 'brew services start ipfs'" }
    }

    let $files_col = $files
        | if $in == [] {
            ls
            | where type == file
            | get name
            | where $it not-in ['desktop.ini' '.DS_Store']
        } else {
            path basename
        }
        | wrap from_text

    if (
        $env.cy.ipfs-upload-with-no-confirm? == true or
        $yes or
        (confirm --default_not $'Confirm uploading ($files_col | length) files?')
     ) { } else {return}

    let $results = $files_col
        | each {|f| $f
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

    if not $disable_append { $results | links-append --quiet }
    if not $quiet { $results }
}

# Link files hierarchy in the a specified or current folder
export def 'link-folder' [
    folder_path?: path # path to a folder to link files at
    --include_extension # Include a file extension (works only with `--link_filenames`)
    --disable_append (-D) # Don't append links to the links table
    --no_content # Use only directory and file names for cyberlinks, don't create cyberlinks to file contents
    --no_folders # Don't link folders to their child members (is not available if --no_content)
    --yes (-y) # Confirm uploading files without request
]: [nothing -> table] {
    let $path = $folder_path | default (pwd)

    if (
        $env.cy.ipfs-upload-with-no-confirm? == true or
        $yes or
        (confirm --default_not $'Confirm uploading ($path)')
     ) { } else {return}

    let $hashes = ^ipfs add $path --recursive --progress=false
        | lines
        | parse '{s} {cid} {path}'
        | reject s
        | insert file_type {|i| pwd | path dirname | path join $i.path | path type}
        | where file_type == file
        | where path !~ '(Identifier|Zone)'

    let $to_text_subst = $hashes
        | insert f {|i| $i.path | path basename | $'pinned_file:($in)'}
        | select cid f
        | transpose --ignore-titles --as-record --header-row

    $hashes
    | each {|i|
        $i.path
        | if $include_extension {} else {
            path parse | reject extension | path join
        }
        | path split
        | if $no_content {} else {
            if $no_folders {
                last
            } else {}
            | append $i.cid
        }
        | window 2
        | each {|p| {from_text: $p.0 to_text: $p.1}}
    }
    | flatten
    | uniq
    | links-pin-columns-2 --dont_replace --quiet
    | update to_text {|i| $to_text_subst | get -i $i.to_text | default $i.to_text}
    | if $disable_append {} else {links-append}
}

# Create a cyberlink according to semantic construction of following a neuron
#
# > cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
# from_text: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
# to_text: bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
# from: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
# to: QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af
export def 'follow' [
    neuron: string # neuron's address to follow
    --use_local_list_only # follow a neuron locally only
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

# Add a tweet and send it immediately (unless of `--disable_send`)
#
# > cy links-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
# from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to_text: cyber-prophet is cool
# from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK
export def 'tweet' [
    text_to?: string # text to tweet
    --disable_send (-D) # don't send tweet immediately, but put it into the temp table
]: [nothing -> record, string -> record] {
    let $text_to = if $text_to == null {} else {$text_to}
    let $cid_from = 'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx' # pin-text 'tweet'

    if $disable_send {
        link-texts $cid_from $text_to
    } else {
        set-links-table-name $'tweet_(now-fn)'

        link-texts $cid_from $text_to

        links-send-tx
    }
}

# Add a random chuck norris cyberlink to the temp table
def 'link-chuck' []: [nothing -> nothing] {
    let $quote = http get -e https://api.chucknorris.io/jokes/random
        | get value
        | $in + "\n\n" + 'via [Chucknorris.io](https://chucknorris.io)'

    cprint -f '=' --indent 4 $quote

    link-texts --quiet 'chuck norris' $quote
}

# Add a random quote cyberlink to the temp table
def 'link-quote' []: [nothing -> nothing] {
    let $quote = http get -e -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=text
        | $in + "\n\n" + 'via [forismatic.com](https://forismatic.com)'

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
    | each {
        match $source {
            'forismatic.com' => { link-quote }
            'chucknorris.io' => { link-chuck }
            _ => {error make {msg: $'unknown source ($source)'}}
        }
    }

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
    --quiet (-q) # Disable informational messages
    --no_timestamp # Don't output a timestamps column
]: [nothing -> table] {
    let $links = current-links-csv-path
        | if ($in | path exists) {
            open
            | if $no_timestamp { reject timestamp -i } else {}
        } else {
            []
        }

    if not $quiet {
        let $links_count = $links | length

        if $links_count == 0 {
            cprint $'The temp cyberlinks table *(current-links-csv-path)* is empty.
                You can add cyberlinks to it manually or by using commands like *"cy link-texts"*'
        } else {
            cprint $'There are *($links_count) cyberlinks* in the temp table:'
        }
    }

    let $links_columns = $links | columns

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
    --quiet (-q) # suppress output the resulted temp links table
]: [table -> table, table -> nothing, record -> table, record -> nothing] {
    upsert timestamp (now-fn)
    | prepend (links-view -q)
    | if $quiet { links-replace -q } else { links-replace }
}

# Replace the temp table with piped-in table
export def 'links-replace' [
    --quiet (-q) # suppress output the resulted temp links table
]: [table -> table, table -> nothing] {
    save (current-links-csv-path) --force

    if not $quiet { links-view -q }
}

# Swap columns from and to
export def 'links-swap-from-to' [
    --dont_replace (-D) # output results only, without modifying the links table
    --keep_original # append results to original links
]: [nothing -> table, table -> table] {
    let $input = inlinks-or-links

    $input
    | rename --block {
        if ($in | str starts-with 'from') {
            str replace 'from' 'to'
        } else {
            str replace 'to' 'from'
        }
    }
    | select -i from_text to_text from to ...($in | columns) # use it here for rearranging
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
    text: string # a text to upload to ipfs
    --dont_replace (-D) # don't replace the temp cyberlinks table, just output results
    --keep_original # append results to original links
    --column (-c): string = 'from' # a column to use for values ('from' or 'to'). 'from' is default
    --empty # fill cids in empty cells only
]: [nothing -> table, table -> table] {
    let $links = inlinks-or-links
    let $cid = pin-text $text

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
    --threads: int = 3 # A number of threads to use to pin particles
]: [nothing -> table, table -> table] {
    let $links = inlinks-or-links

    let $dict = $links.from_text?
        | append $links.to_text?
        | where $it not-in [null '']
        | if $in == [] {
            cprint 'No columns *"from_text"* or *"to_text"* found. Add at least one of them.'
            return
        } else {}
        | uniq
        | par-each -t $threads {|i| {$i: (pin-text $i)}}
        | reduce -f {} {|it acc| $acc | merge $it }

    $links
    | each {|i| $i
        | if $i.from_text? != null {
            upsert from ( $dict | get --ignore-errors --sensitive $i.from_text )
        } else {}
        | if $i.to_text? != null {
            upsert to ( $dict | get --ignore-errors --sensitive $i.to_text )
        } else {}
    }
    | if $dont_replace {} else { links-replace }
}

export def 'links-pin-columns-2' [
    --dont_replace (-D) # Don't replace the links cyberlinks table
    --pin_to_local_ipfs # Pin to local kubo
    --ignore_cid # work with CIDs as regular texts
    --skip_save_particle_in_cache # don't save particles to local cache in cid.md file
    --quiet (-q) # don't print information about tem folder
]: [nothing -> table, table -> table] {
    let $links = inlinks-or-links

    let $temp_ipfs_folder = cy-path temp ipfs_upload (now-fn) --create_missing

    let $groups = $links.from_text?
        | append $links.to_text?
        | where $it not-in [null '']
        | if $in == [] {
            cprint 'No columns *"from_text"* or *"to_text"* found. Add at least one of them.'
            return
        } else {}
        | uniq
        | if $ignore_cid {} else {
            group-by {if (is-cid $in) {'cid'} else {'not-cid'}}
        }

    let $lookup = $groups
        | if $ignore_cid {} else {
            get not-cid
        }
        | enumerate
        | into string index

    # Saving ininitial text files
    $lookup | each {|i| $i.item | save -r ($temp_ipfs_folder | path join $i.index)}

    if not $quiet {
        cprint $'temp files saved to a local directory *($temp_ipfs_folder)*'
    }

    mut $hash_associations = if (
            $env.cy.ipfs-upload-with-no-confirm? == true or
            $pin_to_local_ipfs or
            ( confirm $'Pin files to local kubo? If `no` only hashes will be calculated.' )
        ) {
            ^ipfs add $temp_ipfs_folder --progress=false --recursive
        } else {
            ^ipfs add $temp_ipfs_folder --progress=false --recursive --only-hash
        }
        | lines
        | drop # remove the root folder's cid
        | parse '{s} {cid} {path}'
        | upsert index {|i| $i.path | path basename}
        | join -l $lookup index
        | select cid item

    if not $skip_save_particle_in_cache {
        $hash_associations
        | each {|i|
            let $path = $env.cy.ipfs-files-folder | path join $'($i.cid).md'
            if not ($path | path exists) {
                $i.item | save $path
            }
        }
    }

    if (not $ignore_cid) and $groups.cid? != null {
        $hash_associations = (
            $groups.cid | wrap cid
            | merge ($groups.cid | wrap item)
            | append $hash_associations
        )
    }

    $links
    | reject -i from to # if text_from or text_to are absent, the resulting table is empty. Maybe use default?
    | join -l ($hash_associations | rename from from_text) from_text
    | join -l ($hash_associations | rename to to_text) to_text
    | if $dont_replace {} else { links-replace }
}

export def 'pin-file-or-folder-to-cybernode' [
    $path: path # the path to a folder or a file to pin
] {
    $env.cy.ipfs-storage = 'cybernode'

    let $paths = match ($path | path type) {
            'dir' => {glob ($path | path join '*')}
            'file' => {[$path]}
            _ => {error make {msg: $'($path) is not a dir or a file'}}
        }

    let $paths_length = $paths | length

    $paths
    | enumerate
    | par-each {|i|
        open -r $i.item | pin-text

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
    ^($env.cy.exec) query rank is-exist $from $to $neuron --output json --node $env.cy.rpc-address
    | complete
    | if $in.exit_code == 0 {
        get stdout | from json | get 'exist'
    } else {
        false
    }
}

# Remove existing cyberlinks from the temp cyberlinks table
export def 'links-remove-existed-1by1' [
    --all_links # check all links in the temp table
]: [nothing -> table, nothing -> nothing] {
    let $links_view = links-view -q
    let $links_per_trans = set-get-env links-per-transaction

    let $links_with_status = $links_view
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
            | upsert link_exist {|row|
                print $row.index

                link-exist $row.from $row.to $env.cy.address
            }
        }
        | sort-by index

    let $existed_links = $links_with_status
        | where link_exist?

    let $existed_links_count = $existed_links | length

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

    let $existing_links = graph-links-df
        | polars filter-with ((polars col neuron) == $env.cy.address)
        | polars select particle_from particle_to
        | polars with-column (polars lit true | polars as duplicate)
        | polars into-lazy

    links-view
    | polars into-lazy
    | polars join --left $existing_links [from to] [particle_from particle_to]
    | polars filter-with (polars col duplicate | polars is-not-null)
    | polars drop duplicate
    | polars collect
    | polars into-nu
    | links-replace
}


# Create a custom unsigned cyberlinks transaction
def 'tx-json-create-from-cyberlinks' [
    $links # removed type definition for the case of empty tables
]: table -> path {
    let $links = $links | select from to | uniq
    let $path = cy-path temp transactions --file $'($env.cy.address)-(now-fn)-cyberlink-unsigned.json'

    tx-message-links $env.cy.address $links
    | tx-create $in
    | save $path --force

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
            amount: ($h_amount | into string)
        },
        resource: $resource,
        length: ($length | into string)
    }
}

def 'tx-message-links' [
    $neuron
    $links_table: table<from: string, to: string> # [[from, to]; ["", ""]]
] {
    {
        @type: "/cyber.graph.v1beta1.MsgCyberlink",
        neuron: $neuron,
        links: $links_table
    }
}

def 'tx-create' [
    message?
    --memo: string = 'cy'
    --gas = 23456789
    --fee = 0
    --timeout_height = 0
]: [record -> record, list -> record] {
    let msg = $message | describe
        | if ($in =~ '^list') {
            $message
        } else if ($in =~ '^record') {
            [$message]
        } else {
            error make {msg: $'Message should be record or list. Received ($in)'}
        }

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

def 'tx-authz' [ ]: path -> path {
    let $json_tx_path = $in
    let $out_path = $json_tx_path | path-modify --suffix 'authz'

    let $current_json = open $json_tx_path

    $current_json
    | upsert body.messages.neuron $env.cy.authz
    | upsert body.messages {|i| [ {
        "@type": "/cosmos.authz.v1beta1.MsgExec",
        "grantee": $current_json.body.messages.neuron.0
        "msgs": $i.body.messages
    } ] }
    | to json -r
    | save --raw --force $out_path

    $out_path
}

def 'tx-sign' [ ]: path -> path {
    let $unsigned_tx_path = $in
    let $out_path = $unsigned_tx_path | path-modify --suffix 'signed'
    let $params = [
            --from $env.cy.address
            --chain-id $env.cy.chain-id
            --node $env.cy.rpc-address
            --output-document $out_path
        ]
        | if $env.cy.keyring-backend? == 'test' {
            append ['--keyring-backend' 'test']
        } else {}

    let $response = ^($env.cy.exec) tx sign $unsigned_tx_path ...$params
        | complete

    if $response.exit_code != 0 {
        $response.stderr
        | lines
        | first
        | error make --unspanned {msg: $in}
    }

    $out_path
}

def 'tx-broadcast' []: path -> record {
    ^($env.cy.exec) tx broadcast $in ...[
        --broadcast-mode block
        --output json
        --node $env.cy.rpc-address
    ]
    | complete
    | if ($in.exit_code != 0 ) {
        error make { msg: 'exit code is not 0' }
    } else {
        get stdout | from json | select raw_log code txhash
    }
}

# Create a tx from the piped in or temp cyberlinks table, sign and broadcast it
#
# > cy links-send-tx | to yaml
# cy: 2 cyberlinks should be successfully sent
# code: 0
# txhash: 9B37FA56D666C2AA15E36CDC507D3677F9224115482ACF8CAF498A246DEF8EB0
def 'links-send-tx' [ ] {
    let $links = links-view -q
        | first $env.cy.links-per-transaction

    let $response = tx-json-create-from-cyberlinks $links
        | if ($env.cy.authz? != null) {
            tx-authz
        } else {}
        | tx-sign
        | tx-broadcast

    if $response.code == 0 {
        let $filename = cy-path mylinks _cyberlinks_archive.csv

        let $header = open $filename | first

        $header
        | append ( $links | upsert neuron $env.cy.address )
        | fill non-exist
        | skip
        | to csv --noheaders
        | save $filename --append --raw

        links-view -q
        | skip $env.cy.links-per-transaction
        | links-replace

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
    let $links = inlinks-or-links

    let $filtered = $links
        | where (is-cid ($it.from? | default ''))
        | where (is-cid ($it.to? | default ''))
        | where $it.from != $it.to
        | uniq-by from to

    let $filtered_length = $filtered | length
    let $diff_length = ($links | length) - $filtered_length

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
    | $in // (set-get-env links-per-transaction $links_per_trans)
    | seq 0 $in
    | each {links-send-tx}
}

def 'inlinks-or-links' []: [nothing -> table, table -> table] {
    if $in == null {links-view -q} else {}
    | fill non-exist -v null
}

# send message to neuron with (in 1boot transaction with memo)
export def 'message-send' [
    $neuron: string
    $message: string
    --amount: string = 1boot
    --from: string
] {
    let $from = $from | default $env.cy.address

    ^$env.cy.exec tx bank send $from $neuron $amount --note (pin-text $message) --output json
    | from json
}

# Output neurons dict
export def 'dict-neurons-view' [
    --df # output as a dataframe
    --path # output path of the dict
    --karma_bar # output karma bar
] {
    let $neurons_tags = dict-neurons-tags --wide

    cy-path graph neurons_dict.yaml
    | if $path {
        return $in
    } else {}
    | if ($in | path exists) {
        open
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
        | polars into-df
    } else { }
}

# Add piped in neurons to YAML-dictionary with tag and category
export def 'dict-neurons-add' [
    tag: string = '' # tag to add to neuron
    --category: string = 'default' # category of tag to write to dict
] {
    let $input = $in
    let $desc = $input | describe
    let $path_csv = cy-path graph neurons_dict_tags.csv

    if $input == null {
        error make {
            msg: 'you should pipe a list, a table or a dataframe containing `neuron` column to this command'
        }
    }

    let $candidate = $input
        | if ($desc == 'list<string>') {
            wrap neuron
        } else if ($desc == 'dataframe') {
            polars into-nu
        } else if ($desc == 'string') {
            [{neuron: $in}]
        } else { }
        | select neuron

    let $validated_neurons = $candidate
        | where (is-neuron $it.neuron)

    $validated_neurons
    | upsert tag $tag
    | upsert category $category
    | upsert timestamp (date now | debug)
    | if ($path_csv | path exists) {
        to csv --noheaders
    } else {
        to csv
    }
    | save --raw --append $path_csv
}

# Output dict-neurons tags
export def 'dict-neurons-tags' [
    --path # return the path of tags file
    --wide # return wide table with categories as columns
    --timestamp # output the timestamp of the last neuron's update
] {
    let $path_csv = cy-path graph neurons_dict_tags.csv
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
    let $dict_n_tags_path = cy-path graph neurons_dict_tags.csv

    $dict_n_tags_path
    | if ($in | path exists) {
        open
        | if ($in | columns | 'value' in $in) {
            rename -c {value: tag}
            | save -f $dict_n_tags_path

            print $'($dict_n_tags_path) updated'
        }
    }
}

# Update neurons YAML-dictionary
export def 'dict-neurons-update' [
    --passport # Update passport data
    --balance # Update balances data
    --karma # Update karma
    --all (-a) # Update passport, balance, karma
    --neurons_from_graph # Update info for neurons from graph, and not from current dict
    --threads (-t) = 30 # Number of threads to use for downloading
    --dont_save # Don't update the file on a disk, just output the results
    --quiet (-q) # Don't output results table
] {
    if $neurons_from_graph {
        graph-links-df
        | polars select neuron
        | polars unique
        | polars join --left (dict-neurons-view --df) neuron neuron
        | polars into-nu
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
                | transpose --ignore-titles --as-record --header-row
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
        | save -f (cy-path graph neurons_dict.yaml | backup-and-echo)

        $input
    }
    | if $quiet { null } else { }
}

export def 'authz-give-grant' [
    $neuron # an address of a neuron
    $message_type: string@"nu-complete-authz-types"
    $expiration: duration
] {
    let $path = cy-path temp transactions --file $'($env.cy.address)-authz-(now-fn).json'

    (
        ^$env.cy.exec tx authz grant $neuron generic --msg-type $message_type
        --from $env.cy.address
        --expiration (date now | $in + $expiration | format date '%s' | into int)
        --generate-only
        ...(default-node-params)
    ) | save $path

    $path
    | tx-sign
    | tx-broadcast
}

# query neuron addrsss by his nick
export def 'qnbn' [
    ...nicks: string@'nicks-and-keynames'
    --df
    --force_list_output (-f)
] {
    let $dict_nicks = nicks-and-keynames
        | select value description
        | rename name neuron

    let $addresses = $nicks | where (is-neuron $it) | wrap neuron

    let $neurons = if ($nicks | where not (is-neuron $it) | is-empty) {
            []
        } else {
            $dict_nicks
            | where name in $nicks
            | select neuron
            | uniq-by neuron
        }

    $neurons
    | append $addresses
    | if $df {
        polars into-df
    } else if ($in | length) == 1 and not $force_list_output {
        get neuron.0
    } else {}
}

# An ordered list of cy commands
export def 'help-cy' [] {
    cy-path cy.nu
    | open --raw
    | parse -r "(\n# (?<desc>.*?)(?:\n#[^\n]*)*\nexport def(:? --(:?env|wrapped))* '(?<command>.*)')"
    | select command desc
    | upsert command {|row index| ('cy ' + $row.command)}
}

def --env is-connected-interval [
    interval = 1min
] {
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

# echo particle for publishing
export def 'echo_particle_txt' [
    i: record
    --markdown (-m)
] {
    let $indent = $i.step? | default 0 | into int | $in * 4 | $in + 12

    if $i.content_s? == null {
        $'⭕️ ($i.timestamp), ($i.nick) - timeout - ($i.particle)'
    } else {
        $'🟢 ($i.timestamp), ($i.nick)(char nl)(char nl)($i.content_s)(char nl)(char nl)($i.particle)(char nl)(char nl)'
    }
    | mdcat -l --columns (80 + $indent) -
    | print
    # | each {|b| $"((ansi grey) + ($i.step + 2 | into string) + (ansi reset) | str repeat $indent)($b)" | print $in}
}
