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
    let $json = if (is-neuron $address_or_nick) {
            {"active_passport":{"address":$address_or_nick}}
        } else {
            {"passport_by_nickname":{"nickname":$address_or_nick}}
        }
        | to json -r

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    let $params = ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']

    ( caching-function query wasm contract-state smart $pcontract $json ...$params
        --retries 0 --exec 'cyber' --no_default_params )
    | if $in == null {
        if not $quiet { # to change for using $env
            cprint --before 1 --after 2 $'No passport for *($address_or_nick)* is found'
        }

        return {nickname: '?'}
    } else {
        get data
        | merge $in.extension
        | reject extension approvals token_uri
    }
}

# Set a passport's particle, data or avatar field for a given nickname
#
# > cy passport-set QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
# The particle field for maxim should be successfully set to QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
export def 'passport-set' [
    cid: string # cid to set
    nickname? # Provide a passport's nickname. If null - the nick from config will be used.
    --field: string = 'particle' # A passport's field to set: particle, data, new_avatar
    --verbose # Show the node's response
] {
    if not (is-cid $cid) {
        print $"($cid) doesn't look like a cid"
        return
    }

    if $field not-in ['particle', 'data', 'new_avatar'] {
        print $'The field must be "particle", "data" or "new_avatar". You provided ($field)'
        return
    }

    let $nick = $nickname
        | default $env.cy.passport-nick?
        | if ($in | is-empty) {
            print 'there is no nickname for passport set. To update the fields we need one.'
            return
        } else {}

    let $json = $'{"update_data":{"nickname":"($nick)","($field)":"($cid)"}}'

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'

    let $params = [
            '--from' $env.cy.address
            '--node' 'https://rpc.bostrom.cybernode.ai:443'
            '--output' 'json'
            '--yes'
            '--broadcast-mode' 'block'
            '--gas' '23456789'
            '--chain-id' 'bostrom'
        ]
        | if $env.cy?.keyring-backend? == 'test' {
            append ['--keyring-backend' 'test']
            | flatten
        } else {}

    if $verbose {
        print $'^cyber tx wasm execute ($pcontract) ($json) ($params | str join " ")'
    }

    ^cyber tx wasm execute $pcontract $json ...$params
    | complete
    | if $in.exit_code == 0 {
        if $verbose {
            get stdout
            | from json
            | upsert raw_log {|i| $i.raw_log | from json}
            | select raw_log code txhash
        } else {
            cprint $'The *($field)* field for *($nick)* should be successfully set to *($cid)*'
        }
    } else {
        cprint $'The cid might not be set. You can check it with the command
        "*cy passport-get ($nick) | get ($field) | $in == ($cid)*"'
    }
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

# Download a snapshot of cybergraph
export def --env 'graph-download-snapshot' [
    --disable_update_parquet (-D) # Don't update the particles parquet file
    --neuron: string = 'graphkeeper'
] {
    set-cy-setting caching-function-force-update 'true'
    let $cur_data_cid = passport-get $neuron | get data -i
    set-cy-setting caching-function-force-update 'false'
    let $path = cy-path --create_missing graph $neuron

    let $update_info = $path
        | path join update.toml
        | if ($in | path exists) {open} else {{}}

    let $last_data_cid = $update_info | get -i last_cid

    if ($last_data_cid == $cur_data_cid) {
        print 'no updates found'
        return
    }

    print '' 'Downloading cyberlinks.csv'
    ipfs get $'($cur_data_cid)/graph/cyberlinks.csv' -o $path

    # print '' 'Downloading cyberlinks.csv'
    # ipfs get $'($cur_data_cid)/graph/cyberlinks_contracts.csv' -o $path

    let $dict_name = 'neurons_dict.yaml'
    let $dict_path = $path | path join neurons_dict.yaml
    print '' $'Downloading ($dict_name)'

    ipfs cat $'($cur_data_cid)/graph/neurons_dict.yaml'
    | from yaml
    | if ($dict_path | path exists) {
        prepend (open $dict_path)
        | uniq-by neuron
    } else {}
    | save -f $dict_path

    print '' 'Downloading particles zips'
    ipfs get $'($cur_data_cid)/graph/particles/' -o $'($path)/particles_arch/'

    let $archives = ls ($path | path join particles_arch/*.zip | into glob) | get name
    let $last_archive = $update_info
        | get -i last_archive
        | default ($archives | first)

    cprint 'Unpacking particles archive(s)'

    $archives
    | skip until {|x| $x == $last_archive}
    | each {
        |i| ^unzip -ojq $i -d ($path | path join particles safe)

        cprint $'*($i)* is unzipped'
    }

    let $path_toml = $path | path join update.toml

    $path_toml
    | if ($in | path exists) {
        open
    } else {{}}
    | upsert 'last_cid' $cur_data_cid
    | upsert 'last_archive' ($archives | last)
    | save -f $path_toml

    cprint $'The graph data has been downloaded to the *"($path)"* directory'

    # if (not $disable_update_parquet) {
    #     print 'Updating particles parquet'
    #     graph-update-particles-parquet
    # }
}

def graph_columns [] {
    ['particle_from' 'particle_to' 'neuron' 'height' 'timestamp']
}

def get_links_hasura [
    height: int
    multiplier: int
    --chunk_size: int = 1000
] {
    $"{cyberlinks\(limit: ($chunk_size), offset: ($multiplier * $chunk_size), order_by: {height: asc},
        where: {height: {_gt: ($height)}}) {(graph_columns | str join ' ')}}"
    | {'query': $in}
    | http post -t application/json $env.cy.indexer-graphql-endpoint $in
    | get data.cyberlinks
}

def 'get_links_clickhouse' [
    height: int
    multiplier: int
] {
    let $url = set-get-env 'indexer-clickhouse-endpoint'
    let $auth = set-get-env 'indexer-clickhouse-auth'
    let $chunk_size = set-get-env 'indexer-clickhouse-chunksize'

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
        | save -r $path_csv

        0
    }
}

# Download the latest cyberlinks from a hasura cybernode endpoint
export def 'graph-receive-new-links' [
    filename?: string@'nu-complete-graph-csv-files' # graph csv filename in the 'cy/graph' folder
    --source: string@'nu-complete-graph-provider' = 'hasura'
] {
    let $cyberlinks_path = set-get-env cyberlinks-csv-table $filename
    let $path_csv = cy-path graph $cyberlinks_path
    let $last_height = graph_csv_get_last_height $path_csv

    mut $new_links_count = 0

    cprint $'Downloading using ($source)'

    for $mult in 0.. {
        let $links = if $source == 'hasura' {
                get_links_hasura $last_height $mult
            } else if $source == 'clickhouse' {
                get_links_clickhouse $last_height $mult
            }

        $new_links_count += ($links | length)

        if $links != [] {
            $links | to csv --noheaders | save --raw --append $path_csv

            cprint -a 0 $'(char cr)Since the last update (char lp)which was on ($last_height
                ) height(char rp) ($new_links_count) cyberlinks received!'
        } else {
            break
        }
    }
    print ''
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

    let $follow_list = dict-neurons-tags | where tag == follow | get neuron
    let $block_list = dict-neurons-tags | where tag == block | get neuron

    let $particles = graph-links-df
        | if $whole_graph {} else {
            if ($follow_list | is-empty) {
                let $input = $in

                cprint "You don't have any neurons tagged `follow`, so we'll download only missing particles that
                `maxim` (the hot key of `cyber-prophet`). If you want to download all the missing particles for
                the whole cybergraph you can use the command: *graph-download-missing-particles --whole_graph*.
                If you want to add tag `follow` to some neurons you can use the command:
                *'bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8' | dict-neurons-add follow*"

                $input
                | polars filter-with (
                    (polars col neuron)
                    | polars is-in ['bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8']
                )
            } else {
                polars filter-with (
                    (polars col neuron)
                    | polars is-in $follow_list
                )
            }
        }
        | if ($block_list | is-empty) {} else {
            polars filter-with ((polars col neuron) | polars is-in $block_list | polars expr-not)
        }
        | graph-to-particles
        | graph-add-metadata
        | particles-filter-by-type --timeout
        | print-and-pass
        | polars select particle
        | polars into-nu
        | get particle

    $particles | each {queue-cid-add $in}

    cprint --before 1 $'($particles | length) cids are added into queue'

    queue-cids-download
}

# filter system particles out
export def 'graph-filter-system-particles' [
    column = 'particle' # the column to look for system cids
    --exclude
] {
    polars filter-with (
        (polars col $column)
        | polars is-in (system_cids)
        | if $exclude {polars expr-not} else {}
    )
}

# merge two graphs together, add the `source` column
export def 'graph-merge' [
    df2
    --source_a: string = 'a'
    --source_b: string = 'b'
] {
    let $input = if ($in | polars columns | 'source' in $in) { } else {
        polars with-column (polars lit $source_a | polars as source)
    }

    let $df2_st = $df2
        | if ($df2 | polars columns | 'source' in $in) { } else {
            polars with-column (polars lit $source_b | polars as source)
        }

    $input
    | polars join $df2_st [particle_from particle_to neuron] [particle_from particle_to neuron] --full
    | polars with-column (
        polars when ((polars col source) | polars is-null) (polars col source_x)
        | polars when ((polars col source_x) | polars is-null) (polars col source)
        | polars otherwise (polars concat-str '-' [(polars col source) (polars col source_x)])
        | polars as source
    )
    | polars with-column (
        polars when ((polars col particle_from) | polars is-null) (polars col particle_from_x)
        | polars otherwise (polars col particle_from) | polars as particle_from
    )
    | polars with-column (
        polars when ((polars col particle_to) | polars is-null) (polars col particle_to_x)
        | polars otherwise (polars col particle_to) | polars as particle_to
    )
    | polars with-column (
        polars when ((polars col neuron) | polars is-null) (polars col neuron_x)
        | polars otherwise (polars col neuron) | polars as neuron
    )
    | polars with-column (
        polars when ((polars col height) | polars is-null) (polars col height_x)
        | polars otherwise (polars col height) | polars as height
    )
    | polars with-column (
        polars when ((polars col timestamp) | polars is-null) (polars col timestamp_x)
        | polars otherwise (polars col timestamp) | polars as timestamp
    )
    | polars drop particle_from_x particle_to_x neuron_x height_x timestamp_x source_x
}

# Output unique list of particles from piped in cyberlinks table
#
# > cy graph-to-particles --include_global | polars into-nu | first 2 | to yaml
# - index: 0
#   particle: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05T14:11:41
#   init-role: from
#   neuron_global: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height_global: 490
#   timestamp_global: 2021-11-05T14:11:41
#   content_s: cyber|QK3oufV
# - index: 1
#   particle: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05T14:11:41
#   init-role: to
#   neuron_global: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height_global: 490
#   timestamp_global: 2021-11-05T14:11:41
#   content_s: fuckgoogle!|z3YWjy6
export def 'graph-to-particles' [
    --from # Use only particles from the 'from' column
    --to # Use only particles from the 'to' column
    --include_global # Include column with global particles' df (that includes content)
    --include_particle_index # Include local 'particle_index' column
    --cids_only (-c) # Output one column with CIDs only
    # --init_role # Output if particle originally was in 'from' or 'to' column
] {
    let $links = graph-links-df

    let $links_columns = $links | polars columns
    if $to and $from {
        error make {msg: 'you need to use only "to", "from" or none flags at all, none both of them'}
    }

    def graph-to-particles-keep-column [
        c
        --column: string
    ] {
        $links
        | polars rename $'particle_($column)' particle
        | polars drop $'particle_(col-name-reverse $column)'
        | polars with-column [
            (polars lit ($column) | polars as 'init-role'),
        ]
    }

    let $dummy = $links
        | polars rename particle_from particle
        | polars drop particle_to
        | polars with-column (polars lit 'a' | polars as 'init-role')
        | polars fetch 0 # Create dummy polars to have something to appended to

    $dummy
    | if not $to {
        polars append --col (
            graph-to-particles-keep-column $links --column from
        )
    } else {}
    | if not $from {
        polars append --col (
            graph-to-particles-keep-column $links --column to
        )
    } else {}
    | if ('link_local_index' in $links_columns) {
        polars sort-by [link_local_index height]
    } else {
        polars sort-by [height]
    }
    | polars into-lazy
    | polars unique --subset [particle]
    | polars collect
    | if $cids_only {
        polars select particle
    } else {
        if $include_particle_index {
            polars with-column (
                polars arg-where ((polars col height) != 0) | polars as particle_index
            )
        } else {}
        | if $include_global {
            polars join (graph-particles-df) particle particle -s '_global'
        } else {}
    }
}

# In the piped in particles df leave only particles appeared for the first time
export def 'particles-keep-only-first-neuron' [ ] {
    polars join -s '_global' (
        graph-particles-df
        | polars select particle neuron
    ) particle particle
    | polars with-column (($in.neuron) == ($in.neuron_global)) --name 'is_first_neuron'
    | polars filter-with (polars col is_first_neuron)
    | polars drop neuron_global is_first_neuron
}

# Update the 'particles.parquet' file (it includes content of text files)
export def 'graph-update-particles-parquet' [
    --quiet (-q) # Disable informational messages about the saved parquet file
    --all # re-read all downloaded particles
] {
    let $parquet_path = cy-path graph particles.parquet
    let $particles_folder = $env.cy.ipfs-files-folder
    let $all_particles = graph-links-df
        | graph-to-particles
        | graph-add-metadata
        | polars select [particle neuron height timestamp content_s]

    let $particles_wanted = $all_particles
        | if $all {} else {
            particles-filter-by-type --timeout
        }

    if not $quiet {
        cprint $'Cy is updating ($parquet_path). It will take a coulple of minutes.'
    }

    let $particles_on_disk = glob ($particles_folder | path join '*.md') | path basename

    let $particles_to_open = $particles_wanted
        | polars with-column ((polars concat-str '.' [(polars col particle) (polars lit 'md')]) | polars as name)
        | polars join ($particles_on_disk | wrap name | polars into-df) name name
        | polars select name
        | polars into-nu
        | select name

    let $downloaded_particles = $particles_to_open
        | upsert content_s {
            |i| open -r ($particles_folder | path join $i.name)
            | str substring -g 0..160
        }
        | polars into-df
        | polars with-column (
            $in.name
            | polars str-slice 0 -l 46
        )
        | polars rename name particle
        | polars with-column (
            $in.content_s
            | polars str-slice 0 -l 150
            | polars replace-all -p (char nl) -r '⏎'
        )

    $particles_wanted
    | polars drop 'content_s'
    | polars join --left $downloaded_particles particle particle
    | polars with-column (
        $in.content_s
        | polars fill-null 'timeout|'
    )
    | polars collect
    | polars with-column ( # short name to make content_s unique
        $in.particle
        | polars str-slice 39 # last 7 symbols of 46-symbol cid
        | polars rename particle short_cid
    )
    | polars with-column (
        polars concat-str '|' [(polars col content_s) (polars col short_cid)]
    )
    | polars drop short_cid
    | if $all {} else {
        polars append --col (
            $all_particles
            | particles-filter-by-type --exclude --timeout
        )
    }
    | polars sort-by height particle
    | polars to-parquet ($parquet_path | backup-and-echo --mv)
    | print $in.0?
}

# Filter the graph to chosen neurons only
export def 'graph-filter-neurons' [
    ...neurons_nicks: string@'nu-complete-neurons-nicks'
] {
    let $links = graph-links-df

    $neurons_nicks
    | polars into-df
    | polars join ( dict-neurons-view --df ) '0' nick
    | polars select neuron
    | polars join ( $links ) neuron neuron
}

# Filter the graph to keep or exclude links from contracts
export def 'graph-filter-contracts' [
    --exclude
] {
    graph-links-df
    | polars filter-with (
        $in.neuron =~ '.{64}'
        | if $exclude {polars not} else {}
    )
}

# Append related cyberlinks to the piped in graph
export def 'graph-append-related' [
    --only_first_neuron (-o)
] {
    let $links_in = graph-keep-standard-columns-only --extra_columns ['link_local_index' 'init-role' 'step']
    let $columns_in = $links_in | polars columns
    let $step = if 'step' in $columns_in {
            $links_in.step | polars max | polars into-nu | get 0.step | ($in // 2) + 1 | ($in * 2) - 1
        } else {
            1
        }

    let $links = $links_in
        | if 'link_local_index' in $columns_in {} else {
            polars with-column [
                (polars arg-where ((polars col height) != 0) | $in + 100_000_000 | polars as link_local_index),
            ]
            | polars with-column (polars concat-str '' [(polars col link_local_index) (polars lit '')])
        }
        | if 'init-role' in $columns_in {} else {
            polars with-column (polars lit 'base' | polars as 'init-role')
        }
        | if 'step' in $columns_in {} else {
            polars with-column (polars lit 0 | polars as 'step')
        }

    def append_related [
        from_or_to: string
        --step: int
    ] {
        $links
        | graph-to-particles
        | if $only_first_neuron {
            particles-keep-only-first-neuron
        } else {}
        | polars select particle link_local_index init-role step
        | polars rename particle $'particle_($from_or_to)'
        | polars join (
            graph-links-df --not_in
            | graph-filter-system-particles particle_from --exclude
        ) $'particle_($from_or_to)' $'particle_($from_or_to)'
        | polars with-column [
            (polars concat-str '-' [
                (polars col 'link_local_index')
                (polars col 'init-role')
                (polars col $'particle_($from_or_to)')
                (polars lit ($from_or_to))
                (polars col $'particle_(col-name-reverse $from_or_to)')
            ]),
            ((polars col step) + (if $from_or_to == from {1} else {-1}))
        ]
    }

    $links
    | polars append --col (append_related from --step ($step))
    | polars append --col (append_related to --step ($step + 1))
    | polars sort-by [link_local_index height]
    | polars into-lazy
    | polars unique --subset [particle_from particle_to]
    | polars collect
}

# Output neurons stats based on piped in or the whole graph
export def 'graph-neurons-stats' [] {
    let $links = graph-links-df
    let $p = graph-particles-df

    let $follows = [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | polars into-df
        | polars join --left $links particle particle_from
        | polars group-by neuron
        | polars agg [
            (polars col timestamp | polars count | polars as 'follows')
        ]
        | polars sort-by follows --reverse [true]

    let $followers = [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | polars into-df
        | polars join --left $links particle particle_from
        | polars join $p particle_to particle --suffix '2' # it was working before `polars` 0.94
        | polars with-column (
            $in | polars select content_s | polars replace -p '\|.*' -r ''
        )
        | polars group-by content_s
        | polars agg [
            (polars col timestamp | polars count | polars as 'followers')
        ]
        | polars rename content_s neuron

    let $tweets = [['particle'];['QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx']] # tweet
        | polars into-df
        | polars join --left $links particle particle_from
        | polars group-by neuron
        | polars agg [
            (polars col timestamp | polars count | polars as 'tweets')
        ]

    $links
    | polars group-by neuron
    | polars agg [
        (polars col timestamp | polars count | polars as 'links_count')
        (polars col timestamp | polars min | polars as 'first_link')
        (polars col timestamp | polars max | polars as 'last_link')
    ]
    | polars sort-by links_count --reverse [true] # cygraph neurons activity
    | polars join --left $followers neuron neuron
    | polars join --left $follows neuron neuron
    | polars join --left $tweets neuron neuron
    | polars fill-null 0
    | polars join --left ( dict-neurons-view --df --karma_bar) neuron neuron
    | polars select ($in | polars columns | prepend [nickname links_count last_link] | uniq)
    | polars collect
}

# Output graph stats based on piped in or the whole graph
export def 'graph-stats' [] {
    let $links = graph-links-df | polars with-column (polars lit a | polars as dummyc)
    let $p = graph-particles-df
    let $p2 = $links | graph-to-particles | graph-add-metadata

    def dfr_countrows [] {
        polars with-column (polars lit 1) | polars select literal | polars sum | polars into-nu | get literal.0
    }

    let $n_links_unique = $links
        | polars into-lazy
        | polars unique --subset [particle_from particle_to]
        | polars collect
        | dfr_countrows

    let $n_particles_unique = $p2 | dfr_countrows

    let $n_particles_not_downloaded = $p2
        | particles-filter-by-type --timeout
        | dfr_countrows

    let $n_particles_non_text = $p2
        | polars filter-with ($in.content_s =~ '^"MIME type"')
        | dfr_countrows

    let $follows = $links
        | polars filter-with (
            (polars col particle_from)
            | polars is-in ['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx'] # follow
        )
        | dfr_countrows

    let $tweets = $links
        | polars filter-with (
            (polars col particle_from)
            | polars is-in ['QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx'] # tweet
        )
        | dfr_countrows

    let $stats_by_source = if ($links | polars columns | 'source' in $in) {
            $links
            | polars group-by source
            | polars agg [(polars col source | polars count | polars as source_count)]
            | polars sort-by source
            | polars into-nu
            | transpose --ignore-titles --as-record --header-row
            | {source: $in}
        } else {{}}

    $links
    | polars group-by dummyc
    | polars agg [
        (polars col neuron | polars n-unique | polars as 'neurons')
        (polars col timestamp | polars count | polars as 'links')
        (polars col timestamp | polars min | polars as 'first')
        (polars col timestamp | polars max | polars as 'last')
    ]
    | polars collect
    | polars into-nu
    | reject dummyc
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
}

# Export a graph into CSV file for import to Gephi
export def 'graph-to-gephi' [] {
    let $links = graph-links-df
    let $particles = $links
        | graph-to-particles --include_global

    let $t1_height_index = $links.height
        | polars append --col $particles.height # Particles might be created before they appear in the filtered graph
        | polars unique
        | polars with-column (
            polars arg-where ((polars col height) != 0) | polars as height_index
        )

    let $height_index_max = $t1_height_index
        | polars shape
        | polars into-nu
        | get rows.0

    $links
    | polars join --left $t1_height_index height height
    | polars with-column (
        polars concat-str '' [
            (polars lit '<[')
            (polars col height_index)
            (polars lit ($',($height_index_max)]>'))
        ]
        | polars as Timeset
    )
    | polars rename [particle_from particle_to] [source target]
    | polars to-csv (cy-path export !gephi_cyberlinks.csv)

    $particles
    | polars join --left $t1_height_index height height
    | polars with-column (
        (polars col particle) | polars as cid
    ) | polars rename [particle content_s] [id label]
    | polars with-column (
        polars concat-str '' [
            (polars lit '<[')
            (polars col height_index)
            (polars lit ($',($height_index_max)]>'))
        ]
        | polars as Timeset
    )
    | polars into-nu
    | move id label cid --before height
    | save -f (cy-path export !gephi_particles.csv)
}

# Logseq export WIP
export def 'graph-to-logseq' [
    # --path: string
] {
    let $links = graph-links-df | print-and-pass
    let $particles = $links
        | graph-to-particles --include_global
        | print-and-pass

    let $path = cy-path export $'logseq_(now-fn)'
    mkdir ($path | path join pages)
    mkdir ($path | path join journals)

    $particles
    | polars into-nu
    | par-each {|p|
        # print $p.particle
        $"author:: [[($p.nick)]]\n\n- (
            do -i {open ($env.cy.ipfs-files-folder | path join $'($p.particle).md')
            | default "timeout"
        } )\n- --- \n- ## cyberlinks from \n" |
        save ($path | path join pages $'($p.particle).md')
    }

    $links
    | polars into-nu
    | each {|c|
        $"\t- [[($links.particle_to)]] ($links.height) [[($links.nick?)]]\n" |
        save -a ($path | path join pages $'($links.particle_from).md')
    }
}

# Output particles into txt formatted feed
export def 'graph-to-txt-feed' [] {
    graph-to-particles
    | particles-keep-only-first-neuron
    | graph-add-metadata
    # | polars filter-with ($in.content_s | polars is-null | polars not)
    | polars sort-by [height]
    | polars into-nu
    | each {|i| echo_particle_txt $i}
}

# Export piped-in graph to a CSV file in cosmograph format
export def 'graph-to-cosmograph' [] {
    graph-add-metadata
    | polars rename timestamp time
    | polars select ($in | polars columns | prepend [content_s_from content_s_to] | uniq)
    | polars into-nu
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
    graph-add-metadata --escape_quotes --new_lines
    | polars select 'content_s_from' 'content_s_to'
    | $in.content_s_from + ' -> ' + $in.content_s_to + ';'
    | polars into-nu
    | rename links
    | get links
    | str join (char nl)
    | "digraph G {\n" + $options + "\n" + $in + "\n}"
    | if $preset == '' { } else {
        let $input = $in
        let $filename = cy-path export $'graphviz_($preset)_(now-fn).svg'

        let $params = ['-Tsvg' $'-o($filename)']

        $input | ^($preset) ...$params
        $filename
    }
}

# Add content_s and neuron's nicknames columns to piped in or the whole graph df
#
# > cy graph-filter-neurons maxim@n6r76m8 | cy graph-add-metadata | dfr into-nu | first 2 | to yaml
# - index: 0
#   nick: maxim@n6r76m8
#   height: 87794
#   content_s_from: tweet|R5V4Rvx
#   content_s_to: '"MIME type" = "image/svg+xml"⏎Size = "79336"⏎|6wZUHYo'
#   timestamp: 2021-11-11 10:36:24
#   particle_to: QmaxuSoSUkgKBGBJkT2Ypk9zWdXor89JEmaeEB66wZUHYo
#   particle_from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
#   neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
# - index: 1
#   nick: maxim@n6r76m8
#   height: 88371
#   content_s_from: avatar|TwBrmTs
#   content_s_to: '"MIME type" = "image/svg+xml"⏎Size = "68266"⏎|95aKr4t'
#   timestamp: 2021-11-11 11:31:54
#   particle_to: QmYnLm5MFGFwcoXo65XpUyCEKX4yV7HbCAZiDZR95aKr4t
#   particle_from: Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs
#   neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
export def 'graph-add-metadata' [
    --escape_quotes
    --new_lines
] {
    let $links = graph-links-df
        | graph-keep-standard-columns-only --extra_columns [
            'particle', 'link_local_index', 'init-role', 'step'
        ]

    let $p = graph-particles-df
        | polars select particle content_s
        | if $escape_quotes {
            polars with-column (
                $in.content_s
                | polars replace-all --pattern '"' --replace '\"'
                | polars replace-all --pattern '^(.*)$' --replace '"$1"'
            )
        } else {}
        | if $new_lines {
            polars with-column (
                $in.content_s
                | polars replace-all --pattern '⏎' --replace (char nl)
            )
        } else {}

    let $links_columns = $links | polars columns

    $links
    | if 'particle_to' in $links_columns {
        polars join --left $p particle_to particle
        | polars rename content_s content_s_to
    } else {}
    | if 'particle_from' in $links_columns {
        polars join --left $p particle_from particle
        | polars rename content_s content_s_from
    } else {}
    | if 'particle' in $links_columns {
        polars join --left $p particle particle
    } else {}
    | polars fill-null 'timeout|'
    | polars drop height
    | polars append $links.height
    | if 'neuron' in $links_columns {
        polars join --left (
            dict-neurons-view --df
            | polars select neuron nick
        ) neuron neuron
    } else {}
    | polars select ($in | polars columns | reverse)
}

# Output a full graph, or pass piped in graph further
#
# > cy graph-links-df | polars into-nu | first 1 | to yaml
# - index: 0
#   particle_from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   particle_to: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05T14:11:41
export def 'graph-links-df' [
    filename?: string@'nu-complete-graph-csv-files' # graph csv filename in the 'cy/graph' folder or a path to the graph
    --not_in # don't catch pipe in
    --exclude_system # exclude system particles in from column (tweet, follow, avatar)
] {
    let $input = $in
    let $cyberlinks_path = set-get-env cyberlinks-csv-table $filename
    let $input_type = $input | describe

    if (
        $not_in or
        not ($filename | is-empty) or
        ($filename | is-empty) and $input_type == 'nothing'
    ) {
        return (graph-open-csv-make-df (cy-path graph $cyberlinks_path))
    }


    let $df = $input
        | if ($input_type =~ '^table') {
            polars into-df
        } else {}

    let $df_columns = $df | polars columns
    let $existing_graph_columns = $df_columns | where $it in [particle_from particle_to neuron]

    if (
        ($existing_graph_columns | length) == 3
        or ('particle' in $df_columns)
    ) {
        $df
    } else if ($existing_graph_columns | length) == 0 {
        print $input
        error make {msg: $'there are no graph columns in ($df_columns)'}
    } else {
        graph-open-csv-make-df (cy-path graph $cyberlinks_path) # fixme - take it out
        | polars join --inner $df $existing_graph_columns $existing_graph_columns
    }
}


export def 'graph-keep-standard-columns-only' [
    standard_columns: list = [particle_from, particle_to, neuron, height, timestamp]
    --extra_columns: list = []
    --out # reject standard columns
] {
    let $input = $in
    let $in_columns = $input | polars columns
    let $out_columns = $in_columns
        | where $it in ($standard_columns | append $extra_columns)

    $input
    | if $out {
        polars drop ...($out_columns)
    } else {
        polars select $out_columns
    }
}

def 'graph-open-csv-make-df' [
    path: path
    --datetime
] {
    polars open $path --infer-schema 10000
    | if $datetime {
        polars with-column (
            $in.timestamp
            | polars as-datetime '%Y-%m-%dT%H:%M:%S' -n
            | polars rename datetime timestamp
        )
    } else {}
}

export def 'graph-particles-df' [] {
    cy-path graph particles.parquet
    | if ($in | path exists) {
        polars open $in
    } else {
        cprint `particles.parquet doesn't exist. Use *graph-update-particles-parquet*`

        first_cyberlink
    }
}

export def 'particles-filter-by-type' [
    --exclude
    --media
    --timeout
] {
    let $input = $in
    let $filter_regex = if $media {
            '"MIME'
        } else {}
        | if $timeout {
            append 'timeout\|'
        } else {}
        | str join '|'
        | '^' + $in

    $input
    | polars filter-with (
        $in.content_s =~ $filter_regex
        | if $exclude {polars not} else {}
    )
}

# Create a config JSON to set env variables, to use them as parameters in cyber cli
export def --env 'config-new' [
    # config_name?: string@'nu-complete-config-names'
] {
    print (check-requirements)
    make-default-folders-fn

    cprint -c green 'Choose the name of executable:'
    let $exec = nu-complete-executables | input list -f | print-and-pass

    let $addr_table = ^($exec) keys list --output json
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

    if ($addr_table | length) == 0 {
        let $error_text = cprint --echo $'
            There are no addresses in the keyring of *($exec)*. To use Cy, you need to add one.
            You can find out how to add the key by running the command "*($exec) keys add -h*".
            After adding the key, come back and launch this wizard again.'

        error make -u {msg: $error_text}
    }

    cprint -c green --before 1 $'Select the address from your ($exec) cli to send transactions from:'

    let $address = $addr_table
        | input list -f
        | get address
        | print-and-pass

    let $keyring = $addr_table | where address == $address | get keyring.0

    let $passport_nick = passport-get $address
        | get nickname -i

    if not ($passport_nick | is-empty) {
       cprint -c default_italic --before 1 $'Passport nick *($passport_nick)* will be used'
    }

    let $config_name = $addr_table
        | select address name
        | transpose --header-row --as-record
        | get $address
        | $'($in)($passport_nick | if $in == null {} else {'-' + $in})-($exec)'

    let $chain_id = if ($exec == 'cyber') { 'bostrom' } else { 'space-pussy' }

    let $rpc_def = if ($exec == 'cyber') {
        'https://rpc.bostrom.cybernode.ai:443'
    } else {
        'https://rpc.space-pussy.cybernode.ai:443'
    }

    cprint -c green --before 1 'Select the address of RPC api for interacting with the blockchain:'
    let $rpc_address = [$rpc_def 'other']
        | input list -f
        | if $in == 'other' {
            input 'enter the RPC address:'
        } else {}
        | print-and-pass

    cprint -c green --before 1 'Select the ipfs service to store particles:'

    let $ipfs_storage = set-cy-setting --output_value_only 'ipfs-storage'

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
] {
    if $config_name == null {
        $env.cy
    } else {
        open (cy-path config $'($config_name).toml')
    }
}

# Save the piped-in JSON into a config file inside of `cy/config` folder
export def --env 'config-save' [
    config_name: string@'nu-complete-config-names'
    --inactive # Don't activate current config
] {
    default ($env.cy)
    | upsert config-name $config_name
    | print-and-pass
    | save -f ( cy-path config $'($config_name).toml' )

    if not $inactive {
        config-activate $config_name
    }
}

# Activate the config JSON
export def --env 'config-activate' [
    config_name: string@'nu-complete-config-names'
] {
    let $config_path = $nu.home-path | path join .cy_config.toml

    open $config_path
    | upsert config-name $config_name
    | collect
    | save -f $config_path

    export1
}

def 'search-sync' [
    query
    --page (-p): int = 0
    --results_per_page (-r): int = 10
] {
    let $cid = if (is-cid $query) {
        $query
    } else {
        pin-text $query --only_hash
    }

    print $'searching ($env.cy.exec) for ($cid)'

    caching-function query rank search $cid $page 10
    | get result
    | upsert particle {|i|
        let $particle = ^ipfs cat $i.particle -l 400

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
}

def 'search-with-backlinks' [
    query: string
    --page (-p): int = 0
    --results_per_page (-r): int: int = 10
] {
    let $cid = pin-text $query --only_hash

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
    let $cid = pin-text $query --only_hash

    print $'searching ($env.cy.exec) for ($cid)'

    let $out = ^($env.cy.exec) query rank search $cid $page $results_per_page ...[
            --output json
            --node $env.cy.rpc-address
        ] | complete

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

    clear
    print $'Searching ($env.cy.exec) for ($cid)'

    serp1 $results

    watch (cy-path cache queue_cids_to_download) {||
        clear
        print $'Searching ($env.cy.exec) for ($cid)'
        serp1 $results
    }
}

export def search-walk [
    query: string
    --results_per_page: int = 100
    --duration: duration = 2min
] {
    let $cid = pin-text $query --only_hash

    def serp [page: int] {
        caching-function query rank search $cid $page $results_per_page --cache_validity_duration $duration
        | upsert page $page
    }

    generate {|i|
        {out: $i.result}
        | if ($i.pagination.total / $results_per_page - 1 | math ceil) > $i.page {
            upsert next (serp ($i.page + 1))
        } else {}
    } {
        result: [],
        page : -1,
        pagination: {total: $results_per_page}
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
    match $search_type {
        'search-with-backlinks' => {
            search-with-backlinks $query --page $page --results_per_page $results_per_page
        }
        'search-auto- =>refresh' => {
            search-auto-refresh $query --page $page --results_per_page $results_per_page
        }
        'search-sync' => {
            search-sync $query --page $page --results_per_page $results_per_page
        }
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
    let $headers = ^curl -s -I -m 120 $'($gate_url)($cid)'
        | lines
        | skip 1
        | append 'dummy: dummy' # otherwise it returns list in the end
        | parse '{header}: {value}'
        | transpose -d -r -i

    let $type = $headers | get -i 'Content-Type'
    let $size = $headers | get -i 'Content-Length'

    if (
        $type == null
        or $size == null
        or ($type == 'text/html') and ($size == '157') # missing pages
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
    let $file_path = $file | if $in == '' {cy-path cache MIME_types.csv} else {}

    $'($cid),($source),"($type)",($size),($status),(history session)(char nl)'
    | save -a $file_path
}

# Read a CID from the cache, and if the CID is absent - add it into the queue
export def 'cid-read-or-download' [
    cid: string
    --full # output full text of a particle
] {
    $env.cy.ipfs-files-folder | path join $'($cid).md'
    | if ($in | path exists) {
        open
    } else {
        queue-task-add $'cid-download ($cid)'
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
    let $folder = $folder | default $'($env.cy.ipfs-files-folder)'
    let $content = do -i {open ($env.cy.ipfs-files-folder | path join $'($cid).md')}
    let $source = $source | default $env.cy.ipfs-download-from

    let $task = $'cid-download ($cid) --source ($source) --info_only=($info_only) --folder "($folder)"'

    if $content == null or $content == 'timeout' or $force {
        queue-task-add $task
        print 'downloading'
    }
}

# Download cid immediately and mark it in the queue
export def 'cid-download' [
    cid: string
    --source: string # kubo or gateway
    --info_only # Generates a card with the specified filetype and size instead of downloading the file
    --folder: path # Folder path to save the file
] {
    let $folder = $folder | default $env.cy.ipfs-files-folder
    let $source = $source | default $env.cy.ipfs-download-from
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
    --folder: path # Folder path to save the file
    --info_only # # Generates a card with the specified filetype and size instead of downloading the file
] {
    log debug $'cid to download ($cid)'
    let $file_path = $folder | default $env.cy.ipfs-files-folder | path join $'($cid).md'
    let $type = ^ipfs cat --timeout $timeout -l 400 $cid
        | complete
        | if $in == null or $in.exit_code == 1 {
            'empty'
        } else {
            get stdout
            | file - --mime
            | $in + ''
            | str replace (char nl) ''
            | str replace '/dev/stdin: ' ''
        }

    if ($type =~ '^empty') {
        return 'not found'
    } else if (
        $type =~ '(text/plain|ASCII text|Unicode text, UTF-8|very short file)' and not $info_only
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
            ^ipfs dag stat $cid --enc json --timeout $timeout | from json
        }
        | default {'Size': null}
        | merge {'MIME type': ($type | split row ';' | get -i 0)}
        | sort -r
        | to toml
        | save -f $file_path

        return 'non_text'
    }
}

# Download a cid from gateway immediately
def 'cid-download-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --folder: string
    --info_only # Don't download the file by write a card with filetype and size
] {
    let $file_path = $folder | default $env.cy.ipfs-files-folder | path join $'($cid).md'
    let $meta = cid-get-type-gateway $cid

    if (
        ($meta.type? | default '') == 'text/plain; charset=utf-8' and not $info_only
    ) {
        # to catch response body closed before all bytes were read
        # {http get -e https://gateway.ipfs.cybernode.ai/ipfs/QmdnSiS36vggN6gHbeeoJUBSUEa7B1xTJTcVR8F92vjTHK
        # | save -f temp/test.md}
        try {
            http get -e $'($gate_url)($cid)' -m 120
            | if ($in | str contains '<head><title>502 Bad Gateway</title></head>') {
                return 'not found'
            } else {}
            | save -f $file_path
        } catch {
            return 'not found'
        }
        return 'text'
    } else if ($meta.type? != null) {
        {'MIME type': $meta.type, 'Size': $meta.size?}
        | sort -r
        | to toml
        | save -f $file_path

        return 'non_text'
    } else {
        return 'not found'
    }
}

# Add a CID to the download queue
export def 'queue-cid-add' [
    cid: string
    symbol: string = ''
] {
    let $path = cy-path cache queue_cids_to_download $cid

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

# remove from queue CIDs with many attempts
export def 'cache-clean-cids-queue' [
    attempts: int = 15 # limit a number of previous download attempts for cids in queue
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
    make-default-folders-fn
}

# Set the custom name for links csv table
export def --env 'set-links-table-name' [
    name?: string@'nu-complete-links-csv-files' # a name for a temporary cyberlinks table file
]: nothing -> nothing {
    let $name_1 = $name
        | if $in == null {
            'temp_' + (now-fn)
        } else {}

    $env.cy.links_table_name = $name_1
    if $name == null {$name_1}
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

    let $value_1 = if $value == null {
            set-select-from-variants $key_1
        } else { $value }
        | if ($in in ['true', 'false']) { # input list errors on booleans on 0.87.1
            into bool
        } else {}

    if $output_value_only {
        $value_1
    } else {
        $env.cy = ($env.cy | upsert $key_1 $value_1)
    }
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

# Update Cy and Nushell to the latest versions
export def 'update-cy' [
    --branch: string@'nu-complete-git-branches' = 'dev' # the branch to get updates from
] {
    # check if nushell is installed using brew
    if (brew list nushell | complete | get exit_code | $in == 0) {
        brew upgrade nushell
    } else {
        if (which cargo | length | $in > 0) {
            cargo install --features=dataframe nu
        }
    }

    cd (cy-path)
    git stash
    git checkout $branch
    git pull
    git stash pop
    cd -
}

# An ordered list of cy commands
export def 'help-cy' [] {
    cy-path cy.nu
    | open --raw
    | parse -r "(\n# (?<desc>.*?)(?:\n#[^\n]*)*\nexport def(:? --(:?env|wrapped))* '(?<command>.*)')"
    | select command desc
    | upsert command {|row index| ('cy ' + $row.command)}
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

def 'system_cids' [] {
    [
        'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx',
        'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx',
        'Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs'
    ]
}

def 'first_cyberlink' [] {
    [
        [index, particle, neuron, height, timestamp, content_s];
        [0, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt",
        490, "2021-11-05 14:11:41", "cyber|QK3oufV"]
    ]
    | polars into-df
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
