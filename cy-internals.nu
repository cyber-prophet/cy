use nu-utils [ bar, cprint, "str repeat", to-safe-filename, to-number-format, number-col-format,
nearest-given-weekday, print-and-pass, clip, confirm, normalize, path-modify]

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
    let $config = $nu.home-path
        | path join .cy_config.toml
        | if ($in | path exists) { open } else { {} }

    default-settings
    | merge $config
    | default (cy-path) path
    | default (cy-path graph particles safe) ipfs-files-folder
    | default no-config-set config-name
}

export def default-settings []: nothing -> record {
    open (cy-path kickstart settings-variants.yaml)
    | items {|k v|
        $v.variants.0 # the first variant in the list is the default one
        | if $in == other { {} } else {
            match-type $v.type?
            | wrap $k
        }
    }
    | reduce -f {} {|i acc| $acc | merge $i}
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

    # if $nu.is-interactive {
    #     let $tested_versions = ['0.92.1' '0.92.2' '0.92.3']

    #     version
    #     | get version
    #     | if $in not-in $tested_versions {
    #         cprint $'This version of Cy was tested on ($tested_versions), and you have ($in).
    #             We suggest you to use one of the tested versions. If you installed *nushell*
    #             using brew, you can update it with the command *brew upgrade nushell*'
    #     }
    # }

    let $config = open-cy-config-toml

    let $user_config = $config.path
        | path join config $'($config.config-name).toml'
        | if ($in | path exists) { open } else {
            cprint $'A config file was not found. Run *cy config-new*'
            {}
        }

    make-default-folders-fn

    $env.cy = ($config | merge $user_config)
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

# Sets, retrieves, or defaults an environment variable based on input, without setting it if specified.
export def --env 'set-or-get-env-or-def' [
    key
    value?
    --dont_set_env
] {
    let $val_ref = $value
        | if $in != null {} else {
            $env.cy | get -i $key
        }
        | if $in != null {
            return $in
        } else {
            let $key_record = cy-path kickstart settings-variants.yaml
                | open
                | get -i $key

            $key_record
            | get -i variants.0
            | match-type $key_record.type?
        }

    if not $dont_set_env {
        $env.cy = ($env.cy | upsert $key $val_ref)
    }

    $val_ref
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
