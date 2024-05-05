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
│ cy dict-neurons-tags                          │ Output dict-neurons tags                                                  │
│ cy doctor                                     │ Fix some problems of cy (for example caused by updates)                  │
│ cy dict-neurons-update                        │ Update neurons YAML-dictionary                                           │
│ cy graph-download-snapshot                    │ Download a snapshot of cybergraph                                        │
│ cy graph-receive-new-links                    │ Download the latest cyberlinks from a hasura cybernode endpoint          │
│ cy graph-download-missing-particles           │ download particles missing from local cache for followed neurons or t... │
│ cy graph-filter-system-particles              │ filter system particles out                                              │
│ cy graph-merge                                │ merge two graphs together, add the `source` column                       │
│ cy graph-to-particles                         │ Output unique list of particles from piped in cyberlinks table           │
│ cy particles-keep-only-first-neuron           │ In the piped in particles df leave only particles appeared for the fi... │
│ cy graph-update-particles-parquet             │ Update the 'particles.parquet' file (it includes content of text files)  │
│ cy graph-filter-neurons                       │ Filter the graph to chosen neurons only                                  │
│ cy graph-filter-contracts                     │ Filter the graph to keep or exclude links from contracts                 │
│ cy graph-append-related                       │ Append related cyberlinks to the piped in graph                          │
│ cy graph-neurons-stats                        │ Output neurons stats based on piped in or the whole graph                │
│ cy graph-stats                                │ Output graph stats based on piped in or the whole graph                  │
│ cy graph-to-gephi                             │ Export a graph into CSV file for import to Gephi                         │
│ cy graph-to-logseq                            │ Logseq export WIP                                                        │
│ cy graph-to-txt-feed                          │ Output particles into txt formatted feed                                  │
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

