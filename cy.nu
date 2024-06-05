# Cy - a tool for interacting with Cybergraphs
# https://github.com/cyber-prophet/cy
#
# Use:
# > overlay use -pr ~/cy/cy.nu

use std assert [equal greater]
use nu-utils [ bar, cprint, "str repeat", to-safe-filename, to-number-format, number-col-format,
    nearest-given-weekday, print-and-pass, clip, confirm, normalize, path-modify]
use cy-internals.nu [cy-path match-type default-settings open-cy-config-toml export1 param-or-input backup-and-echo make-default-folders-fn set-or-get-env-or-def set-select-from-variants path-exists-safe]

use std log

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
    let $text = param-or-input $text_param
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

# Add a tweet and send it immediately (unless of disable_send flag)
#
# > cy links-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
# from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to_text: cyber-prophet is cool
# from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
# to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK
export def 'tweet' [
    text_to: string # text to tweet
    --disable_send (-D) # don't send tweet immediately, but put it into the temp table
]: [nothing -> record, string -> record] {
    let $text_to = param-or-input $text_to
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

    if (not $quiet) { links-view -q }
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
    let $links_per_trans = set-or-get-env-or-def --dont_set_env links-per-transaction

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
    | reject index
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
    let $links = links-view -q | first (
        set-or-get-env-or-def links-per-transaction
    )

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
    | $in // (set-or-get-env-or-def links-per-transaction $links_per_trans)
    | seq 0 $in
    | each {links-send-tx}
}

def 'inlinks-or-links' []: [nothing -> table, table -> table] {
    if $in == null {links-view -q} else {}
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

    ( caching-function query wasm contract-state smart $pcontract $json $params
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
    let $graphql_api = set-or-get-env-or-def 'indexer-graphql-endpoint'

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
    let $url = set-or-get-env-or-def 'indexer-clickhouse-endpoint'
    let $auth = set-or-get-env-or-def 'indexer-clickhouse-auth'
    let $chunk_size = set-or-get-env-or-def 'indexer-clickhouse-chunksize'

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
    let $cyberlinks_path = set-or-get-env-or-def cyberlinks-csv-table $filename
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
    | polars join $df2_st [particle_from particle_to neuron] [particle_from particle_to neuron] --outer
    | polars with-column (
        polars when ((polars col source) | polars is-null) (polars col source_x)
        | polars when ((polars col source_x) | polars is-null) (polars col source)
        | polars otherwise (polars concat-str '-' [(polars col source) (polars col source_x)])
        | polars as source
    )
    | polars with-column (
        polars when ((polars col height) | polars is-null) (polars col height_x)
        | polars otherwise (polars col height) | polars as height
    )
    | polars with-column (
        polars when ((polars col timestamp) | polars is-null) (polars col timestamp_x)
        | polars otherwise (polars col timestamp) | polars as timestamp
    )
    | polars drop height_x timestamp_x source_x
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
    | print ($in | get 0 -i)
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
        | polars join $p particle_to particle
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
            | reject index
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
    | reject index
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
    | reject index
    | each {|i| echo_particle_txt $i}
}

# Export piped-in graph to a CSV file in cosmograph format
export def 'graph-to-cosmograph' [] {
    graph-add-metadata
    | polars rename timestamp time
    | polars select ($in | polars columns | prepend [content_s_from content_s_to] | uniq)
    | polars into-nu
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
    let $graph = graph-add-metadata --escape_quotes --new_lines
        | polars select 'content_s_from' 'content_s_to'
        | $in.content_s_from + ' -> ' + $in.content_s_to + ';'
        | polars into-nu
        | rename index links
        | get links
        | str join (char nl)
        | "digraph G {\n" + $options + "\n" + $in + "\n}"

    if $preset == '' { $graph } else {
        let $filename = cy-path export $'graphviz_($preset)_(now-fn).svg'

        let $params = ['-Tsvg' $'-o($filename)']

        $graph | ^($preset) ...$params
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
        | graph-keep-standard-columns-only --extra_columns ['particle', 'link_local_index', 'init-role', 'step']

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
            polars append (
                $in.content_s
                | polars replace-all --pattern '⏎' --replace (char nl)
            )
        } else {}

    let $links_columns = $links | polars columns

    let $c_out = $links
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

    let $columns_order_target = $c_out | polars columns | reverse

    $c_out
    | polars select $columns_order_target
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
    let $cyberlinks_path = set-or-get-env-or-def cyberlinks-csv-table $filename
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
        graph-open-csv-make-df (cy-path graph $cyberlinks_path)
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

    if (not ($passport_nick | is-empty)) {
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
    let $in_config = upsert config-name $config_name
    let $filename = cy-path config $'($config_name).toml'

    let $filename2 = if not ($filename | path exists) {
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

    $in_config
    | upsert config-name ($filename2 | path parse | get stem)
    | upsert config-path ($filename2)
    | if not $inactive {
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
    let $config = default (config-view $config_name)
    let $config_path = $nu.home-path | path join .cy_config.toml
    let $config_toml = open $config_path
        | merge $config

# todo refactor

    $env.cy = $config_toml

    cprint -c green_underline -b 1 'Config is loaded'

    let $new_config = open $config_path
    | upsert 'config-name' $config_toml.config-name

    # can't save to the same location as opened in this piped
    $new_config
    | save $config_path -f

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

# Check the queue for the new CIDs, and if there are any, safely download the text ones
export def 'queue-cids-download' [
    attempts: int = 0 # limit a number of previous download attempts for cids in queue
    --info # don't download data, just check queue
    --quiet # Disable informational messagesrmation
    --threads: int = 15 # a number of threads to use for downloading
    --cids_in_run: int = 0 # a number of files to download in one command run. 0 - means all (default)
] {
    let $files = ls -s (cy-path cache queue_cids_to_download)

    if ($files | length) == 0 {
        return 'there are no files in queue'
    }

    if not $quiet {
        cprint $'Overall count of files in queue is *($files | length)*'
        cprint $'*($env.cy.ipfs-download-from)* will be used for downloading'
    }

    let $filtered_files = $files
        | where size <= (1 + $attempts | into filesize)
        | sort-by size

    let $filtered_count = $filtered_files | length

    if $filtered_files == [] {
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

# Get a current height for the active network in config
#
# > cy query-current-height | to yaml
# height: '9010895'
# time: 2023-07-11T11:37:40.708298734Z
# chain_id: bostrom
export def 'query-current-height' [
    exec?: string@'nu-complete-executables' # executable to use for the query
] {
    let $exec = $exec | default $env.cy.exec

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
    neuron?: string # an address of a neuron
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
    neuron?: string # an address of a neuron
    --height: int = 0 # a height to request a state on
    --record # output the results as a record
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
        transpose --ignore-titles --as-record --header-row
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
    --height: int = 0 # a height to request a state on
] {
    caching-function query bank total [--height $height]
    | get supply
    | into int amount
    | transpose --ignore-titles --as-record --header-row
}

export def 'tokens-pools-table-get' [
    --height: int = 0 # a height to request a state on
    --short # get only basic information
] {
    let $liquidity_pools = caching-function query liquidity pools [--height $height]

    if $short { return $liquidity_pools }

    let $supply = tokens-supply-get --height $height

    $liquidity_pools
    | get pools
    | each {|b| $b
        | upsert balances {|i|
            tokens-balance-get --height $height --record $i.reserve_account_address
        }
    }
    | where balances != (token-dummy-balance | transpose --ignore-titles --as-record --header-row)
    | upsert balances {
        |i| $i.balances | select ...$i.reserve_coin_denoms # keep only pool's tokens
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
    --height: int = 0 # a height to request a state on
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
    --height: int = 0 # a height to request a state on
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
    --height: int = 0 # a height to request a state on
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
    --h_liquid # return amount of liquid H
    --quiet # don't print amount of H liquid
    --height: int = 0 # a height to request a state on
    --sum
] {
    let $address = $neuron | default $env.cy.address
    let $account_vesting = query-account $address --height $height

    if ($account_vesting | get -i vesting_periods) == null {
        return []
    }

    let $release_slots = $account_vesting.vesting_periods.length
        | reduce -f [($account_vesting.start_time | into int)] {
            |i acc| $acc | append (($i | into int) + ($acc | last))
        }
        | skip
        | each {|i| 10 ** 9 * $i | into datetime}
        | wrap release_time

    let $investmint_status = $account_vesting.vesting_periods
        | reject length
        | merge $release_slots
        | where release_time > (date now)
        | flatten --all
        | into int amount
        | upsert state frozen

    let $h_all = tokens-balance-get $address --height $height
        | where denom == hydrogen
        | if ($in | length | $in > 0) {
            get amount.0 | into int
        } else { 0 }

    let $hydrogen_liquid = $investmint_status
        | where denom == 'hydrogen'
        | get amount
        | append 0
        | math sum
        | $h_all - $in

    if not $quiet {
        print $'liquid hydrogen available for investminting: (
            $hydrogen_liquid | to-number-format --significant_integers 0)'
    }

    if $h_liquid {
        $hydrogen_liquid
    } else {
        $investmint_status
        | if $sum {
            tokens-sum --state investminting
        } else {}
        | append null # if no investmint slots are busy, the command should return a list
    }
}

export def 'tokens-routed-from' [
    neuron?: string
    --height: int = 0 # a height to request a state on
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
    --height: int = 0 # a height to request a state on
] {
    let $address = $neuron | default $env.cy.address

    caching-function query grid routed-to $address [--height $height]
    | get -i value
    | if $in == null {return} else { }
    | into int amount
    | upsert state routed-to
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
        |i| $i.path #denom compound
        | str replace --regex --all '[^-0-9]' ''
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
        [base_denom, ticker, coinDecimals];
        [usomm SOMM 6]
        [ucre CRE 6]
        [boot mBOOT 6]
        [pussy gPUSSY 9]
        [hydrogen mH 6]
        [tocyb mTOCYB 6]
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
    let $json = {get_assets_by_chain: {chain_name: $chain_name}} | to json -r
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
    --height: int = 0 # a height to request a state on
]: nothing -> table {
    let $pools = tokens-pools-table-get --height $height
        | select reserve_coin_amount reserve_account_address reserve_coin_denom
        | into float reserve_coin_amount

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
    let $denom = tokens-info-from-registry
        | select token denom
        | transpose --ignore-titles --as-record --header-row
        | get $token

    let $target_denom_price_in_h = tokens-price-in-h-naive | transpose --ignore-titles --as-record --header-row | get $denom

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
    let $input = join -l (tokens-price-in-h-naive --all_data) denom denom

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

    if ($columns | where $it =~ 'amount_in_h' | length) > 0 {
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
    --test # Use keyring-backend test (with no password)
] {
    let $balances = ^($env.cy.exec) keys list --output json --keyring-backend test
        | from json
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

    let $default_columns = $balances | columns | prepend 'name' | uniq
        | reverse | prepend ['address'] | uniq
        | reverse | reduce -f {} {|i acc| $acc | merge {$i : 0}}

    $balances
    | each {|i| $default_columns | merge $i}
    | sort-by name
    | if (($in | length) > 1) { } else {
        into record
    }
}

export def 'tokens-undelegations' [
    $neuron?: string # an address of a neuron
    --height: int = 0 # a height to request a state on
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
    $neuron?: string # an address of a neuron
    --height: int = 0 # a height to request a state on
    --routes: string = 'from'
    --dont_convert_pools
] {
    let $address = $neuron | default $env.cy.address
    let $invstiminted_frozen = tokens-investmint-status-table $address --sum --quiet

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
}

export def 'tokens-sum' [
    --state: string = '-'
] {
    if $in in [null []] {return [{denom: boot, amount: 0, state: 'dummy'}]} else {}
    | sort-by amount -r
    | group-by denom
    | values
    | each {|i|
        {}
        | upsert denom $i.denom.0
        | upsert amount ($i.amount | into float | math sum | into int)
        | upsert state (
            if $state == '-' {
                $i.state? | uniq | str join '+'
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
    neuron?: string # an address of a neuron
] {
    let $address = $neuron | default $env.cy.address

    let $tx = ^($env.cy.exec) tx distribution withdraw-all-rewards ...[
            ...(default-node-params)
            --from $address
            --fees '0boot'
            --gas 2000000
            --yes
        ]
        | str replace "Default sign-mode 'direct' not supported by Ledger, using sign-mode 'amino-json'.\n" ''
        | from json

    if $tx.code? != 0 { cprint '*tx.code != 0*' }
    print ($tx | select code txhash)

    let $tx_hash = $tx | get txhash

    print 'Waiting for 20 seconds to query for transaction info from the node'
    sleep 20sec

    rewards-withdraw-tx-analyse $tx_hash
}

export def 'rewards-withdraw-tx-analyse' [
    tx_hash: string # a hash of a transaction to check
] {
    let $tx = query-tx $tx_hash

    let $tx_height = $tx | get height | into int | $in - 1
    let $tx_neuron = $tx | get tx.body.messages.0.delegator_address

    let $rewards = $tx
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

    let $result = tokens-delegations-table-get $tx_neuron --height $tx_height
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

    $result
    | upsert percent_rel {|i| $i.percent / ($result.percent | math max)}
    | move percent_rel --after commission
}

export def 'tokens-delegate-wizard' [
    $neuron?: string # an address of a neuron
] {
    let $address = $neuron | default $env.cy.address

    let $boots_liquid = tokens-balance-all $address
        | where state == liquid
        | where denom == boot
        | get amount.0
        | $in - 2_000_000 # a fraction for fees

    ($boots_liquid | to-number-format --denom boot --significant_integers 0 | ansi strip)
    | cprint $'You have *($in)* liquid. How much of them would you like to delegate?'

    let $boots_to_delegate: string = tokens-fraction-menu $boots_liquid --denom 'boot'

    cprint $'Choose the validator to delegate *($boots_to_delegate)*.'
    let $operator = validator-chooser --only_my_validators
        | append {moniker: 'load more'}
        | input list --fuzzy
        | if ($in | values | get 0 | $in == 'load more') {
            validator-chooser | input list --fuzzy
        } else {}
        | get operator_address

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

export def 'tokens-investmint-wizard' [
    $neuron?: string # an address of a neuron
    --weeks-from-now: int
] {
    let $address = $neuron | default $env.cy.address

    $env.cy.caching-function-force-update = true

    let $times = tokens-investmint-status-table $address
        | print-and-pass
        | window 2 --stride 2
        | each {|i| $i
            | reduce -f '' {|a acc| $acc + $'($a.amount)($a.denom) '}
            | wrap tokens
            | upsert release_time $i.release_time.0
        }

    $env.cy.caching-function-force-update = false

    let $h_free = tokens-investmint-status-table $address --h_liquid --quiet
        | if $in in [[] 0] {
            error make {msg: (cprint --echo $'no liquid hydrogen on *($address)* address')}
        } else {}

    let $h_to_investmint = tokens-fraction-menu $h_free --denom hydrogen --bins_list [0.5 1 0.2]

    let $resource_token = ['Volt' 'Ampere']
        | input list
        | str downcase
        | 'milli' + $in

    cprint --before 1 --after 2 'Choose the investminting period.
    In the list below fields that have `tokens` value are your currently used slots.
    The first value is always a tuesday after the next 2 weeks.'

    let $release_time = $times
        | select release_time tokens
        | if $weeks_from_now != null {
            nearest-given-weekday --weeks $weeks_from_now
        } else {
            prepend (1..6 | each { {release_time: (nearest-given-weekday --weeks $in)} })
            | sort-by release_time
            | input list
            | get release_time
        }
        | $in - (date now) | into int
        | $in / 10 ** 9 | into int

    let $trans_unsigned = ^cyber tx resources investmint ...[
        $h_to_investmint $resource_token $release_time
        --from $address --fees 2000boot --gas 2000000 ...(default-node-params) --generate-only
    ]

    print ($trans_unsigned | from json | to yaml)

    if (confirm '*Confirm transaction?*') {
        let $unsigned = cy-path temp 'tx_investmint_unsigned.json'
        let $signed: string = cy-path temp 'tx_investmint_signed.json'
        $trans_unsigned | save --raw --force $unsigned
        ^($env.cy.exec) tx sign $unsigned --from $address --output-document $signed --yes ...(default-node-params)

        ^($env.cy.exec) tx broadcast $signed ...(default-node-params) | from json | select txhash
    }
}

export def 'tokens-fraction-input' [
    --dust_to_leave: int = 50_000 # the amount of token to leave for paing fee
    --denom: string = '' # a denom of a token
    --yes # proceed without confirmation
] {
    let $tokens = $in - $dust_to_leave

    while true {
        cprint $'you can enter integer value (char lp)like *4_000_000* or *4000000*(char rp) or percent
            from your liquid BOOTs (char lp)like *30%*(char rp)'

        let $value = input
            | if ($in | str contains '%') {
                str replace '%' '' | into float | $in / 100 | $tokens * $in
            } else { str replace --regex --all '[^0-9]' '' }
            | into int

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
    id?: string@'nu-complete-props' # id of a proposal to check
    --dont_format # don't format proposals
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
            table -e | print
        }
    }
}

def 'governance-prop-summary' [] {
    let $tally_res = | get -i final_tally_result
        | if $in == null {return} else {}
        | into int yes abstain no no_with_veto

    let $total = $tally_res | values | math sum

    $tally_res
    | {'✅': $in.yes, '❌': $in.no, '🛑': $in.no_with_veto, '🦭': $in.abstain}
    | items {|k v| $'($k)(
        $v / $total * 100
        | to-number-format --denom "%" --decimals 1 --significant_integers 0
    )'}
    | str join '/'
    | ' | ' + $in
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

def 'current-links-csv-path' [
    name?: path
]: nothing -> path {
    $name
    | default ($env.cy?.links_table_name?)
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
#
# > validator-generate-persistent-peers-string https://rpc.bostrom.cybernode.ai:443
# Nodes list for https://rpc.bostrom.cybernode.ai:443
#
# 70 peers found
# persistent_peers = "7ad32f1677ffb11254e7e9b65a12da27a4f877d6@195.201.105.229:36656,d0518..."
export def 'validator-generate-persistent-peers-string' [
    node_address?: string
]: nothing -> string {
    let $node_address = $node_address | default $env.cy.rpc-address

    if $node_address == $env.cy.rpc-address {
        cprint -a 2 $"Nodes list for *($env.cy.rpc-address)*"
    }

    let $peers = http get -e $'($node_address)/net_info' | get result.peers

    cprint -a 2 $"*($peers | length)* peers found"

    $peers
    | each {
        get node_info.id remote_ip node_info.listen_addr
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
    let $validator = if (is-validator $validator_or_moniker) {
            $validator_or_moniker
        } else {
            nu-complete-validators-monikers
            | select value description
            | transpose --ignore-titles --as-record --header-row
            | get $validator_or_moniker
        }

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
    | upsert trans_status {|i| trans_status $i}
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
    --height: int = 0 # a height to request a state on
    --seq # return sequence
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
    caching-function query bandwidth price
    | get price.dec
    | into float
    | $in * 1000
    | into int # price in millivolt
}

def 'query-links-bandwidth-params' []: nothing -> record {
    caching-function query bandwidth params
    | get params
    | transpose key value
    | into float value
    | transpose --ignore-titles --as-record --header-row
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
    neuron? # an address of a neuron
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
    neuron? # an address of a neuron
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

export def 'query-links-bandwidth-neuron' [
    neuron? # an address of a neuron
]: nothing -> table {
    caching-function query bandwidth neuron ($neuron | default $env.cy.address) --cache_stale_refresh 5min
    | get neuron_bandwidth
    | select max_value remained_value
    | transpose param links
    | into int links
    | upsert links {|i| $i.links / (query-links-bandwidth-price) | math floor}
}

export def 'query-staking-validators' [] {
    let $vals_1_page = caching-function query staking validators --count-total

    let $offset_to_go = $vals_1_page
        | get pagination.total
        | into int
        | $in // 100
        | 1..$in
        | each {|i| $i * 100}

    let $all_validators = $offset_to_go
        | each {|i| caching-function query staking validators --count-total --offset $i | get validators}
        | flatten
        | prepend $vals_1_page.validators

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

# A wrapper, to cache CLI requests
export def --wrapped 'caching-function' [
    ...rest
    --exec: string = '' # The name of executable
    --cache_validity_duration: duration = 60min # Sets the cache's valid duration.
                                                # No updates initiated during this period.
    --cache_stale_refresh: duration # Sets stale cache's usable duration.
                                    # Triggers background update and returns cache results.
                                    # If exceeded, requests immediate data update.
    --force_update
    --disable_update (-U)
    --quiet # Don't output execution's result
    --no_default_params # Don't use default params (like output, chain-id)
    --error # raise error instead of null in case of cli's error
    --retries: int
]: nothing -> record {
    if ($retries != null) {$env.cy.caching-function-max-retries = $retries}

    let $rest = $rest | each {into string}

    let $cache_stale_refresh = set-or-get-env-or-def caching-function-cache_stale_refresh $cache_stale_refresh

    if $rest == [] { error make {msg: 'The "caching-function" function needs arguments'} }

    let $executable = if $exec != '' {$exec} else {$env.cy.exec}
    let $sub_commands_and_args = $rest
        | flatten
        | flatten # to receive params as a list from passport-get
        | if $no_default_params {} else {
            append (default-node-params)
        }

    let $json_path = $executable
        | append ($sub_commands_and_args)
        | str join '_'
        | str replace -r '--node.*' ''
        | str trim -c '_'
        | to-safe-filename --suffix '.json'
        | cy-path cache jsonl --file $in

    log debug $'json path: ($json_path)'

    let $last_data = if ($json_path | path exists) {
            # use debug here print $json_path
            open $json_path
        } else {
            {'update_time': 0}
        }
        | into datetime update_time

    let $freshness = (date now) - $last_data.update_time

    mut $update = (
        $force_update or
        ($env.cy.caching-function-force-update? | default false) or
        ($freshness > $cache_stale_refresh and not $disable_update)
    )

    if 'error' in ($last_data | columns) {
        log debug $'last update ($freshness) was unsuccessful, requesting for a new one'
        $update = true
    }

    if $update {
        (request-save-output-exec-response $executable $sub_commands_and_args $json_path $error $quiet
            --last_data $last_data)
    } else {
        if $freshness > $cache_validity_duration {
            queue-task-add -o 2 (
                $'caching-function --exec ($executable) --force_update [' +
                (
                    $sub_commands_and_args
                    | each {
                        str replace -a '"' '\"' | $'"($in)"'
                    }
                    | str join ' '
                ) +
                '] | to yaml | lines | first 5 | str join "\n"'
            )
        }

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
        ^($executable) ...$sub_commands_and_args
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
        $response = (do $request)

        if $response.error? == null {
            $retries = 0
        } else {
            sleep 2sec
            $retries = $retries - 1
        }
    }

    $response
    | to json -r
    | save --raw --force $json_path

    if 'error' in ($response | columns) {
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
        | save --append --raw ($json_path | str replace '.json' '_arch.jsonl')
    }

    if not $quiet {$response}
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

export def 'crypto-prices' [] {
    http get 'https://api.coincap.io/v2/assets' | get data
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

def is-cid [particle: string] {
    $particle =~ '^Qm\w{44}$'
}

def is-neuron [address: string] {
    $address =~ '^(bostrom|pussy)(\w{39}|\w{59})$'
}

def is-validator [address: string] {
    $address =~ '^(bostrom|pussy)\w{46}$'
}

def is-connected [] {
    (do -i {http get https://duckduckgo.com/} | describe) == 'raw input'
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

def 'default-node-params' [] {
    [
        '--node' $env.cy.rpc-address
        '--chain-id' $env.cy.chain-id # todo chainid to choose
        '--output' 'json'
    ]
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

export def 'queue-task-add' [
    command: string
    --priority (-o): int = 1
] {
    let $filename = $command
        | to-safe-filename --prefix $'($priority)-' --suffix '.nu.txt'
        | cy-path cache queue_tasks_to_run $in

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
            if ($in | length) == 0 { } else {
                par-each -t $threads {
                    |i| queue-execute-task $i
                }
            }
        }
        sleep 1sec
        print -n $"(char cr)⌛(date now | format date '%H:%M:%S') - to exit press `ctrl+c`"
    }
}

export def 'queue-execute-task' [
    task_path: path
] {
    let $command = open $task_path

    let $results = ^nu --config $nu.config-path --env-config $nu.env-path $task_path
        | complete

    $results
    | if $in.exit_code == 0 {
        print -n $'(char nl)🔵 ($command)'
        print -n $'(char nl)($results.stdout)'
    } else {
        print -n $'(char nl)🛑 ($command)'
        $command + ';' | save -a (cy-path cache queue_tasks_failed ($task_path | path basename))
    }
    ^rm -f $task_path
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
    dict-neurons-view
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
    nu-complete key-names
    | append (nu-complete dict-nicks)
}

def 'nu-complete-bool' [] {
    [true, false]
}

def 'nu-complete-props' [] {
    let term_size = term size | get columns

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

def 'nu-complete-graph-csv-files' [] {
    ls -s (cy-path graph '*.csv' | into glob)
    | sort-by modified -r
    | select name size
    | upsert size {|i| $i.size | into string}
    | rename value description
}

def 'nu-complete-links-csv-files' [] {
    ls -s (cy-path mylinks '*.csv' | into glob)
    | where name !~ '_cyberlinks_archive.csv'
    | update name {|i| $i.name | str replace -r '\.csv$' ''}
    | sort-by modified -r
    | select name size
    | upsert size {|i| $i.size | into string}
    | rename value description
}

def 'nu-complete-graph-provider' [] {
    ['hasura' 'clickhouse']
}

def 'nu-complete-graphviz-presets' [] {
    [ 'sfdp', 'dot' ]
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
    let $table = default $tbl

    $table
    | columns
    | reduce -f $table {|column acc|
        $acc | default $value_to_replace $column
    }
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
