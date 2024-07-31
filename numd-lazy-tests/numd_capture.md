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
/Users/user/cy/temp/ipfs_upload/20240731-131655
╭─from_text─┬──────to_text──────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ bostrom   │ cyber             │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ cyber     │ superintelligence │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M │
╰─from_text─┴──────to_text──────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy set-links-table-name
temp_20240731-131655

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

> cy set-links-table-name
temp_20240731-131702

> {from_text: 'cyber' to_text: 'bostrom'} | cy links-replace
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy links-pin-columns | reject timestamp
╭─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────┬────timestamp────╮
│ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ 20240731-131705 │
╰─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────┴────timestamp────╯

> cy links-view | reject timestamp
There are 1 cyberlinks in the temp table:
╭─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-link-all 'cy testing script'
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────┬────timestamp────╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ 20240731-131705 │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────┴────timestamp────╯

> cy links-view | reject timestamp
There are 1 cyberlinks in the temp table:
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy config-activate 42gboot+cyber

> cy link-random 3
╭from_text┬──────────────────────────────────────────────────────────────────to_text───────────────────────────────────────────────────────────────────┬──────────────────from──────────────────┬─to─╮
│ quote   │ Love is the only force capable of transforming an enemy into friend.  (Martin Luther King, Jr.)                                            │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2... │ .. │
│         │                                                                                                                                            │                                        │    │
│         │ via [forismatic.com](https://forismatic.com)                                                                                               │                                        │    │
│ quote   │ If you are patient in one moment of anger, you will escape one hundred days of sorrow. (Chinese Proverb)                                   │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2... │ .. │
│         │                                                                                                                                            │                                        │    │
│         │ via [forismatic.com](https://forismatic.com)                                                                                               │                                        │    │
│ quote   │ There are two primary choices in life: to accept conditions as they exist, or accept the responsibility for changing them. (Denis Waitley) │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2... │ .. │
│         │                                                                                                                                            │                                        │    │
│         │ via [forismatic.com](https://forismatic.com)                                                                                               │                                        │    │
╰─from_te─┴──────────────────────────────────────────────────────────────────to_text───────────────────────────────────────────────────────────────────┴──────────────────from──────────────────┴─to─╯

> cy link-random 3 --source forismatic.com
╭from_text┬───────────────────────────────────────────────────────────────────────────────────to_text────────────────────────────────────────────────────────────────────────────────────┬─from─┬─to─╮
│ quote   │ Translation is the paradigm, the exemplar of all writing. It is translation that demonstrates most vividly the yearning for transformation that underlies every act invol... │ Q... │ .. │
│ quote   │ Our distrust is very expensive.  (Ralph Emerson)                                                                                                                             │ Q... │ .. │
│         │                                                                                                                                                                              │      │    │
│         │ via [forismatic.com](https://forismatic.com)                                                                                                                                 │      │    │
│ quote   │ Treat a man as he is, he will remain so. Treat a man the way he can be and ought to be, and he will become as he can be and should be.  (Johann Wolfgang von Goethe)         │ Q... │ .. │
│         │                                                                                                                                                                              │      │    │
│         │ via [forismatic.com](https://forismatic.com)                                                                                                                                 │      │    │
╰─from_te─┴───────────────────────────────────────────────────────────────────────────────────to_text────────────────────────────────────────────────────────────────────────────────────┴─from─┴─to─╯

> cy links-remove-existed-1by1
1 0 2 3 4 5 6 7 4 cyberlinks was/were already created by
bostrom166tas63rcdezv35jycr8mlfr0qgjdm7rgpzly5
╭───────────┬─────────────────────────────────────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                                                           │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                  │
│ to_text   │ Love is the only force capable of transforming an enemy into friend.  (Martin Luther King, Jr.) │
│           │                                                                                                 │
│           │ via [forismatic.com](https://forismatic.com)                                                    │
│ to        │ QmeQYGEi7hayBzwPgWBJwxT6cLvGGrNbUuev6EoMg9WGjc                                                  │
╰───────────┴─────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                                                                    │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                           │
│ to_text   │ If you are patient in one moment of anger, you will escape one hundred days of sorrow. (Chinese Proverb) │
│           │                                                                                                          │
│           │ via [forismatic.com](https://forismatic.com)                                                             │
│ to        │ QmTP64E4EctdvqxLYLDwQkn7dqKBBMRAw7qXN3EsM1ndRf                                                           │
╰───────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                                                                    │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                           │
│ to_text   │ There are two primary choices in life: to accept conditions as they exist, or accept the responsibili... │
│ to        │ Qmdi2DZky2uxxPV6ev7n42NHTd2bBiP5yoYNKPTc2pNcug                                                           │
╰───────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                                                                    │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                           │
│ to_text   │ Translation is the paradigm, the exemplar of all writing. It is translation that demonstrates most vi... │
│ to        │ QmRWhfJzURpHVjGXvu1eK11m1NaZ1fnS8TREj7vT7asxeK                                                           │
╰───────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────╯
So they were removed from the temp table!

╭─#─┬from_text┬─────────────────────────────────────────────────────────────────────to_text─────────────────────────────────────────────────────────────────────┬─from─┬─to─┬─timestamp─┬link_exist╮
│ 0 │ bostrom │ cyber                                                                                                                                           │ Q... │ .. │           │ false    │
│ 1 │ cyber   │ superintelligence                                                                                                                               │ Q... │ .. │           │ false    │
│ 6 │ quote   │ Our distrust is very expensive.  (Ralph Emerson)                                                                                                │ Q... │ .. │ 202407... │ false    │
│   │         │                                                                                                                                                 │      │    │           │          │
│   │         │ via [forismatic.com](https://forismatic.com)                                                                                                    │      │    │           │          │
│ 7 │ quote   │ Treat a man as he is, he will remain so. Treat a man the way he can be and ought to be, and he will become as he can be and should be.  (Joh... │ Q... │ .. │ 202407... │ false    │
╰─#─┴─from_te─┴─────────────────────────────────────────────────────────────────────to_text─────────────────────────────────────────────────────────────────────┴─from─┴─to─┴─timestamp─┴─link_exi─╯
```
