
# A wrapper, to cache CLI requests
export def 'ber' [
    ...rest
    --seconds: int = 86400
    --exec: string
    --abci: string
    --absolutetimeouts
    --account: string
    --accountnumber (-a): string
    --address: string
    --admin: string
    --algo: string
    --allowedmessages: string
    --allowedvalidators: string
    --amino
    --amount: string
    --ascii
    --b64
    --bech: string
    --broadcastmode (-b): string
    --chainid: string
    --cointype: string
    --commission
    --commissionmaxchangerate: string
    --commissionmaxrate: string
    --commissionrate: string
    --computegpu
    --consensuscreate_empty_blocks
    --consensuscreate_empty_blocks_interval: string
    --consensusdouble_sign_check_height: string
    --counttotal
    --cpuprofile: string
    --db_backend: string
    --db_dir: string
    --delayed
    --denom: string
    --denyvalidators: string
    --deposit: string
    --depositor: string
    --description: string
    --details: string
    --device (-d)
    --dryrun
    --events: string
    --expiration: string
    --fast_sync
    --feeaccount: string
    --fees: string
    --force (-f)
    --forzeroheight
    --from: string
    --gas: string
    --gasadjustment: string
    --gasprices: string
    --generateonly
    --genesis_hash: string
    --genesistime: string
    --gentxdir: string
    --grpcaddress: string
    --grpcenable
    --grpconly
    --grpcwebaddress: string
    --grpcwebenable
    --haltheight: string
    --halttime: string
    --hdpath: string
    --height: string
    --help (-h)
    --hex
    --hex (-x)
    --home: string
    --iavldisablefastnode
    --identity: string
    --index: string
    --instantiateeverybody: string
    --instantiatenobody: string
    --instantiateonlyaddress: string
    --interactive (-i)
    --interblockcache
    --invcheckperiod: string
    --ip: string
    --jailallowedaddrs: string
    --keepaddrbook
    --keyringbackend: string
    --keyringdir: string
    --label: string
    --latestheight
    --ledger
    --limit: string
    --listnames (-n)
    --log_format: string
    --log_level: string
    --long
    --maxmsgs: string
    --minimumgasprices: string
    --minretainblocks: string
    --minselfdelegation: string
    --moniker: string
    --msgtype: string
    --multisig: string
    --multisigthreshold: string
    --newmoniker: string
    --noadmin
    --noautoincrement
    --nobackup
    --node (-n): string
    --node: string
    --nodedaemonhome: string
    --nodedirprefix: string
    --nodeid: string
    --nosort
    --note: string
    --offline
    --offset: string
    --output (-o): string
    --output: string
    --outputdir (-o): string
    --outputdocument: string
    --overwrite
    --overwrite (-o)
    --p2pexternaladdress: string
    --p2pladdr: string
    --p2ppersistent_peers: string
    --p2ppex
    --p2pprivate_peer_ids: string
    --p2pseed_mode
    --p2pseeds: string
    --p2punconditional_peer_ids: string
    --p2pupnp
    --packettimeoutheight: string
    --packettimeouttimestamp: string
    --page: string
    --pagekey: string
    --period: string
    --periodlimit: string
    --poolcoindenom: string
    --priv_validator_laddr: string
    --proposal: string
    --prove
    --proxy_app: string
    --pruning: string
    --pruninginterval: string
    --pruningkeepevery: string
    --pruningkeeprecent: string
    --pubkey: string
    --recover
    --reserveacc: string
    --reverse
    --rpcgrpc_laddr: string
    --rpcladdr: string
    --rpcpprof_laddr: string
    --rpcunsafe
    --runas: string
    --searchapi
    --securitycontact: string
    --sequence (-s): string
    --sequences: string
    --signatureonly
    --signmode: string
    --spendlimit: string
    --startingipaddress: string
    --statesyncsnapshotinterval: string
    --statesyncsnapshotkeeprecent: string
    --status: string
    --timeoutheight: string
    --title: string
    --trace
    --tracestore: string
    --transport: string
    --type: string
    --unarmoredhex
    --unsafe
    --unsafeentropy
    --unsafeskipupgrades: string
    --upgradeheight: string
    --upgradeinfo: string
    --v: string
    --vestingamount: string
    --vestingendtime: string
    --vestingstarttime: string
    --voter: string
    --wasmmemory_cache_size: string
    --wasmquery_gas_limit: string
    --wasmsimulation_gas_limit: string
    --website: string
    --withtendermint
    --xcrisisskipassertinvariants
    --yes (-y)
] {
    let $flags_nu = [
        $absolutetimeouts, $amino, $ascii, $b64, $commission, $computegpu,
        $consensuscreate_empty_blocks, $counttotal, $delayed, $device,
        $dryrun, $fast_sync, $force, $forzeroheight, $generateonly,
        $grpcenable, $grpconly, $grpcwebenable, $help, $hex, $iavldisablefastnode,
        $interactive, $interblockcache, $keepaddrbook, $latestheight, $ledger, $listnames,
        $long, $noadmin, $noautoincrement, $nobackup, $nosort, $offline, $overwrite,
        $p2ppex, $p2pseed_mode, $p2pupnp, $prove, $recover, $reverse, $rpcunsafe,
        $searchapi, $signatureonly, $trace, $unarmoredhex, $unsafe, $unsafeentropy,
        $withtendermint, $xcrisisskipassertinvariants, $yes
    ]
    let $flags_cli = ([
        '--absolute-timeouts', '--amino', '--ascii', '--b64', '--commission', '--compute-gpu',
        '--consensus.create_empty_blocks', '--count-total', '--delayed', '--device',
        '--dry-run', '--fast_sync', '--for-zero-height', '--force', '--generate-only',
        '--grpc-only', '--grpc-web.enable', '--grpc.enable', '--help', '--hex', '--iavl-disable-fastnode',
        '--inter-block-cache', '--interactive', '--keep-addr-book', '--latest-height', '--ledger', '--list-names',
        '--long', '--no-admin', '--no-auto-increment', '--no-backup', '--nosort', '--offline', '--overwrite',
        '--p2p.pex', '--p2p.seed_mode', '--p2p.upnp', '--prove', '--recover', '--reverse', '--rpc.unsafe',
        '--search-api', '--signature-only', '--trace', '--unarmored-hex', '--unsafe', '--unsafe-entropy',
        '--with-tendermint', '--x-crisis-skip-assert-invariants', '--yes'
    ])

    let $options_nu = [
        $abci, $account, $accountnumber, $address, $admin, $algo, $allowedmessages,
        $allowedvalidators, $amount, $bech, $broadcastmode, $chainid, $cointype,
        $commissionmaxchangerate, $commissionmaxrate, $commissionrate,
        $consensuscreate_empty_blocks_interval, $consensusdouble_sign_check_height,
        $cpuprofile, $db_backend, $db_dir, $denom, $denyvalidators, $deposit, $depositor,
        $description, $details, $events, $expiration, $feeaccount, $fees, $from, $gas,
        $gasadjustment, $gasprices, $genesis_hash, $genesistime, $gentxdir, $grpcaddress,
        $grpcwebaddress, $haltheight, $halttime, $hdpath, $height, $home, $identity, $index,
        $instantiateeverybody, $instantiatenobody, $instantiateonlyaddress, $invcheckperiod,
        $ip, $jailallowedaddrs, $keyringbackend, $keyringdir, $label, $limit, $log_format,
        $log_level, $maxmsgs, $minimumgasprices, $minretainblocks, $minselfdelegation,
        $moniker, $msgtype, $multisig, $multisigthreshold, $newmoniker, $node, $nodedaemonhome,
        $nodedirprefix, $nodeid, $note, $offset, $output, $outputdir, $outputdocument,
        $p2pexternaladdress, $p2pladdr, $p2ppersistent_peers, $p2pprivate_peer_ids, $p2pseeds,
        $p2punconditional_peer_ids, $packettimeoutheight, $packettimeouttimestamp, $page,
        $pagekey, $period, $periodlimit, $poolcoindenom, $priv_validator_laddr, $proposal,
        $proxy_app, $pruning, $pruninginterval, $pruningkeepevery,
        $pruningkeeprecent, $pubkey, $reserveacc, $rpcgrpc_laddr, $rpcladdr, $rpcpprof_laddr,
        $runas, $securitycontact, $sequence, $sequences, $signmode, $spendlimit, $startingipaddress,
        $statesyncsnapshotinterval, $statesyncsnapshotkeeprecent, $status, $timeoutheight, $title,
        $tracestore, $transport, $type, $unsafeskipupgrades, $upgradeheight, $upgradeinfo, $v,
        $vestingamount, $vestingendtime, $vestingstarttime, $voter, $wasmmemory_cache_size,
        $wasmquery_gas_limit, $wasmsimulation_gas_limit, $website
    ]
    let $options_cli = [
        '--abci', '--account', '--account-number', '--address', '--admin', '--algo', '--allowed-messages',
        '--allowed-validators', '--amount', '--bech', '--broadcast-mode', '--chain-id', '--coin-type',
        '--commission-max-change-rate', '--commission-max-rate', '--commission-rate',
        '--consensus.create_empty_blocks_interval', '--consensus.double_sign_check_height',
        '--cpu-profile', '--db_backend', '--db_dir', '--denom', '--deny-validators', '--deposit', '--depositor',
        '--description', '--details', '--events', '--expiration', '--fee-account', '--fees', '--from', '--gas',
        '--gas-adjustment', '--gas-prices', '--genesis-time', '--genesis_hash', '--gentx-dir',
        '--grpc-web.address', '--grpc.address', '--halt-height', '--halt-time', '--hd-path', 
        '--height', '--home', '--identity', '--index',
        '--instantiate-everybody', '--instantiate-nobody', '--instantiate-only-address', 
        '--inv-check-period',
        '--ip', '--jail-allowed-addrs', '--keyring-backend', '--keyring-dir', '--label', '--limit', '--log_format',
        '--log_level', '--max-msgs', '--min-retain-blocks', '--min-self-delegation', '--minimum-gas-prices',
        '--moniker', '--msg-type', '--multisig', '--multisig-threshold', '--new-moniker', '--node', '--node-daemon-home',
        '--node-dir-prefix', '--node-id', '--note', '--offset', '--output', '--output-dir', '--output-document',
        '--p2p.external-address', '--p2p.laddr', '--p2p.persistent_peers', '--p2p.private_peer_ids', '--p2p.seeds',
        '--p2p.unconditional_peer_ids', '--packet-timeout-height', '--packet-timeout-timestamp', '--page',
        '--page-key', '--period', '--period-limit', '--pool-coin-denom', '--priv_validator_laddr', '--proposal',
        '--proxy_app', '--pruning', '--pruning-interval', '--pruning-keep-every',
        '--pruning-keep-recent', '--pubkey', '--reserve-acc', '--rpc.grpc_laddr', '--rpc.laddr', '--rpc.pprof_laddr',
        '--run-as', '--security-contact', '--sequence', '--sequences', '--sign-mode', 
        '--spend-limit', '--starting-ip-address',
        '--state-sync.snapshot-interval', '--state-sync.snapshot-keep-recent', '--status', '--timeout-height', '--title',
        '--trace-store', '--transport', '--type', '--unsafe-skip-upgrades', '--upgrade-height', '--upgrade-info', '--v',
        '--vesting-amount', '--vesting-end-time', '--vesting-start-time', '--voter', '--wasm.memory_cache_size',
        '--wasm.query_gas_limit', '--wasm.simulation_gas_limit', '--website'
    ]

    let $list_flags_out = (
        $flags_nu
        | enumerate
        | reduce -f [] {
            |i acc| if $i.item {
                $acc
                | append ($flags_cli | get $i.index)
            } else {
                $acc
            }
        }
    )

    let $list_options_out = (
        $options_nu
        | enumerate
        | reduce -f [] {
            |i acc| if not ($i.item | is-empty) {
                $acc
                | append ($options_cli | get $i.index)
                | append $i.item
            } else {
                $acc
            }
        }
    )
    # print $list_flags_out

    let $exec = ($exec | default $env.cy.exec)

    let $important_options = (
        $list_options_out
        | enumerate
        | reduce -f '' {
            |i acc| if ($i.item in ['--page', '--height', '--events']) {
                [$acc $i.item ($list_options_out | get ($i.index + 1))] | str join ''
            } else {
                $acc
            }
        } | '+' + $in
    )

    let $cfolder = $'($env.cy.path)/cache/cli_out/'
    let $command = $'($exec)_($rest | str join "_")($important_options | str replace "/" "")'
    let $ts1 = (date now | into int)

    # print $important_options
    let $filename = $'($cfolder)($command)-($ts1).json'

    let $cache_ls = (ls $cfolder)

    # print 'cached_files'
    let $cached_file = (
        if $cache_ls != null {
            # print '$cache_ls != null'

            let $a1 = (
                $cache_ls
                | where name =~ $'($command)'
                | inspect
            )

            if ($a1 | length) == 0 {
                # print 'here is null'
                null
            } else {
                $a1
                | sort-by modified --reverse
                | where modified > (date now | into int | $in - $seconds | into datetime)
                | get -i name.0
            }
        } else {
            null
        }
    )

    let $content = (
        if ($cached_file != null) {
            print 'cached used'
            open $cached_file
        } else  {
            print $'request command from cli, saving to ($filename)'
            print $'($exec) ($rest) --output json ($list_flags_out)'
            # let $out = (^($exec) $rest --output json $list_options_out $list_flags_out | from json)
            [
                $exec 
                ($rest | str join " ")
                '--output json'
                ($list_options_out | str join " ")
                ($list_flags_out | str join " ")
                '| save -r' 
                ($filename)
            ] | str join ' '
            | pu-add $in 
            # let $out1 = do -i {^($exec) $rest --output json $list_flags_out | from json}
            # let $out = (^($exec) $rest --output json $list_options_out $list_flags_out | from json)
            # if $out != null {$out | save $filename}
            # $out

        }
    )

    $content
}