use std log

use nu-utils [ bar, cprint, "str repeat", to-safe-filename, to-number-format, number-col-format,
nearest-given-weekday, print-and-pass, clip, confirm, normalize, path-modify]

use queue.nu *

export def 'cy-path' [
    ...folders: string # folders to add to cy path
    --create_missing # if the resulted path doesn't exist - create it
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
    | if $file != null {
        path join $file
    } else {}
}

export def open-cy-config-toml []: nothing -> record {
    $nu.home-path
    | path join .cy_config.toml
    | if ($in | path exists) { open } else { {} }
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
        'duration' => {$def_value | into duration}
        'bool' => {$def_value | into bool}
        _ => {$def_value | into string}
    }
}


export def export1 --env [] {
    let $config = open-cy-config-toml

    let $user_config = $config.path
        | path join config $'($config.config-name).toml'
        | if ($in | path exists) { open } else {
            cprint $'A config file was not found. Run *cy config-new*'
            {}
        }

    make-default-folders-fn

    $env.cy = (default-settings | merge $config | merge $user_config)
}

export def 'backup-and-echo' [
    filename?: path
    --quiet # don't echo the file-path back
    --mv # move the file to backup directory instead of copy
] {
    let $path = if $filename == null {} else {$filename}
    let $backups_path = cy-path backups $'(now-fn)($path | path basename)'

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
    cy-path --create_missing cache queue_cids_dead
    cy-path --create_missing cache queue_cids_to_download
    cy-path --create_missing cache queue_tasks_failed
    cy-path --create_missing cache queue_tasks_to_run
    cy-path --create_missing cache search
    cy-path --create_missing config
    cy-path --create_missing export
    cy-path --create_missing graph particles safe
    cy-path --create_missing mylinks
    cy-path --create_missing temp ipfs_upload
    cy-path --create_missing temp transactions

    touch (cy-path graph update.toml)

    if not (current-links-csv-path | path exists) {
        'from,to' | save (current-links-csv-path)
    }

    if not (cy-path mylinks _cyberlinks_archive.csv | path exists) {
        'from,to,address,timestamp,txhash'
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


# A wrapper, to cache CLI requests
export def --wrapped 'caching-function' [
    ...rest
    --exec: string = '' # The name of executable
    --cache_validity_duration: duration = 60min # Sets the cache's valid duration.
                                                # No updates initiated during this period.
                                                # set to 0sec to request for
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

    let $rest = $rest | flatten | flatten | into string

    let $cache_stale_refresh = set-get-env caching-function-cache_stale_refresh $cache_stale_refresh

    if $rest == [] { error make {msg: 'The "caching-function" function needs arguments'} }

    let $executable = if $exec != '' {$exec} else {$env.cy.exec}
    let $sub_commands_and_args = $rest
        | if $no_default_params {} else {
            append (default-node-params)
        }

    let $json_path = generate-cache-path $executable $sub_commands_and_args

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
        (request-save-output-exec-response $executable $sub_commands_and_args $json_path
            --error=$error --quiet=$quiet --last_data $last_data)
    } else {
        if $freshness > $cache_validity_duration {
            add-background-task $executable sub_commands_and_args
        }

        $last_data
    }
}

def 'request-save-output-exec-response' [
    executable: string
    sub_commands_and_args: list
    json_path: string
    --error
    --quiet
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

def generate-cache-path [
    $executable
    $sub_commands_and_args
] {
    $executable
    | append ($sub_commands_and_args)
    | str join '_'
    | str replace -r '--node.*' ''
    | str trim -c '_'
    | to-safe-filename --suffix '.json'
    | cy-path cache jsonl --file $in
}

def add-background-task [
    executable
    sub_commands_and_args
] {
    $sub_commands_and_args
    | each { str replace -a '"' '\"' | $'"($in)"' }
    | str join ' '
    | ($'caching-function --exec ($executable) --force_update [' +
        $in + '] | to yaml | lines | first 5 | str join "\n"')
    | queue-task-add -o 2 $in
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
] {
    date now
    | format date (
        if $pretty {'%Y-%m-%d-%H:%M:%S'} else {'%Y%m%d-%H%M%S'}
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
