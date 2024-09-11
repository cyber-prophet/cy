use std log

use nu-utils [ bar, cprint, "str repeat", to-safe-filename, to-number-format, number-col-format,
nearest-given-weekday, print-and-pass, clip, confirm, normalize, path-modify]

export def 'cy-path' [
    ...folders: string # folders to add to cy path
    --create_missing # if the resulted path doesn't exist - create it
    --ts_extension: string = '' # name a file with timestamp and extension, precides file
    --file: string # a filename to use as a last segment of the path
]: nothing -> path {
    $env | get -i cy.path
    | default ($nu.home-path | path join 'cy')
    | append $folders
    | path join
    | path expand
    | if $create_missing {
        if not ($in | path exists) {
            let $input = $in
            mkdir $input
            $input
        } else {}
    } else {}
    | if $ts_extension != '' {
        path join (
            date now
            | format date '%F_%T_%f'
            | str replace -ra '([^\d_])' ''
            | $in + '.' + $ts_extension
        )
    } else if $file != null {
        path join $file
    } else {}
}

export def open-global-config-toml []: nothing -> record {
    let $path = $nu.home-path | path join .cy_config.toml

    if ($path | path exists) {
        open $path
    } else {
        {} | save $path;
        {}
    }
    | default (cy-path) path
    | default (cy-path graph particles safe) ipfs-files-folder
    | default no-config-set config-name
}

export def default-settings []: nothing -> record {
    cy-path kickstart settings-variants.yaml
    | open
    | items {|k v| {k: $k v: ($v.variants.0 | match-type $v.type?)}}
    | where v != 'other'
    | transpose -idr
}

export def match-type [
    $type?
]: any -> any {
    let $def_value = $in
    match $type {
        'int' => {$def_value | into int}
        'datetime' => {$def_value | into datetime}
        'duration' => {
            $def_value
            | if ($in | describe) == 'duration' {

            } else if ($in =~ '\D') { # if it contains `wk` or similar
                into duration
            } else {
                # i don't know where it saves durations as int here, so i handle it this way
                into int | into duration
            }
        }
        'bool' => {$def_value | into bool}
        _ => {$def_value | into string}
    }
}


export def load-default-env --env [] {
    let $global_config = open-global-config-toml

    let $user_config = $global_config.path
        | path join config $'($global_config.config-name).toml'
        | if ($in | path exists) { open } else {
            cprint $'A config file was not found. Run *cy config-new*'
            {}
        }

    make-default-folders-fn

    let $types_dict = cy-path kickstart settings-variants.yaml | open

    $env.cy = (
        default-settings
        | merge $global_config
        | merge $user_config
        | items {|k v|
            {
                key: $k
                value: ($v | match-type ($types_dict | get -i $k | get -i type))
            }
        }
        | transpose -idr
    )
}

export def 'backup-and-echo' [
    filename?: path
    --quiet # don't echo the file-path back
    --mv # move the file to backup directory instead of copy
] {
    let $path = if $filename == null {} else {$filename}
    let $backups_path = cy-path backups $'(now-fn --precise)($path | path basename)'

    if not ( $path | path exists ) {
        cprint $'*($path)* does not exist'
        return $path
    }

    if $mv {
        mv $path $backups_path
    } else {
        cp $path $backups_path
    }

    if not $quiet { $path }
}


export def 'set-select-from-variants' [
    $key
] {
    let $key_record = cy-path kickstart settings-variants.yaml
        | open
        | get -i $key

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

# Sets an environment variable if a value is provided; otherwise, retrieves the current value of the environment variable.
export def --env 'set-get-env' [
    key
    value?
] {
    if $value != null {
        $env.cy = ($env.cy | upsert $key $value)
        return $value
    } else {
        $env.cy | get $key
    }
}


export def make-default-folders-fn []: nothing -> nothing {
    cy-path --create_missing backups
    cy-path --create_missing cache cli_out
    cy-path --create_missing cache jsonl
    cy-path --create_missing cache search
    cy-path --create_missing config
    cy-path --create_missing export
    cy-path --create_missing graph particles safe
    cy-path --create_missing mylinks invalid
    cy-path --create_missing temp ipfs_upload
    cy-path --create_missing temp queue_cids_dead
    cy-path --create_missing temp queue_cids_to_download
    cy-path --create_missing temp queue_tasks_failed
    cy-path --create_missing temp queue_tasks_to_run
    cy-path --create_missing temp transactions
    cy-path --create_missing temp transaction_errors

    touch (cy-path graph update.toml)

    if not (current-links-csv-path | path exists) {
        'from,to' | save (current-links-csv-path)
    }

    if not (cy-path mylinks _cyberlinks_archive.csv | path exists) {
        'from,to,neuron,timestamp,txhash' + (char nl)
        # underscore is supposed to place the file first in the folder
        | save (cy-path mylinks _cyberlinks_archive.csv)
    }
}

export def 'path-exists-safe' [
    path_to_check
] {
    try {$path_to_check | path exists} catch {false}
}

# > [{a: 1} {b: 2}] | to nuon
# [{a: 1}, {b: 2}]
#
# > [{a: 1} {b: 2}] | fill non-exist | to nuon
# [[a, b]; [1, null], [null, 2]]
export def 'fill non-exist' [
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

export def 'current-links-csv-path' [
    name?: path
]: nothing -> path {
    $name
    | default ($env.cy?.links_table_name?)
    | default 'temp'
    | cy-path mylinks $'($in).csv'
}

export def is-cid [particle: string] {
    $particle =~ '^Qm\w{44}$'
}

export def is-neuron [address: string] {
    $address =~ '^(bostrom|pussy)(\w{39}|\w{59})$'
}

export def is-validator [address: string] {
    $address =~ '^(bostrom|pussy)\w{46}$'
}

export def is-connected [] {
    (do -i {http get https://duckduckgo.com/} | describe) == 'raw input'
}

export def 'default-node-params' [] {
    [
        '--node' $env.cy.rpc-address
        '--chain-id' $env.cy.chain-id # todo chainid to choose
        '--output' 'json'
    ]
}

export def 'col-name-reverse' [
    column: string
] {
    match $column {
        'from' => {'to'},
        'to' => {'from'},
        _ => {''}
    }
}

export def 'now-fn' [
    --pretty (-P)
    --precise (-p)
] {
    date now
    | format date (
        if $pretty {
            '%Y-%m-%d-%H:%M:%S'
        } else if $precise {
            '%Y%m%d-%H%M%S-%f'
        } else {
            '%Y%m%d-%H%M%S'
        }
    )
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

export def dict-neurons-bare [
    --path
] {
    cy-path graph neurons_dict.yaml
    | if $path {
        return $in
    } else {}
    | if ($in | path exists) {
        open
    } else { [[neuron nickname];
        ['bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8' 'maxim']] }
}
