use ../cy.nu *
use ../nu-utils internals [export1 cy-path]
use std assert [equal greater]

export-env {
    export1
    $env.IPFS_PATH = /Users/user/.ipfs_blank
}

export def tests-pin-text-1 [] {
    equal (pin-text 'cyber') 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
    equal (pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV') 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
    equal (
        pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
    ) 'QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F'
}


export def pin-text-2 [] {
    equal (pin-text 'tests/linkfilestest/cyber.txt') 'QmSFQ4nwTiQppHg3daTJ7GHFuiFFiu6mNjjeKN54ynTTUx'
    equal (pin-text ([tests linkfilestest cyber.txt] | path join) --follow_file_path) 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
}


export def link-texts-1 [] {
    equal {
        from_text: cyber,
        to_text: bostrom,
        from: "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
        to: "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"
    } (
        link-texts "cyber" "bostrom"
    )

    equal {
        from_text: "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
        to_text: "bostrom",
        from: "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
        to: "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"
    } (
        link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom"
    )

    equal {
        from_text: "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV",
        to_text: "bostrom",
        from: "QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F",
        to: "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"
    } (
        link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --ignore_cid
    )
}

export def 'link-chain-1' [] {
    set-cy-setting ipfs-upload-with-no-confirm 'true'
    equal (link-chain bostrom cyber superintelligence) [
        [from_text, to_text, from, to];
        [bostrom, cyber, "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"],
        [cyber, superintelligence, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M"]
    ]
}

export def link-files-1 [] {
    cd ('tests' | path join linkfilestest)
    let $temp_name = random chars
    set-links-table-name $temp_name

    let $expect = [
        [from_text, to_text, from, to];
        [bostrom.txt, "pinned_file:bostrom.txt",
        "QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"],
        [cyber.txt, "pinned_file:cyber.txt",
        "QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"]
    ]
    let $result = (
        link-files --link_filenames --yes --include_extension
    )
    equal $expect $result
}

export def link-files-2 [] {
    cd ('tests' | path join linkfilestest)
    let $temp_name = random chars
    set-links-table-name $temp_name

    let $expect = [
        [from_text, to_text, from, to];
        [bostrom.txt, "pinned_file:bostrom.txt",
        "QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"]
    ]

    let $result = (
        link-files --link_filenames --yes --include_extension bostrom.txt
    )
    equal $expect $result
}

export def follow-1 [] {
    equal {
        from_text: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx",
        to_text: "bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8",
        from: "QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx",
        to: "QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af"
    } (
        follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
    )
    equal (follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only) null
}

export def validator-chooser-1 [] {
    greater ( validator-chooser | length ) 1
}

export def caching-function-1 [] {
    equal (
        caching-function query rank karma bostrom1smsn8u0h5tlvt3jazf78nnrv54aspged9h2nl9 | describe
    ) 'record<karma: string, update_time: date>'
    equal (
        caching-function query bank balances bostrom1quchyywzdxp62dq3rwan8fg35v6j58sjwnfpuu | describe
    ) ('record<balances: table<denom: string, amount: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
    equal (
        caching-function query bank balances bostrom1cj8j6pc3nda8v708j3s4a6gq2jrnue7j857m9t | describe
    ) ('record<balances: table<denom: string, amount: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
    equal (
        caching-function query staking delegations bostrom1eg3v42jpwf3d66v6rnrn9hedyd8qvhqy4dt8pc | describe
    ) ('record<delegation_responses: table<delegation: record<delegator_address: string, ' +
        'validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, ' +
        'pagination: record<next_key: nothing, total: string>, update_time: date>')
    equal (
        caching-function query staking delegations bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | describe
    ) ('record<delegation_responses: table<delegation: record<delegator_address: string, ' +
        'validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, ' +
        'pagination: record<next_key: nothing, total: string>, update_time: date>')
    equal (
        caching-function query rank top | describe
    ) ('record<result: table<particle: string, rank: string>, pagination: record<total: int>, ' +
        'update_time: date>')
    equal (
        caching-function query ibc-transfer denom-traces | describe
    ) ('record<denom_traces: table<path: string, base_denom: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
    equal (
        caching-function query liquidity pools --cache_validity_duration 0sec | describe
    ) ('record<pools: table<id: string, type_id: int, reserve_coin_denoms: list<string>, ' +
        'reserve_account_address: string, pool_coin_denom: string>, pagination: record<next_key: ' +
        'nothing, total: string>, update_time: date>')
}

export def tweet-1 [] {

    let $expect = {
        from_text: "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx",
        to_text: "cyber-prophet is cool",
        from: "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx",
        to: "QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK"
    }
    links-clear
    let $result = tweet 'cyber-prophet is cool' --disable_send
    equal $expect $result
}

export def set-link-table-1 [] {
    let $temp_name = (random chars)
    set-links-table-name ($temp_name)
    link-texts 'cyber' 'bostrom'
}

export def link-complex-1 [] {
    set-links-table-name

    [[from_text, to_text]; ['cyber-prophet' '🤘'] ['tweet' 'cy is cool!']]
    | links-append

    links-pin-columns
    equal (
        links-view --no_timestamp
    ) [
        [from_text, to_text, from, to];
        [cyber-prophet, 🤘, "QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD",
            "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        [tweet, "cy is cool!", "QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx",
            "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    links-link-all 'cy testing script'
    equal (
        links-view --no_timestamp
    ) [
        [from_text, to_text, from, to];
        ["cy testing script", 🤘, "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx",
            "QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow"],
        ["cy testing script", "cy is cool!", "QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx",
            "QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8"]
    ]

    config-activate 42gboot+cyber
    link-random 3
    link-random 3 --source forismatic.com
    links-remove-existed-1by1
    equal (links-send-tx | get code) 0
}


export def passport-get-test [] {
    equal (passport-get bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel) {nickname: ?}
    equal (passport-get bostrom1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa) {nickname: ?} # unexisting address
    equal (passport-get bostrom1de53jgxjfj5n84qzyfd7z44m9wrudygt524v6r | get nickname) 'graphkeeper'
}


export def dict-neurons-view-test-dummy [] {
    equal (dict-neurons-view; null) null
    equal (dict-neurons-view --df; null) null
    equal (dict-neurons-view --path) (cy-path graph neurons_dict.yaml)
}

# #[test]
# export def graph-download-snapshot-test-dummy [] {
#     equal (graph-download-snapshot; null) null
# }

#[test]
# export def graph-receive-new-links-test-dummy [] {
#     equal (graph-receive-new-links; null) null
# }

#[test]
export def search-test-dummy [] {
    greater (search 'cy' | length) 0
}

#[test]
export def cid-download-kubo-test-dummy [] {
    equal (cid-download --source 'kubo' 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV') 'downloaded'
}

#[test]
export def cid-download-gateway-test-dummy [] {
    equal (cid-download --source 'gateway' QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV) 'downloaded'
}


#[test]
def test-tokens-routed-from [] {
    equal (tokens-routed-from bostrom1vu39vtn2ld3aapued6nwlhm7wpg2gj9zzlncek) null
    equal (tokens-routed-from bostrom1vu39vtn2ld3aapued6nwlhm7wpg2gj9zzlncej) []

    # seems like there is a mistake below
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8) [
        [denom, amount, state]; [milliampere, 3000, routed-from], [millivolt, 180000, routed-from]
    ]
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 --height 10124681) [
        [denom, amount, state]; [milliampere, 3000, routed-from], [millivolt, 180000, routed-from]
    ]
    equal (tokens-routed-from bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 --height 2000) []
}

export def graph-complex-1 [] {
    greater (
        graph-links-df | polars filter-with ((polars col timestamp) > ((date now) - 15day | format date %F)) | polars filter-with ((polars col timestamp) < (date now | format date %F)) | graph-stats | get neurons
    ) 0
}

export def graph-complex-2 [] {
    equal (
        graph-links-df | graph-neurons-stats | polars select nick links_count karma karma_norm karma_norm_bar | polars first 2 | polars into-nu | get 0.links_count | $in > 0
    ) true
}

export def graph-filter-system-particles-1 [] {
    equal (
        graph-links-df test-graph.csv | graph-filter-system-particles particle_from | polars shape | polars into-nu
    ) [
        [index, rows, columns]; [0, 76, 5]
    ]

    equal (
        graph-links-df test-graph.csv | graph-filter-system-particles particle_from --exclude | polars shape | polars into-nu
    ) [ [index, rows, columns]; [0, 1188, 5] ]
}

export def graph-merge-1 [] {
    equal (
        graph-links-df test-graph.csv
        | graph-filter-system-particles particle_from --exclude
        | graph-merge (graph-links-df test-graph.csv
        | graph-filter-system-particles particle_from)
        | polars group-by source
        | polars agg ((polars col source) | polars count | polars as count)
        | polars collect
        | polars into-nu
        | sort-by count
        | reject index
    ) [[source, count]; [b, 76], [a, 1188]]
}

export def graph-to-particles-1 [] {
    equal (
        graph-links-df test-graph.csv
        | graph-to-particles
        | polars first 3
        | polars into-nu
    ) (
        [ [index, neuron, particle, height, timestamp, init-role];
        [0, "bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k", "QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw", 9029, "2021-11-06 03:52:13", from],
        [1, "bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k", "QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR", 9029, "2021-11-06 03:52:13", to],
        [2, "bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t", "QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE", 12863, "2021-11-06 09:59:22", from] ]
    )
}
