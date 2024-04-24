```nushell
> $env.config.table.abbreviated_row_count = 10000
> help-cy
╭────────────────────command────────────────────┬───────────────────────────────────desc───────────────────────────────────╮
│ cy pin-text                                   │ Pin a text particle                                                      │
│ cy link-texts                                 │ Add a 2-texts cyberlink to the temp table                                │
│ cy link-chain                                 │ Add a link chain to the temp table                                       │
│ cy link-files                                 │ Pin files from the current folder to the local node and append their ... │
│ cy follow                                     │ Create a cyberlink according to semantic construction of following a ... │
│ cy tweet                                      │ Add a tweet and send it immediately (unless of disable_send flag)        │
│ cy link-random                                │ Make a random cyberlink from different APIs (chucknorris.io, forismat... │
│ cy links-view                                 │ View the temp cyberlinks table                                           │
│ cy links-append                               │ Append piped-in table to the temp cyberlinks table                       │
│ cy links-replace                              │ Replace the temp table with piped-in table                               │
│ cy links-swap-from-to                         │ Swap columns from and to                                                 │
│ cy links-clear                                │ Empty the temp cyberlinks table                                          │
│ cy links-link-all                             │ Add the same text particle into the 'from' or 'to' column of the temp... │
│ cy links-pin-columns                          │ Pin values from column 'text_from' and 'text_to' to an IPFS node and ... │
│ cy links-remove-existed-1by1                  │ Remove existing cyberlinks from the temp cyberlinks table                │
│ cy links-remove-existed-2                     │ Remove existing links using graph snapshot data                          │
│ cy links-publish                              │ Publish all links from the temp table to cybergraph                      │
│ cy tsv-copy                                   │ Copy a table from the pipe into the clipboard (in tsv format)            │
│ cy tsv-paste                                  │ Paste a table from the clipboard to stdin (so it can be piped further)   │
│ cy message-send                               │ send message to neuron with (in 1boot transaction with memo)             │
│ cy passport-get                               │ Get a passport by providing a neuron's address or nick                   │
│ cy passport-set                               │ Set a passport's particle, data or avatar field for a given nickname     │
│ cy dict-neurons-view                          │ Output neurons dict                                                      │
│ cy dict-neurons-add                           │ Add piped in neurons to YAML-dictionary with tag and category            │
│ cy dict-neurons-tags                          │ Ouput dict-neurons tags                                                  │
│ cy doctor                                     │ Fix some problems of cy (for example caused by updates)                  │
│ cy dict-neurons-update                        │ Update neurons YAML-dictionary                                           │
│ cy graph-download-snapshot                    │ Download a snapshot of cybergraph                                        │
│ cy graph-receive-new-links                    │ Download the latest cyberlinks from a hasura cybernode endpoint          │
│ cy graph-download-missing-particles           │ download particles missing from local cache for followed neurons or t... │
│ cy graph-filter-system-particles              │ filter system particles out                                              │
│ cy graph-merge                                │ merge two graphs together, add the `source` column                       │
│ cy graph-to-particles                         │ Output unique list of particles from piped in cyberlinks table           │
│ cy particles-keep-only-first-neuron           │ In the piped in particles df leave only particles appeared for the fi... │
│ cy graph-update-particles-parquet             │ Update the 'particles.parquet' file (it inculdes content of text files)  │
│ cy graph-filter-neurons                       │ Filter the graph to chosen neurons only                                  │
│ cy graph-filter-contracts                     │ Filter the graph to keep or exclude links from contracts                 │
│ cy graph-append-related                       │ Append related cyberlinks to the piped in graph                          │
│ cy graph-neurons-stats                        │ Output neurons stats based on piped in or the whole graph                │
│ cy graph-stats                                │ Output graph stats based on piped in or the whole graph                  │
│ cy graph-to-gephi                             │ Export a graph into CSV file for import to Gephi                         │
│ cy graph-to-logseq                            │ Logseq export WIP                                                        │
│ cy graph-to-txt-feed                          │ Output particles into txt formated feed                                  │
│ cy graph-to-cosmograph                        │ Export piped-in graph to a CSV file in cosmograph format                 │
│ cy graph-to-graphviz                          │ Export piped-in graph into graphviz format                               │
│ cy graph-add-metadata                         │ Add content_s and neuron's nicknames columns to piped in or the whole... │
│ cy graph-links-df                             │ Output a full graph, or pass piped in graph further                      │
│ cy config-new                                 │ Create a config JSON to set env variables, to use them as parameters ... │
│ cy config-view                                │ View a saved JSON config file                                            │
│ cy config-save                                │ Save the piped-in JSON into config file                                  │
│ cy config-activate                            │ Activate the config JSON                                                 │
│ cy search                                     │ Use the built-in node search function in cyber or pussy                  │
│ cy cid-get-type-gateway                       │ Obtain cid info                                                          │
│ cy cid-read-or-download                       │ Read a CID from the cache, and if the CID is absent - add it into the... │
│ cy cid-download-async                         │ Add a cid into queue to download asynchronously                          │
│ cy cid-download                               │ Download cid immediately and mark it in the queue                        │
│ cy queue-cid-add                              │ Add a CID to the download queue                                          │
│ cy watch-search-folder                        │ Watch the queue folder, and if there are updates, request files to do... │
│ cy queue-cids-download                        │ Check the queue for the new CIDs, and if there are any, safely downlo... │
│ cy cache-clean-cids-queue                     │ remove from queue CIDs with many attempts                                │
│ cy cache-clear                                │ Clear the cache folder                                                   │
│ cy query-current-height                       │ Get a current height for the active network in config                    │
│ cy query-rank-karma                           │ Get a karma metric for a given neuron                                    │
│ cy tokens-balance-get                         │ Get a balance for a given account                                        │
│ cy tokens-supply-get                          │ Get supply of all tokens in a network                                    │
│ cy tokens-ibc-denoms-table                    │ Check IBC denoms                                                         │
│ cy tokens-info-from-registry                  │ Get info about tokens from the on-chain-registry contract                │
│ cy balances                                   │ Check balances for the keys added to the active CLI                      │
│ cy tokens-rewards-withdraw                    │ Withdraw rewards, make stats                                             │
│ cy governance-view-props                      │ info about props current and past                                        │
│ cy set-links-table-name                       │ Set the custom name for links csv table                                  │
│ cy ipfs-bootstrap-add-congress                │ Add the cybercongress node to bootstrap nodes                            │
│ cy validator-generate-persistent-peers-string │ Dump the peers connected to the given node to the comma-separated 'pe... │
│ cy validator-query-delegators                 │ Query all delegators to a specified validator                            │
│ cy query-tx                                   │ Query tx by hash                                                         │
│ cy query-tx-seq                               │ Query tx by acc/seq                                                      │
│ cy query-account                              │ Query account                                                            │
│ cy query-authz-grants-by-granter              │ Query status of authz grants for address                                 │
│ cy query-authz-grants-by-grantee              │ Query status of authz grants for address                                 │
│ cy caching-function                           │ A wrapper, to cache CLI requests                                         │
│ cy qnbn                                       │ query neuron addrsss by his nick                                         │
│ cy update-cy                                  │ Update Cy and Nushell to the latest versions                             │
│ cy help-cy                                    │ An ordered list of cy commands                                           │
│ cy echo_particle_txt                          │ echo particle for publishing                                             │
╰────────────────────command────────────────────┴───────────────────────────────────desc───────────────────────────────────╯

> help-cy | length
84
```

```nushell
> $env.IPFS_PATH = /Users/user/.ipfs_blank

> pin-text 'cyber'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
> pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
> pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F
> pin-text 'linkfilestest/cyber.txt'
QmafiM9MqvpAh4eZJrB7KJ3BAaEqphJGS9EDpLnMePKCPn
> pin-text ([tests linkfilestest cyber.txt] | path join) --follow_file_path
QmSFQ4nwTiQppHg3daTJ7GHFuiFFiu6mNjjeKN54ynTTUx
> pin-text ([linkfilestest cyber.txt] | path join) --follow_file_path
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
> link-texts "cyber" "bostrom"
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯
> link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom"
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯
> link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --ignore_cid
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ bostrom                                        │
│ from      │ QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯
> set-cy-setting ipfs-upload-with-no-confirm 'true'

> link-chain bostrom cyber superintelligence
╭────from_text─────┬─────────to_text──────────┬─────────────────────────from──────────────────────────┬──────────────────────────to──────────────────────────╮
│ bostrom          │ cyber                    │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb        │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV       │
│ cyber            │ superintelligence        │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV        │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M       │
╰────from_text─────┴─────────to_text──────────┴─────────────────────────from──────────────────────────┴──────────────────────────to──────────────────────────╯

> set-links-table-name
temp_20240417-125111
> cd linkfilestest

> link-files --link_filenames --yes --include_extension
╭────from_text─────┬───────────to_text────────────┬────────────────────────from─────────────────────────┬─────────────────────────to─────────────────────────╮
│ bostrom.txt      │ pinned_file:bostrom.txt      │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k      │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb     │
│ cyber.txt        │ pinned_file:cyber.txt        │ QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV     │
╰────from_text─────┴───────────to_text────────────┴────────────────────────from─────────────────────────┴─────────────────────────to─────────────────────────╯

> cd ..

> cd linkfilestest

> link-files --link_filenames --yes --include_extension bostrom.txt
╭────from_text─────┬───────────to_text────────────┬────────────────────────from─────────────────────────┬─────────────────────────to─────────────────────────╮
│ bostrom.txt      │ pinned_file:bostrom.txt      │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k      │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb     │
╰────from_text─────┴───────────to_text────────────┴────────────────────────from─────────────────────────┴─────────────────────────to─────────────────────────╯

> cd ..

> follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │
│ to_text   │ bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 │
│ from      │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │
│ to        │ QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af │
╰───────────┴────────────────────────────────────────────────╯
> follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only

> validator-chooser | length
96
> caching-function query rank karma bostrom1smsn8u0h5tlvt3jazf78nnrv54aspged9h2nl9 | describe
nothing
> config-activate 42gboot+cyber
╭────────────────────┬────────────────────────────────────────────────────────────╮
│ config-name        │ 42gboot+cyber                                              │
│ ipfs-download-from │ gateway                                                    │
│ ipfs-files-folder  │ /Users/user/Documents/local_files/cyber_files/ipfs_objects │
│ path               │ /Users/user/cy                                             │
│ address            │ bostrom166tas63rcdezv35jycr8mlfr0qgjdm7rgpzly5             │
│ chain-id           │ bostrom                                                    │
│ exec               │ cyber                                                      │
│ ipfs-storage       │ cybernode                                                  │
│ passport-nick      │ 42gboot                                                    │
│ rpc-address        │ https://rpc.bostrom.cybernode.ai:443                       │
╰────────────────────┴────────────────────────────────────────────────────────────╯
> caching-function query rank karma bostrom1smsn8u0h5tlvt3jazf78nnrv54aspged9h2nl9 | describe
record<karma: string, update_time: date>
> caching-function query bank balances bostrom1quchyywzdxp62dq3rwan8fg35v6j58sjwnfpuu | describe
record<balances: table<denom: string, amount: string>, pagination: record<next_key: nothing, total: string>, update_time: date>
> caching-function query bank balances bostrom1cj8j6pc3nda8v708j3s4a6gq2jrnue7j857m9t | describe
record<balances: table<denom: string, amount: string>, pagination: record<next_key: nothing, total: string>, update_time: date>
> caching-function query staking delegations bostrom1eg3v42jpwf3d66v6rnrn9hedyd8qvhqy4dt8pc | describe
record<delegation_responses: table<delegation: record<delegator_address: string, validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, pagination: record<next_key: nothing, total: string>, update_time: date>
> caching-function query staking delegations bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | describe
record<delegation_responses: table<delegation: record<delegator_address: string, validator_address: string, shares: string>, balance: record<denom: string, amount: string>>, pagination: record<next_key: nothing, total: string>, update_time: date>
> caching-function query rank top | describe
record<result: table<particle: string, rank: string>, pagination: record<total: int>, update_time: date>
> caching-function query ibc-transfer denom-traces | describe
record<denom_traces: table<path: string, base_denom: string>, pagination: record<next_key: nothing, total: string>, update_time: date>
> caching-function query liquidity pools --cache_validity_duration 0sec | describe
record<pools: table<id: string, type_id: int, reserve_coin_denoms: list<string>, reserve_account_address: string, pool_coin_denom: string>, pagination: record<next_key: nothing, total: string>, update_time: date>
> links-clear

> tweet 'cyber-prophet is cool' --disable_send
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ to_text   │ cyber-prophet is cool                          │
│ from      │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ to        │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │
╰───────────┴────────────────────────────────────────────────╯
> set-links-table-name
temp_20240417-125554
> link-texts 'cyber' 'bostrom'
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯
> [[from_text, to_text]; ['cyber-prophet' '🤘'] ['tweet' 'cy is cool!']]
    | links-append
╭────from_text─────┬────to_text────┬───────────────────────from───────────────────────┬────────────────────────to────────────────────────┬─────timestamp─────╮
│ cyber            │ bostrom       │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV   │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb   │ 20240417-125602   │
│ cyber-prophet    │ 🤘            │                                                  │                                                  │ 20240417-125611   │
│ tweet            │ cy is cool!   │                                                  │                                                  │ 20240417-125611   │
╰────from_text─────┴────to_text────┴───────────────────────from───────────────────────┴────────────────────────to────────────────────────┴─────timestamp─────╯

> links-pin-columns
╭────from_text─────┬────to_text────┬───────────────────────from───────────────────────┬────────────────────────to────────────────────────┬─────timestamp─────╮
│ cyber            │ bostrom       │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV   │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb   │ 20240417-125602   │
│ cyber-prophet    │ 🤘            │ QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD   │ QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow   │ 20240417-125611   │
│ tweet            │ cy is cool!   │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx   │ QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8   │ 20240417-125611   │
╰────from_text─────┴────to_text────┴───────────────────────from───────────────────────┴────────────────────────to────────────────────────┴─────timestamp─────╯

> links-view --no_timestamp
╭───────from_text───────┬──────to_text───────┬─────────────────────────from──────────────────────────┬──────────────────────────to───────────────────────────╮
│ cyber                 │ bostrom            │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb        │
│ cyber-prophet         │ 🤘                 │ QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD        │ QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow        │
│ tweet                 │ cy is cool!        │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx        │ QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8        │
╰───────from_text───────┴──────to_text───────┴─────────────────────────from──────────────────────────┴──────────────────────────to───────────────────────────╯

> links-link-all 'cy testing script'
╭──────from_text──────┬────to_text────┬──────────────────────from───────────────────────┬───────────────────────to────────────────────────┬────timestamp─────╮
│ cy testing script   │ bostrom       │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx  │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb  │ 20240417-125602  │
│ cy testing script   │ 🤘            │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx  │ QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow  │ 20240417-125611  │
│ cy testing script   │ cy is cool!   │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx  │ QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8  │ 20240417-125611  │
╰──────from_text──────┴────to_text────┴──────────────────────from───────────────────────┴───────────────────────to────────────────────────┴────timestamp─────╯

> links-view --no_timestamp
╭────────from_text─────────┬──────to_text──────┬─────────────────────────from─────────────────────────┬──────────────────────────to──────────────────────────╮
│ cy testing script        │ bostrom           │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx       │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb       │
│ cy testing script        │ 🤘                │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx       │ QmQKvsh8pp6qFk31ch6RydBFeEHi82TjsRP8FEPYQ3jDow       │
│ cy testing script        │ cy is cool!       │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx       │ QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8       │
╰────────from_text─────────┴──────to_text──────┴─────────────────────────from─────────────────────────┴──────────────────────────to──────────────────────────╯

> config-activate 42gboot+cyber
╭────────────────────┬────────────────────────────────────────────────────────────╮
│ config-name        │ 42gboot+cyber                                              │
│ ipfs-download-from │ gateway                                                    │
│ ipfs-files-folder  │ /Users/user/Documents/local_files/cyber_files/ipfs_objects │
│ path               │ /Users/user/cy                                             │
│ address            │ bostrom166tas63rcdezv35jycr8mlfr0qgjdm7rgpzly5             │
│ chain-id           │ bostrom                                                    │
│ exec               │ cyber                                                      │
│ ipfs-storage       │ cybernode                                                  │
│ passport-nick      │ 42gboot                                                    │
│ rpc-address        │ https://rpc.bostrom.cybernode.ai:443                       │
╰────────────────────┴────────────────────────────────────────────────────────────╯
> link-random 3

> link-random 3 --source forismatic.com

> links-remove-existed-1by1

> graph-links-df | polars filter-with ((polars col timestamp) > ((date now) - 15day | format date %F)) | polars filter-with ((polars col timestamp) < (date now | format date %F)) | graph-stats | get neurons
59
> graph-links-df | graph-neurons-stats | polars select nick links_count karma karma_norm karma_norm_bar | polars first 2 | polars into-nu | get 0.links_count | $in > 0
true
> graph-links-df test-graph.csv | graph-filter-system-particles particle_from | polars shape | polars into-nu
╭─#─┬─rows─┬─columns─╮
│ 0 │   76 │       5 │
╰─#─┴─rows─┴─columns─╯

> graph-links-df test-graph.csv | graph-filter-system-particles particle_from --exclude | polars shape | polars into-nu
╭─#─┬─rows─┬─columns─╮
│ 0 │ 1205 │       5 │
╰─#─┴─rows─┴─columns─╯

> graph-links-df test-graph.csv
        | graph-filter-system-particles particle_from --exclude
        | graph-merge (graph-links-df test-graph.csv
        | graph-filter-system-particles particle_from)
        | polars group-by source
        | polars agg ((polars col source) | polars count | polars as count)
        | polars collect
        | polars into-nu
        | sort-by count
        | reject index
╭─source─┬─count─╮
│ b      │    76 │
│ a      │  1205 │
╰─source─┴─count─╯

> graph-links-df test-graph.csv
        | graph-filter-system-particles particle_from --exclude
        | graph-merge (graph-links-df test-graph.csv
        | graph-filter-system-particles particle_from)
        | polars group-by source
        | polars agg ((polars col source) | polars count | polars as count)
        | polars collect
        | polars into-nu
        | sort-by count
        | reject index
╭──#──┬──────────────────────neuron──────────────────────┬─────────────────────particle─────────────────────┬──height──┬───────timestamp───────┬──init-role──╮
│ 0   │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k   │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw   │     9029 │ 2021-11-06 03:52:13   │ from        │
│ 1   │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k   │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR   │     9029 │ 2021-11-06 03:52:13   │ to          │
│ 2   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t   │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE   │    12863 │ 2021-11-06 09:59:22   │ from        │
╰──#──┴──────────────────────neuron──────────────────────┴─────────────────────particle─────────────────────┴──height──┴───────timestamp───────┴──init-role──╯
```
