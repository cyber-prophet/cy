use queue.nu [caching-function]

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
