```nushell
> if (ps | where name =~ ipfs | is-empty) {wezterm cli spawn -- /Users/user/.cargo/bin/nu -c "$env.IPFS_PATH = /Users/user/.ipfs_blank; ipfs daemon"}
23

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
/Users/user/cy/temp/ipfs_upload/20240802-141809
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

> cy link-random 3 | to yaml
- from_text: quote
  to_text: |
    text: What separates the winners from the losers is how a person reacts to each new twist of fate.
    author: Donald Trump
    source: https://forismatic.com
  from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
  to: QmRkvVM8vTfE6kESU4pxoMA3DSVWmnBUhGzDbSLTe9ob4N
- from_text: quote
  to_text: |
    text: Our greatness lies not so much in being able to remake the world as being able to remake ourselves.
    author: Mahatma Gandhi
    source: https://forismatic.com
  from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
  to: QmYrQ1gSueMSMGZFDBeYfgzaa7ZxRSP7HBQxr8CNTzaaYu

> cy link-random 3 --source forismatic.com | to yaml
- from_text: quote
  to_text: |
    text: I believe that a simple and unassuming manner of life is best for everyone, best both for the body and the mind.
    author: Albert Einstein
    source: https://forismatic.com
  from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
  to: QmcLQ1fdyfvMeKGHGyEdkpNx7oE67didQ8Jb8qkT1ws4AJ

> cy link-random 3 --source chucknorris.io | to yaml
- from_text: chuck norris
  to_text: |
    text: Chuck Norris uses the dimensional tear in his kitchen as a garbage disposal.
    source: https://chucknorris.io
  from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
  to: QmeHFSg2qZWJaAh1aB4dUv7b9YoDDC5Zg1BPpdxNaEcmSb
- from_text: chuck norris
  to_text: |
    text: The show Survivor had the original premise of putting people on an island with Chuck Norris. There were no survivors, and nobody is brave enough to go to the island to retrieve the footage.
    source: https://chucknorris.io
  from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
  to: QmR3Fa3U34cJkLWRpvQrKGig7ZWE33YrSna19BzLzmfn1F
- from_text: chuck norris
  to_text: |
    text: The eye of Chuck Norris' penis is all seeing, all knowing.
    source: https://chucknorris.io
  from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
  to: QmNmVqnx64Z8fkCB695WWsVLTsvq976n8C12c87cdCS5sx

> cy links-remove-existed-1by1
1 0 2 4 3 7 5 6 8 9 10
4 cyberlinks was/were already created by
bostrom166tas63rcdezv35jycr8mlfr0qgjdm7rgpzly5
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ bostrom                                        │
│ from      │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ to_text   │ cyber                                          │
│ to        │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ superintelligence                              │
│ to        │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                                                              │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                     │
│ to_text   │ text: What separates the winners from the losers is how a person reacts to each new twist of fate. │
│           │ author: Donald Trump                                                                               │
│           │ source: https://forismatic.com                                                                     │
│           │                                                                                                    │
│ to        │ QmRkvVM8vTfE6kESU4pxoMA3DSVWmnBUhGzDbSLTe9ob4N                                                     │
╰───────────┴────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                                                              │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                     │
│ to_text   │ text: What separates the winners from the losers is how a person reacts to each new twist of fate. │
│           │ author: Donald Trump                                                                               │
│           │ source: https://forismatic.com                                                                     │
│           │                                                                                                    │
│ to        │ QmRkvVM8vTfE6kESU4pxoMA3DSVWmnBUhGzDbSLTe9ob4N                                                     │
╰───────────┴────────────────────────────────────────────────────────────────────────────────────────────────────╯
So they were removed from the temp table!

╭─#──┬──from_text───┬───────────────────────────────────────────────────────────────────to_text───────────────────────────────────────────────────────────────────┬─from─┬─to─┬─timestamp─┬link_exist╮
│ 2  │ quote        │ text: Our greatness lies not so much in being able to remake the world as being able to remake ourselves.                                   │ Q... │ .. │ 202408... │ false    │
│    │              │ author: Mahatma Gandhi                                                                                                                      │      │    │           │          │
│    │              │ source: https://forismatic.com                                                                                                              │      │    │           │          │
│    │              │                                                                                                                                             │      │    │           │          │
│ 5  │ quote        │ text: I believe that a simple and unassuming manner of life is best for everyone, best both for the body and the mind.                      │ Q... │ .. │ 202408... │ false    │
│    │              │ author: Albert Einstein                                                                                                                     │      │    │           │          │
│    │              │ source: https://forismatic.com                                                                                                              │      │    │           │          │
│    │              │                                                                                                                                             │      │    │           │          │
│ 6  │ quote        │ text: I believe that a simple and unassuming manner of life is best for everyone, best both for the body and the mind.                      │ Q... │ .. │ 202408... │ false    │
│    │              │ author: Albert Einstein                                                                                                                     │      │    │           │          │
│    │              │ source: https://forismatic.com                                                                                                              │      │    │           │          │
│    │              │                                                                                                                                             │      │    │           │          │
│ 7  │ quote        │ text: I believe that a simple and unassuming manner of life is best for everyone, best both for the body and the mind.                      │ Q... │ .. │ 202408... │ false    │
│    │              │ author: Albert Einstein                                                                                                                     │      │    │           │          │
│    │              │ source: https://forismatic.com                                                                                                              │      │    │           │          │
│    │              │                                                                                                                                             │      │    │           │          │
│ 8  │ chuck norris │ text: The show Survivor had the original premise of putting people on an island with Chuck Norris. There were no survivors, and nobody i... │ Q... │ .. │ 202408... │ false    │
│ 9  │ chuck norris │ text: Chuck Norris uses the dimensional tear in his kitchen as a garbage disposal.                                                          │ Q... │ .. │ 202408... │ false    │
│    │              │ source: https://chucknorris.io                                                                                                              │      │    │           │          │
│    │              │                                                                                                                                             │      │    │           │          │
│ 10 │ chuck norris │ text: The eye of Chuck Norris' penis is all seeing, all knowing.                                                                            │ Q... │ .. │ 202408... │ false    │
│    │              │ source: https://chucknorris.io                                                                                                              │      │    │           │          │
│    │              │                                                                                                                                             │      │    │           │          │
╰─#──┴──from_text───┴───────────────────────────────────────────────────────────────────to_text───────────────────────────────────────────────────────────────────┴─from─┴─to─┴─timestamp─┴─link_exi─╯

> cy links-publish
2 links from initial data were removed, because they were obsolete
╭────────────────────cy────────────────────┬──────────────────────────────txhash──────────────────────────────╮
│ 5 cyberlinks should be successfully sent │ 882E44E14441E7F6B97C81DCDBD2504F274096DE9572DF635AF5ABEDE44AC31A │
╰────────────────────cy────────────────────┴──────────────────────────────txhash──────────────────────────────╯
```
