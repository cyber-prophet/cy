use cy-internals.nu [cy-path]

# Create a custom unsigned cyberlinks transaction
export def 'tx-json-create-from-cyberlinks' [
    $links # removed type definition for the case of empty tables
]: table -> path {
    let $links = $links | select from to | uniq
    let $path = cy-path temp transactions --file $'($env.cy.address)-(now-fn)-cyberlink-unsigned.json'

    tx-message-links $env.cy.address $links
    | tx-create $in
    | save $path --force

    $path
}

export def 'tx-message-links' [
    $neuron
    $links_table: table<from: string, to: string> # [[from, to]; ["", ""]]
] {
    {
        @type: "/cyber.graph.v1beta1.MsgCyberlink",
        neuron: $neuron,
        links: $links_table
    }
}

export def 'tx-create' [
    message?
    --memo: string = 'cy'
    --gas = 23456789
    --fee = 0
    --timeout_height = 0
]: [record -> record, list -> record] {
    let msg = $message | describe
        | if ($in =~ '^list') {
            $message
        } else if ($in =~ '^record') {
            [$message]
        } else {
            error make {msg: $'Message should be record or list. Received ($in)'}
        }

    {
        body: {
            messages: $msg,
            memo: $memo,
            timeout_height: ($timeout_height | into string),
            extension_options: [],
            non_critical_extension_options: []
        },
        auth_info: {
            signer_infos: [],
            fee: {
                amount: [ {denom: boot, amount: ($fee | into string)} ],
                gas_limit: ($gas | into string),
                payer: "",
                granter: ""
            }
        }, signatures: []
    }
}

export def 'tx-authz' [ ]: path -> path {
    let $json_tx_path = $in
    let $out_path = $json_tx_path | path-modify --suffix 'authz'

    let $current_json = open $json_tx_path

    $current_json
    | upsert body.messages.neuron $env.cy.authz
    | upsert body.messages {|i| [ {
        "@type": "/cosmos.authz.v1beta1.MsgExec",
        "grantee": $current_json.body.messages.neuron.0
        "msgs": $i.body.messages
    } ] }
    | to json -r
    | save --raw --force $out_path

    $out_path
}

export def 'tx-sign' [ ]: path -> path {
    let $unsigned_tx_path = $in
    let $out_path = $unsigned_tx_path | str replace 'unsigned' 'signed'
    let $params = [
            --from $env.cy.address
            --chain-id $env.cy.chain-id
            --node $env.cy.rpc-address
            --output-document $out_path
        ]
        | if $env.cy.keyring-backend? == 'test' {
            append ['--keyring-backend' 'test']
        } else {}

    let $response = ^($env.cy.exec) tx sign $unsigned_tx_path ...$params
        | complete

    if $response.exit_code != 0 {
        $response.stderr
        | lines
        | first
        | error make --unspanned {msg: $in}
    }

    $out_path
}

export def 'tx-broadcast' []: path -> record {
    ^($env.cy.exec) tx broadcast $in ...[
        --broadcast-mode block
        --output json
        --node $env.cy.rpc-address
        --yes
    ]
    | complete
    | if ($in.exit_code != 0 ) {
        {code: $in.exit_code}
    } else {
        get stdout | from json
    }
}

export def 'tx-message-investmint' [
    neuron: string
    --h_amount: int
    --resource: string
    --length: int
] {
    {
        @type: "/cyber.resources.v1beta1.MsgInvestmint",
        neuron: $neuron,
        amount: {
            denom: hydrogen,
            amount: ($h_amount | into string)
        },
        resource: $resource,
        length: ($length | into string)
    }
}
