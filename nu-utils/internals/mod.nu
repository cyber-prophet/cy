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
    | default (cy-path cy graph particles safe) ipfs-files-folder
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


export def export1 --env [ ] {
    let $tested_versions = ['0.92.1']

    version
    | get version
    | if $in not-in $tested_versions {
        cprint $'This version of Cy was tested on ($tested_versions), and you have ($in).
            We suggest you to use one of the tested versions. If you installed *nushell*
            using brew, you can update it with the command *brew upgrade nushell*'
    }

    let $config = open-cy-config-toml

    let $user_config = $config.path
        | path join config $'($config.config-name).toml'
        | if ($in | path exists) { open } else {
            cprint $'A config file was not found. Run *cy config-new*'
            {}
        }

    $env.cy = ($config | merge $user_config)
}
