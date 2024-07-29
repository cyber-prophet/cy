use cy-complete.nu *

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

    generate $closure $start
    | flatten
    | flatten
    | into int amount
    | move denom amount --before validator_address
    | rename neuron
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

export def 'crypto-prices' [] {
    http get 'https://api.coincap.io/v2/assets' | get data
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

export def 'banner' [] {
    print $"
     ____ _   _
    / ___\) | | |
   \( \(___| |_| |
    \\____)\\__  |   (ansi yellow)cy(ansi reset) nushell module is loaded
         \(____/    have fun🔵"
}

export def 'banner2' [] {
    print $'(ansi yellow)cy(ansi reset) is loaded'
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
