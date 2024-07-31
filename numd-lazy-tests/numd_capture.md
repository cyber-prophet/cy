```nushell
> overlay use ~/cy/cy -pr
> $env.config.table.abbreviated_row_count = 10000

> cy help-cy
╭────────────────command─────────────────┬────────────────────────────────────desc─────────────────────────────────────╮
│ cy pin-text                            │ Pin a text particle                                                         │
│ cy link-texts                          │ Add a 2-texts cyberlink to the temp table                                   │
│ cy link-chain                          │ Add a link chain to the temp table                                          │
│ cy link-files                          │ Pin files from the current folder to the local node and append their cyb... │
│ cy link-folder                         │ Create cyberlinks to hierarchies (if any) `parent_folder - child_folder`... │
│ cy follow                              │ Create a cyberlink according to `following a neuron` semantic convention    │
│ cy tweet                               │ Add a tweet and send it immediately (unless of `--disable_send`)            │
│ cy link-random                         │ Make a random cyberlink from different APIs (chucknorris.io, forismatic.... │
│ cy links-view                          │ View the temp cyberlinks table                                              │
│ cy links-append                        │ Append piped-in table to the temp cyberlinks table                          │
│ cy links-replace                       │ Replace the temp table with piped-in table                                  │
│ cy links-swap-from-to                  │ Swap columns `from` and `to`                                                │
│ cy links-clear                         │ Empty the temp cyberlinks table                                             │
│ cy links-link-all                      │ Add the same text particle into the 'from' or 'to' column of the temp cy... │
│ cy links-pin-columns                   │ Pin values of 'from_text' and 'to_text' columns to an IPFS node and fill... │
│ cy links-remove-existed-1by1           │ Remove existing in cybergraph cyberlinks from the temp table                │
│ cy links-remove-existed-using-snapshot │ Remove existing links using graph snapshot data                             │
│ cy links-publish                       │ Publish all links from the temp table to cybergraph                         │
│ cy set-links-table-name                │ Set a custom name for the temp links csv table                              │
│ cy config-new                          │ Create a config JSON to set env variables, to use them as parameters in ... │
│ cy config-view                         │ View a saved JSON config file                                               │
│ cy config-save                         │ Save the piped-in JSON into a config file inside of `cy/config` folder      │
│ cy config-activate                     │ Activate the config JSON                                                    │
╰────────────────command─────────────────┴────────────────────────────────────desc─────────────────────────────────────╯

> cy help-cy | length
23
```

```nushell
> $env.IPFS_PATH = /Users/user/.ipfs_blank

> cy pin-text 'cyber'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F

> cy pin-text 'linkfilestest/cyber.txt'
QmafiM9MqvpAh4eZJrB7KJ3BAaEqphJGS9EDpLnMePKCPn

> cy pin-text ([tests linkfilestest cyber.txt] | path join) --follow_file_path
QmSFQ4nwTiQppHg3daTJ7GHFuiFFiu6mNjjeKN54ynTTUx

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
/Users/user/cy/temp/ipfs_upload/20240731-131431
╭from_text┬──────to_text──────┬──────────────────────from──────────────────────┬─────────────────to──────────────────╮
│ bostrom │ cyber             │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6Fv... │
│ cyber   │ superintelligence │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9... │
╰─from_te─┴──────to_text──────┴──────────────────────from──────────────────────┴─────────────────to──────────────────╯

> cy set-links-table-name
temp_20240731-131431

> cd linkfilestest

> cy link-files --link_filenames --yes --include_extension
╭──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬─────────────to──────────────╮
│ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8... │
│ cyber.txt   │ pinned_file:cyber.txt   │ QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6 │ QmRX8qYgeZoYM3M5zzQaWEpV... │
╰──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴─────────────to──────────────╯

> cd ..

> cd linkfilestest

> cy link-files --link_filenames --yes --include_extension bostrom.txt
╭──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬─────────────to──────────────╮
│ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8... │
╰──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴─────────────to──────────────╯

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
temp_20240731-131440

> cy link-texts 'cyber' 'bostrom'
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy links-pin-columns
╭from_text┬─to_text─┬──────────────────────from──────────────────────┬────────────────to─────────────────┬─timestamp─╮
│ cyber   │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSH... │ 202407... │
╰─from_te─┴─to_text─┴──────────────────────from──────────────────────┴────────────────to─────────────────┴─timestamp─╯

> cy links-view --no_timestamp
There are 1 cyberlinks in the temp table:
╭from_text┬─to_text─┬──────────────────────from──────────────────────┬──────────────────────to───────────────────────╮
│ cyber   │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3Rm... │
╰─from_te─┴─to_text─┴──────────────────────from──────────────────────┴──────────────────────to───────────────────────╯

> cy links-link-all 'cy testing script'
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬────────────to─────────────┬─timestamp─╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9b... │ 202407... │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴────────────to─────────────┴─timestamp─╯

> cy links-view --no_timestamp
There are 1 cyberlinks in the temp table:
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬──────────────────to───────────────────╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDC... │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴──────────────────to───────────────────╯

> cy config-activate 42gboot+cyber

> cy link-random 3
╭from_text┬───────────────────────────────────────────to_text────────────────────────────────────────────┬─from─┬─to─╮
│ quote   │ Whatever we expect with confidence becomes our own self-fulfilling prophecy.  (Brian Tracy)  │ Q... │ .. │
│         │                                                                                              │      │    │
│         │ via [forismatic.com](https://forismatic.com)                                                 │      │    │
│ quote   │ No man ever reached to excellence in any one art or profession without having passed thro... │ Q... │ .. │
│ quote   │ Interesting when rain falls somewhere only to recognize that it isn't falling some place ... │ Q... │ .. │
╰─from_te─┴───────────────────────────────────────────to_text────────────────────────────────────────────┴─from─┴─to─╯

> cy link-random 3 --source forismatic.com
╭from_text┬───────────────────────────────────────────to_text────────────────────────────────────────────┬─from─┬─to─╮
│ quote   │ You have power over your mind — not outside events. Realize this, and you will find stren... │ Q... │ .. │
│ quote   │ The world doesn’t happen to you it happens from you.                                         │ Q... │ .. │
│         │                                                                                              │      │    │
│         │ via [forismatic.com](https://forismatic.com)                                                 │      │    │
│ quote   │ We have two ears and one mouth so that we can listen twice as much as we speak.   (Epicte... │ Q... │ .. │
╰─from_te─┴───────────────────────────────────────────to_text────────────────────────────────────────────┴─from─┴─to─╯

> cy links-remove-existed-1by1
0 2 3 1 4 5 6 7 There are no cyberlinks in the temp table for the current address exist the
cybergraph
```
