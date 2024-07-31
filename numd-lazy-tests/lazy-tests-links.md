```nushell
> overlay use ~/cy/cy -pr
> $env.config.table.abbreviated_row_count = 10000

> cy help-cy
╭────────────────command─────────────────┬────────────────────────────────────────────────────────desc─────────────────────────────────────────────────────────╮
│ cy pin-text                            │ Pin a text particle                                                                                                 │
│ cy link-texts                          │ Add a 2-texts cyberlink to the temp table                                                                           │
│ cy link-chain                          │ Add a link chain to the temp table                                                                                  │
│ cy link-files                          │ Pin files from the current folder to the local node and append their cyberlinks to the temp table                   │
│ cy link-folder                         │ Create cyberlinks to hierarchies (if any) `parent_folder - child_folder`, `folder - filename`, `filename - content` │
│ cy follow                              │ Create a cyberlink according to `following a neuron` semantic convention                                            │
│ cy tweet                               │ Add a tweet and send it immediately (unless of `--disable_send`)                                                    │
│ cy link-random                         │ Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)                                        │
│ cy links-view                          │ View the temp cyberlinks table                                                                                      │
│ cy links-append                        │ Append piped-in table to the temp cyberlinks table                                                                  │
│ cy links-replace                       │ Replace the temp table with piped-in table                                                                          │
│ cy links-swap-from-to                  │ Swap columns `from` and `to`                                                                                        │
│ cy links-clear                         │ Empty the temp cyberlinks table                                                                                     │
│ cy links-link-all                      │ Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table                              │
│ cy links-pin-columns                   │ Pin values of 'from_text' and 'to_text' columns to an IPFS node and fill `from` and `to` with their CIDs            │
│ cy links-remove-existed-1by1           │ Remove existing in cybergraph cyberlinks from the temp table                                                        │
│ cy links-remove-existed-using-snapshot │ Remove existing links using graph snapshot data                                                                     │
│ cy links-publish                       │ Publish all links from the temp table to cybergraph                                                                 │
│ cy set-links-table-name                │ Set a custom name for the temp links csv table                                                                      │
│ cy config-new                          │ Create a config JSON to set env variables, to use them as parameters in cyber cli                                   │
│ cy config-view                         │ View a saved JSON config file                                                                                       │
│ cy config-save                         │ Save the piped-in JSON into a config file inside of `cy/config` folder                                              │
│ cy config-activate                     │ Activate the config JSON                                                                                            │
╰────────────────command─────────────────┴────────────────────────────────────────────────────────desc─────────────────────────────────────────────────────────╯

> cy help-cy | length
23

> $env.IPFS_PATH = /Users/user/.ipfs_blank

> cy pin-text 'cyber'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F

> cy pin-text 'linkfilestest/cyber.txt'
QmafiM9MqvpAh4eZJrB7KJ3BAaEqphJGS9EDpLnMePKCPn

> cy pin-text ([linkfilestest cyber.txt] | path join) --follow_file_path
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy link-texts "cyber" "bostrom"
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom"
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --ignore_cid
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ bostrom                                        │
│ from      │ QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy set-cy-setting ipfs-upload-with-no-confirm 'true'

> cy link-chain bostrom cyber superintelligence
temp files saved to a local directory
/Users/user/cy/temp/ipfs_upload/20240731-141837
╭─from_text─┬──────to_text──────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ bostrom   │ cyber             │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ cyber     │ superintelligence │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M │
╰─from_text─┴──────to_text──────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy set-links-table-name lazy-tests-links-1

> cd linkfilestest

> cy link-files --link_filenames --yes --include_extension
╭──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ cyber.txt   │ pinned_file:cyber.txt   │ QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6 │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
╰──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy link-files --link_filenames --yes --include_extension bostrom.txt
╭──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cd ..

> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │
│ to_text   │ bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 │
│ from      │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │
│ to        │ QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af │
╰───────────┴────────────────────────────────────────────────╯

> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only

> cy links-clear

> cy tweet 'cyber-prophet is cool' --disable_send
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ to_text   │ cyber-prophet is cool                          │
│ from      │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ to        │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │
╰───────────┴────────────────────────────────────────────────╯

> cy set-links-table-name lazy-tests-links-2

> [{from_text: 'cyber' to_text: 'bostrom'}] | cy links-replace
╭─from_text─┬─to_text─╮
│ cyber     │ bostrom │
╰─from_text─┴─to_text─╯

> cy links-pin-columns | reject timestamp -i
╭─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-view | reject timestamp -i
There are 1 cyberlinks in the temp table:
╭─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-link-all 'cy testing script'
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-view | reject timestamp -i
There are 1 cyberlinks in the temp table:
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy config-activate 42gboot+cyber

> cy link-random 3
╭─from_text─┬────────────────────────────────────────to_text────────────────────────────────────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ quote     │ Don't miss all the beautiful colors of the rainbow looking for that pot of gold.      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ Qmbh3TKPhfZQjEuLyFKdHKYCsLb46SSuzTSH7co6FLrt64 │
│           │                                                                                       │                                                │                                                │
│           │ via [forismatic.com](https://forismatic.com)                                          │                                                │                                                │
│ quote     │ The personal life deeply lived always expands into truths beyond itself.  (Anais Nin) │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmTeRvZivV9nLiVL2vkH9jJL6d55eMY7LPVDGXJ8HB69g1 │
│           │                                                                                       │                                                │                                                │
│           │ via [forismatic.com](https://forismatic.com)                                          │                                                │                                                │
│ quote     │ The way is not in the sky. The way is in the heart.   (Buddha)                        │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmW6qzdTVfhJrLC5YZSiQRuh1fDuXvmLGyZgGJ4Yax75uo │
│           │                                                                                       │                                                │                                                │
│           │ via [forismatic.com](https://forismatic.com)                                          │                                                │                                                │
╰─from_text─┴────────────────────────────────────────to_text────────────────────────────────────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy link-random 3 --source forismatic.com
╭from_text┬───────────────────────────────────────────────────────────to_text───────────────────────────────────────────────────────────┬──────────────────────from──────────────────────┬────to─────╮
│ quote   │ Snowflakes are one of natures most fragile things, but just look what they can do when they stick together.  (Vista Kelly ) │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmSL95... │
│         │                                                                                                                             │                                                │           │
│         │ via [forismatic.com](https://forismatic.com)                                                                                │                                                │           │
│ quote   │ A gem cannot be polished without friction, nor a man perfected without trials.  (Chinese Proverb)                           │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmaR1W... │
│         │                                                                                                                             │                                                │           │
│         │ via [forismatic.com](https://forismatic.com)                                                                                │                                                │           │
│ quote   │ Know, first, who you are, and then adorn yourself accordingly.   (Epictetus )                                               │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmQPuF... │
│         │                                                                                                                             │                                                │           │
│         │ via [forismatic.com](https://forismatic.com)                                                                                │                                                │           │
╰─from_te─┴───────────────────────────────────────────────────────────to_text───────────────────────────────────────────────────────────┴──────────────────────from──────────────────────┴────to─────╯

> cy links-remove-existed-1by1 | enumerate | table -e
0 1 2 3 4 5 6 7
1 cyberlinks was/were already created by
bostrom166tas63rcdezv35jycr8mlfr0qgjdm7rgpzly5
╭───────────┬────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                          │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                 │
│ to_text   │ The way is not in the sky. The way is in the heart.   (Buddha) │
│           │                                                                │
│           │ via [forismatic.com](https://forismatic.com)                   │
│ to        │ QmW6qzdTVfhJrLC5YZSiQRuh1fDuXvmLGyZgGJ4Yax75uo                 │
╰───────────┴────────────────────────────────────────────────────────────────╯
So they were removed from the temp table!

╭─#─┬─────────────────────────────────────────────────────────────────────item─────────────────────────────────────────────────────────────────────╮
│ 0 │ ╭────────────┬────────────────────────────────────────────────╮                                                                              │
│   │ │ from_text  │ bostrom                                        │                                                                              │
│   │ │ to_text    │ cyber                                          │                                                                              │
│   │ │ from       │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │                                                                              │
│   │ │ to         │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │                                                                              │
│   │ │ timestamp  │                                                │                                                                              │
│   │ │ index      │ 0                                              │                                                                              │
│   │ │ link_exist │ false                                          │                                                                              │
│   │ ╰────────────┴────────────────────────────────────────────────╯                                                                              │
│ 1 │ ╭────────────┬────────────────────────────────────────────────╮                                                                              │
│   │ │ from_text  │ cyber                                          │                                                                              │
│   │ │ to_text    │ superintelligence                              │                                                                              │
│   │ │ from       │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │                                                                              │
│   │ │ to         │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M │                                                                              │
│   │ │ timestamp  │                                                │                                                                              │
│   │ │ index      │ 1                                              │                                                                              │
│   │ │ link_exist │ false                                          │                                                                              │
│   │ ╰────────────┴────────────────────────────────────────────────╯                                                                              │
│ 2 │ ╭────────────┬──────────────────────────────────────────────────────────────────────────────────╮                                            │
│   │ │ from_text  │ quote                                                                            │                                            │
│   │ │ to_text    │ Don't miss all the beautiful colors of the rainbow looking for that pot of gold. │                                            │
│   │ │            │                                                                                  │                                            │
│   │ │            │ via [forismatic.com](https://forismatic.com)                                     │                                            │
│   │ │ from       │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                   │                                            │
│   │ │ to         │ Qmbh3TKPhfZQjEuLyFKdHKYCsLb46SSuzTSH7co6FLrt64                                   │                                            │
│   │ │ timestamp  │ 20240731-141854                                                                  │                                            │
│   │ │ index      │ 2                                                                                │                                            │
│   │ │ link_exist │ false                                                                            │                                            │
│   │ ╰────────────┴──────────────────────────────────────────────────────────────────────────────────╯                                            │
│ 3 │ ╭────────────┬───────────────────────────────────────────────────────────────────────────────────────╮                                       │
│   │ │ from_text  │ quote                                                                                 │                                       │
│   │ │ to_text    │ The personal life deeply lived always expands into truths beyond itself.  (Anais Nin) │                                       │
│   │ │            │                                                                                       │                                       │
│   │ │            │ via [forismatic.com](https://forismatic.com)                                          │                                       │
│   │ │ from       │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                        │                                       │
│   │ │ to         │ QmTeRvZivV9nLiVL2vkH9jJL6d55eMY7LPVDGXJ8HB69g1                                        │                                       │
│   │ │ timestamp  │ 20240731-141858                                                                       │                                       │
│   │ │ index      │ 3                                                                                     │                                       │
│   │ │ link_exist │ false                                                                                 │                                       │
│   │ ╰────────────┴───────────────────────────────────────────────────────────────────────────────────────╯                                       │
│ 4 │ ╭────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮ │
│   │ │ from_text  │ quote                                                                                                                       │ │
│   │ │ to_text    │ Snowflakes are one of natures most fragile things, but just look what they can do when they stick together.  (Vista Kelly ) │ │
│   │ │            │                                                                                                                             │ │
│   │ │            │ via [forismatic.com](https://forismatic.com)                                                                                │ │
│   │ │ from       │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                                              │ │
│   │ │ to         │ QmSL95FVCKD1LwtmJobUM5DCiFSyJApbTSfVRagyEA9dLu                                                                              │ │
│   │ │ timestamp  │ 20240731-141906                                                                                                             │ │
│   │ │ index      │ 5                                                                                                                           │ │
│   │ │ link_exist │ false                                                                                                                       │ │
│   │ ╰────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯ │
│ 5 │ ╭────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────╮                           │
│   │ │ from_text  │ quote                                                                                             │                           │
│   │ │ to_text    │ A gem cannot be polished without friction, nor a man perfected without trials.  (Chinese Proverb) │                           │
│   │ │            │                                                                                                   │                           │
│   │ │            │ via [forismatic.com](https://forismatic.com)                                                      │                           │
│   │ │ from       │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                    │                           │
│   │ │ to         │ QmaR1Wuxqxf9gQyUNQkLdxWb3HqAAHhmp9LZ6M4FSax3jw                                                    │                           │
│   │ │ timestamp  │ 20240731-141909                                                                                   │                           │
│   │ │ index      │ 6                                                                                                 │                           │
│   │ │ link_exist │ false                                                                                             │                           │
│   │ ╰────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────╯                           │
│ 6 │ ╭────────────┬───────────────────────────────────────────────────────────────────────────────╮                                               │
│   │ │ from_text  │ quote                                                                         │                                               │
│   │ │ to_text    │ Know, first, who you are, and then adorn yourself accordingly.   (Epictetus ) │                                               │
│   │ │            │                                                                               │                                               │
│   │ │            │ via [forismatic.com](https://forismatic.com)                                  │                                               │
│   │ │ from       │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                │                                               │
│   │ │ to         │ QmQPuFt8sDcLHXy8zcYsXtwxZV1dTHWERqDJcSU4aXVeYh                                │                                               │
│   │ │ timestamp  │ 20240731-141913                                                               │                                               │
│   │ │ index      │ 7                                                                             │                                               │
│   │ │ link_exist │ false                                                                         │                                               │
│   │ ╰────────────┴───────────────────────────────────────────────────────────────────────────────╯                                               │
╰─#─┴─────────────────────────────────────────────────────────────────────item─────────────────────────────────────────────────────────────────────╯
```
