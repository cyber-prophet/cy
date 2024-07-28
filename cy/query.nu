use cy-internals.nu *
use nu-utils ['cprint']
use cy-complete.nu *

# Get a current height for the active network in config
#
# > cy query-current-height | to yaml
# height: '9010895'
# time: 2023-07-11T11:37:40.708298734Z
# chain_id: bostrom
export def 'query-current-height' [
    exec?: string@'nu-complete-executables' # executable to use for the query
] {
    let $exec = $exec | default $env.cy.exec

    ^($exec) query block -n $env.cy.rpc-address
    | from json
    | get block.header
    | select height time chain_id
}

# Get a karma metric for a given neuron
#
# > cy query-rank-karma bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | to yaml
# karma: 852564186396
export def 'query-rank-karma' [
    neuron?: string # an address of a neuron
] {
    let $address = if $neuron == null {$env.cy.address} else {$neuron}

    caching-function query rank karma $address
    | default 0 karma
    | into int karma
}


# Query tx by hash
export def 'query-tx' [
    hash: string
    --full_info # display all columns of a transaction
]: nothing -> record {
    def trans_status [i] {
        if $i.code == 0 {'Transaction has been processed! ✅'} else {
            $'Transaction has been rejected: the code ($i.code?)'}
    }

    caching-function --error [query tx --type hash $hash]
    | if ($in | columns | $in == [update_time]) {
        error make {msg: (cprint --echo $'No transaction with hash ($hash) is found')}
    } else {
        reject -i events
    }
    | print-and-pass {|i| trans_status $i}
    | if $full_info {
        select -i ...($in | columns | prepend [height code logs tx txhash])
    } else {
        select height code logs
    }
    | upsert trans_status {|i| trans_status $i}
}

# Query tx by acc/seq
export def 'query-tx-seq' [
    neuron: string
    seq: int
]: nothing -> record {
    caching-function --disable_update [query tx --type=acc_seq $'($neuron)/($seq)']
    | reject -i events
}

# Query account
export def 'query-account' [
    neuron: string
    --height: int = 0 # a height to request a state on
    --seq # return sequence
]: nothing -> record {
    caching-function query account $neuron [--height $height]
    | if $seq {
        get base_vesting_account.base_account.sequence
        | into int
    } else {}
}

export def 'query-links-max-in-block' []: nothing -> int {
    ( query-links-bandwidth-params | get max_block_bandwidth ) / ( query-links-bandwidth-price )
    | into int
}

def 'query-links-bandwidth-price' []: nothing -> int {
    caching-function query bandwidth price
    | get price.dec
    | into float
    | $in * 1000
    | into int # price in millivolt
}

def 'query-links-bandwidth-params' []: nothing -> record {
    caching-function query bandwidth params
    | get params
    | transpose key value
    | into float value
    | transpose --ignore-titles --as-record --header-row
}

# Query status of authz grants for address
#
# > query-authz-grants-by-granter (qnbn bb🔑) | first 2 | to yaml
# - expired: true
#   expiration: 2023-04-25 05:40:44 +00:00
#   grantee: bostrom1yrv70gskxcn04xu03rpywd044gvz9l0mmhad2d
#   msg: /cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward
#   granter: bostrom1mcslqq8ghtuf6xu987qtk64shy6rd86a2xtwu8
#   '@type': /cosmos.authz.v1beta1.GenericAuthorization
# - expired: true
#   expiration: 2023-04-25 05:42:25 +00:00
#   grantee: bostrom1yrv70gskxcn04xu03rpywd044gvz9l0mmhad2d
#   msg: /cosmos.staking.v1beta1.MsgDelegate
#   granter: bostrom1mcslqq8ghtuf6xu987qtk64shy6rd86a2xtwu8
#   '@type': /cosmos.authz.v1beta1.GenericAuthorization
export def 'query-authz-grants-by-granter' [
    neuron? # an address of a neuron
] {
    $neuron
    | if ($in != null) { } else { $env.cy.address }
    | caching-function query authz grants-by-granter $in
    | get grants
    | each {|i| $i | merge $i.authorization | reject authorization}
    | upsert expiration {|i| $i.expiration | into datetime}
    | sort-by expiration
    | upsert expired {|i| $i.expiration < (date now)}
    | select -i expired expiration grantee msg ...($in | columns)
}

# Query status of authz grants for address
#
# > query-authz-grants-by-grantee bostrom1sgy27lctdrc5egpvc8f02rgzml6hmmvh5wu6xk | to yaml
# - expired: true
#   expiration: 2023-05-05 11:43:49 +00:00
#   granter: bostrom1angqedc8vu2dxa2d2cx7z5jjzm6vjldgtqm005
#   msg: /cyber.resources.v1beta1.MsgInvestmint
#   grantee: bostrom1sgy27lctdrc5egpvc8f02rgzml6hmmvh5wu6xk
#   '@type': /cosmos.authz.v1beta1.GenericAuthorization
export def 'query-authz-grants-by-grantee' [
    neuron? # an address of a neuron
] {
    $neuron
    | if ($in != null) { } else { $env.cy.address }
    | caching-function query authz grants-by-grantee $in
    | get grants
    | each {|i| $i | merge $i.authorization | reject authorization}
    | upsert expiration {|i| $i.expiration | into datetime}
    | sort-by expiration
    | upsert expired {|i| $i.expiration < (date now)}
    | select -i expired expiration granter msg ...($in | columns)
}
