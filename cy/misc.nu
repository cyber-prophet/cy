use cy-complete.nu *

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
