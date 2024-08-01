# Cy submodule for creating and publishing cyberlinks

use nu-utils [cprint, print-and-pass, confirm, path-modify]
use cy-complete.nu *
use cy-internals.nu *
use dict.nu [dict-neurons-add]
use graph.nu [graph-links-df graph-receive-new-links]
use query.nu [query-links-bandwidth-neuron]
use tx.nu [tx-json-create-from-cyberlinks tx-sign tx-authz tx-broadcast]

# Pin a text particle
#
# pin text 'cyber', get it's cid
# > cy pin-text 'cyber'
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#
# pin text 'cyber.txt', get it's cid
# > cy pin-text 'cyber.txt'
# QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
#
# save text 'cyber' to the file. Use flag `--follow_file_path` to pin the content of file, but not it's name
# > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt' --follow_file_path
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#
# use `cy pin-text` with some cid, to see that it will return the cid by default unchanged
# > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#
# use `--ignore_cid` flag to calculate hash from the initial cid as if it is a regular text
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
    | links-pin-columns-using-kubo
}

# Pin files from the current folder to the local node and append their cyberlinks to the temp table
#
# Create temporary directory, cd there, save `cyber.txt` `bostrom.txt` files there with according content.
# > cd (mktemp -d); 'cyber' | save cyber.txt; 'bostrom' | save bostrom.txt;
#
# Create cyberlinks from filenames to their content for previously saved files.
# > cy link-files --link_filenames --yes | to yaml
# - from_text: bostrom.txt
#   to_text: pinned_file:bostrom.txt
#   from: QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k
#   to: QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb
# - from_text: cyber.txt
#   to_text: pinned_file:cyber.txt
#   from: QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
#   to: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
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

# Create cyberlinks to hierarchies (if any) `parent_folder - child_folder`, `folder - filename`, `filename - content`
export def 'link-folder' [
    folder_path?: path # path to a folder to link files at
    --include_extension # Include a file extension
    --disable_append (-D) # Don't append links to the links table
    --no_content # Use only directory and filenames, don't create cyberlinks to file contents
    --no_folders # Don't link folders to their child members (is not available if `--no_content` is used)
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
    | links-pin-columns-using-kubo --dont_replace --quiet
    | update to_text {|i| $to_text_subst | get -i $i.to_text | default $i.to_text}
    | if $disable_append {} else {links-append}
}

# Create a cyberlink according to `following a neuron` semantic convention
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
def 'link-chuck' []: [nothing -> record] {
    let $quote = http get --allow-errors https://api.chucknorris.io/jokes/random
        | get value
        | str trim
        | { text: $in
            source: 'https://chucknorris.io' }
        | to yaml

    link-texts 'chuck norris' $quote
}

# Add a random quote cyberlink to the temp table
def 'link-quote' []: [nothing -> record] {
    let $quote = ( http get --allow-errors -r
        https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=text )
        | str replace -ar '(\.|\,)(\S)' '$1 $2'
        | str replace -ar '\s+' ' '
        | parse -r '^(?<text>.*?)\((?<author>.*)?\)'
        | if ($in.0? | is-empty) {
            print $"empty answer:\n($in)";
            return
        } else {get 0}
        | str trim text? author?
        | if $in.author? in [null, ''] {select quote} else {}
        | insert source 'https://forismatic.com'
        | to yaml

    # link-texts 'quote' $quote
    link-texts 'quote' $quote
}

# Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)
#
# > cy link-random | to yaml
# - from_text: quote
#   to_text: |
#     text: Those who are blessed with the most talent don't necessarily outperform everyone else. It's the people with follow-through who excel.
#     author: Mary Kay Ash
#     source: https://forismatic.com
#   from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
#   to: QmXfF8iWJUA37T7fDWbSLM6ASHBtXMTfnJx9jhg6g5A9eE
#
# > cy link-random --source chucknorris.io | to yaml
# - from_text: chuck norris
#   to_text: |
#     text: Chuck Norris is like God, sex and kung-fu put in a blender to create undiluted manliness.
#     source: https://chucknorris.io
#   from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
#   to: Qmd3y4evbAZYwKPojDsvZiwSnWdnrPugY7CF95E4Jxp4Me
export def 'link-random' [
    n: int = 1 # Number of links to append
    --source: string@'nu-complete-random-sources' = 'forismatic.com' # choose the source to take random links from
]: [nothing -> record, nothing -> table] {
    1..$n
    | par-each -t 3 {
        match $source {
            'forismatic.com' => { link-quote }
            'chucknorris.io' => { link-chuck }
            _ => {error make {msg: $'unknown source ($source)'}}
        }
    }
    | uniq-by to_text
}

# View the temp cyberlinks table
#
# > cy links-view | to yaml
# There are 2 cyberlinks in the temp
# table:
# - from_text: quote
#   to_text: |
#     text: Those who are blessed with the most talent don't necessarily outperform everyone else. It's the people with follow-through who excel.
#     author: Mary Kay Ash
#     source: https://forismatic.com
#   from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
#   to: QmXfF8iWJUA37T7fDWbSLM6ASHBtXMTfnJx9jhg6g5A9eE
#   timestamp: 20240801-072212
# - from_text: chuck norris
#   to_text: |
#     text: Chuck Norris is like God, sex and kung-fu put in a blender to create undiluted manliness.
#     source: https://chucknorris.io
#   from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
#   to: Qmd3y4evbAZYwKPojDsvZiwSnWdnrPugY7CF95E4Jxp4Me
#   timestamp: 20240801-072216
export def 'links-view' [
    --quiet (-q) # Disable informational messages
    --no_timestamp # Don't output a timestamps column
]: [nothing -> table] {
    let $links = current-links-csv-path
        | if ($in | path exists) {
            open
            | if $no_timestamp { reject timestamp -i } else {} # remove this flag
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
    save (current-links-csv-path | backup-and-echo --mv) --force

    if not $quiet { links-view -q }
}

# Swap columns `from` and `to`
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

# Pin values of 'from_text' and 'to_text' columns to an IPFS node and fill `from` and `to` with their CIDs
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

export def 'links-pin-columns-using-kubo' [
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

# Remove existing in cybergraph cyberlinks from the temp table
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
                print -n $'($row.index) '

                link-exist $row.from $row.to $env.cy.address
            }
        }
        | sort-by index

    let $existed_links = $links_with_status
        | where link_exist?

    let $existed_links_count = $existed_links | length

    if $existed_links_count > 0 {
        cprint --before 1 $'*($existed_links_count) cyberlinks* was/were already created by *($env.cy.address)*'

        $existed_links
        | select -i from_text from to_text to
        | each {|i| print $i}

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
export def 'links-remove-existed-using-snapshot' [] {
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

# Create a tx from the piped in or temp cyberlinks table, sign and broadcast it
#
# > cy links-send-tx | to yaml
# cy: 2 cyberlinks should be successfully sent
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
        $links
        | upsert neuron $env.cy.address
        | upsert txhash $response.txhash
        | select from to neuron timestamp txhash
        | to csv --noheaders
        | $in + (char nl)
        | save --append --raw (cy-path mylinks _cyberlinks_archive.csv)

        links-view -q
        | skip $env.cy.links-per-transaction
        | links-replace

        {'cy': $'($links | length) cyberlinks should be successfully sent'}
        | merge $response
        | select cy txhash

    } else {
        print $response

        if $response.raw_log == 'not enough personal bandwidth' {
            print (query-links-bandwidth-neuron $env.cy.address)
            error make --unspanned {msg: (cprint --echo 'Increase your *Volts* balance or wait time.')}
        }
        if $response.raw_log =~ 'your cyberlink already exists' {
            error make --unspanned {msg: (cprint --echo 'Use *cy links-remove-existed-using-snapshot*')}
        }

        cprint 'The transaction might be not sent.'
    }
}

# remove duplicated or non-valid cyberlinks from the temp table
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
    let $links_per_trans = set-get-env links-per-transaction $links_per_trans

    links-view --quiet
    | links-prepare-for-publishing
    | links-replace
    | length
    | $in // $links_per_trans
    | if $nu.os-info.name == 'macos' {
        seq 0 $in
        | each {links-send-tx}
    } else { # in linux request for pin won't show up inside `each` cycle
        if $in > 1 {
            cprint $'Publising first ($links_per_trans) cyberlinks.
                You will need to exectue *links-publish* ($in - 1) more
                times.'
        }
        links-send-tx
    }
}

def 'inlinks-or-links' []: [nothing -> table, table -> table] {
    if $in == null {links-view -q} else {}
    | fill non-exist -v null
}

# Set a custom name for the temp links csv table
export def --env 'set-links-table-name' [
    name?: string@'nu-complete-links-csv-files' # a name for a temporary cyberlinks table file
]: nothing -> nothing {
    $env.cy.links_table_name = (
        $name
        | default $'temp_(now-fn)'
    )

    if $name == null {
        return $env.cy.links_table_name
    }
}
