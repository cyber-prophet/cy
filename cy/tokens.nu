use cy-internals.nu ['fill non-exist']
use nu-utils ['cprint']
use cy-complete.nu *

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
    caching-function query bank total --height $height
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
    caching-function query staking delegations ($address | default $env.cy.address) --height $height
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
# The emoji 🛑 means that it has been sent not from the network that issued this token.
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
    | join --left (cy-path kickstart ibc_denoms.csv | open) denom
    | each { |i| $i
        | if $i.base_denom? == null {
            merge (
                $i.denom
                | str replace 'ibc/' ''
                | caching-function query ibc-transfer denom-trace $"'($in)'" --retries 1
                | get -i denom_trace
                | default {path: '00-00' base_denom: 'unknown'}
            )
        } else {}
    }
    | upsert token {|i|
        tokens-shorten-ibc $i.denom $i.base_denom $i.path
    }
    | sort-by path --natural
    | reject path amount
    | if $full {} else {
        select denom token
    }
}

export def 'tokens-denoms-exponent-dict' [] {
    open tokenList.js
    | str replace -r -m '(?s).*(\[.*\]).*' '$1'
    | from nuon
    | rename -c {'coinMinimalDenom': 'base_denom'}
    | rename -c {'denom': 'ticker'}
    | append [
        [base_denom, ticker, coinDecimals];
        [usomm SOMM 6]
        [ucre CRE 6]
        [boot mBOOT 6]
        [pussy gPUSSY 9]
        [hydrogen mH 6]
        [tocyb mTOCYB 6]
    ]
    | rename -c {'coinDecimals': 'exponent'}
    | select base_denom ticker exponent
    | reverse
    | uniq-by base_denom
}

# Get info about tokens from the on-chain-registry contract
#
# https://github.com/Snedashkovsky/on-chain-registry
export def 'tokens-info-from-registry' [
    chain_name: string = 'bostrom'
    --full # show full data
] {
    'bostrom1w33tanvadg6fw04suylew9akcagcwngmkvns476wwu40fpq36pms92re6u'
    | append ({get_assets_by_chain: {chain_name: $chain_name}} | to json -r)
    | append ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']
    | caching-function --exec 'cyber' --no_default_params query wasm contract-state smart ...$in
    | get data.assets
    | if $full {} else {
        where display != null # tokens with no information
        | insert path {|i|
            if $i.traces? == null {''} else {
                $i.traces
                | get chain.path.0
                | split row '/'
                | drop
                | str join '/'
            }
        }
        | upsert exponent {|i| $i.denom_units?.exponent? | default [0] | math max}
        | select base display exponent chain_id path -i
        | rename denom base_denom
    }
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
        | select base_denom denom
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
    let $input = join -l (tokens-ibc-denoms-table) denom | fill non-exist -v ''

    let $columns = $input | columns

    if ($columns | where $it =~ 'amount_in_h' | length) > 0 {
        reduce -f $input {|i acc| $acc | merge ($acc | number-col-format $i --decimals 0 --denom 'H')}
    } else {$input}
    # $input
    | upsert token {|i| if $i.token? != '' {$i.token} else {$i.denom}}
    | move token --before ($in | columns | first)
    | move denom --after ($in | columns | last)
    | upsert base_denom {|i| $i.token | split row '/' | get 0 }
    | join -l (tokens-denoms-exponent-dict) base_denom
    | default 0 exponent
    | upsert token {
        |i| $i.token
        | str replace $i.base_denom ($i.ticker? | default ($i.token | str upcase))
    }
    | if amount in $columns {
        upsert amount_f {
            |i| $i.amount / (10 ** $i.exponent)
            | to-number-format --integers 9 --decimals 0
        }
        | move amount_f --after token
    } else {}
    | reject -i base_denom ticker exponent
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

def 'tokens-shorten-ibc' [
    denom: string
    base_denom: string
    path: string
] {
    $path #denom compound
    | str replace --regex --all '[^-0-9]' ''
    | str trim -c '-'
    | if ($in | split row '-' | length | $in > 1) {
        '🛑'
    } else {}
    | $'($base_denom)/($denom | str substring 62..68)/($in)'
}
