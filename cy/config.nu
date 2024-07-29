use cy-complete.nu *
use nu-utils [ cprint print-and-pass]
use maintenance.nu [ check-requirements ]
use cy-internals.nu *
export use cy-internals.nu load-default-env
use passport.nu *

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

    $config_path
    | if ($in | path exists) {
        open
    } else {{}}
    | upsert config-name $config_name
    | save -f $config_path

    load-default-env
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
