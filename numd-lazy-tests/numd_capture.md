```nushell
> overlay use ~/cy/cy -pr
> $env.config.table.abbreviated_row_count = 10000

> cy help-cy

> cy help-cy | length
0
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
/Users/user/cy/temp/ipfs_upload/20240627-135001
╭─from_text─┬──────to_text──────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ bostrom   │ cyber             │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ cyber     │ superintelligence │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M │
╰─from_text─┴──────to_text──────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy set-links-table-name
temp_20240627-135002

> cd linkfilestest

> cy link-files --link_filenames --yes --include_extension
╭──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ cyber.txt   │ pinned_file:cyber.txt   │ QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6 │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
╰──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cd ..

> cd linkfilestest

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
temp_20240627-135022

> cy link-texts 'cyber' 'bostrom'
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy links-pin-columns
╭─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────┬────timestamp────╮
│ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ 20240627-135026 │
╰─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────┴────timestamp────╯

> cy links-view --no_timestamp
There are 1 cyberlinks in the temp table:
╭─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-link-all 'cy testing script'
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────┬────timestamp────╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ 20240627-135026 │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────┴────timestamp────╯

> cy links-view --no_timestamp
There are 1 cyberlinks in the temp table:
╭─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy config-activate 42gboot+cyber

> cy link-random 3
===============================================================================
    If you have made mistakes, there is always another chance for you. You may
    have a fresh start any moment you choose. (Mary Pickford)

    via [forismatic.com](https://forismatic.com)
===============================================================================
===============================================================================
    Life is really simple, but we insist on making it complicated.   (Confucius
    )

    via [forismatic.com](https://forismatic.com)
===============================================================================
===============================================================================
    I cannot give you the formula for success, but I can give you the formula
    for failure: which is: Try to please everybody.  (Herbert Swope)

    via [forismatic.com](https://forismatic.com)
===============================================================================

> cy link-random 3 --source forismatic.com
===============================================================================
    Go put your creed into the deed. Nor speak with double tongue.  (Ralph
    Emerson)

    via [forismatic.com](https://forismatic.com)
===============================================================================
===============================================================================
    To be fully alive, fully human, and completely awake is to be continually
    thrown out of the nest. (Pema Chodron)

    via [forismatic.com](https://forismatic.com)
===============================================================================
===============================================================================
    There is never enough time to do everything, but there is always enough time
    to do the most important thing.  (Brian Tracy)

    via [forismatic.com](https://forismatic.com)
===============================================================================

> cy links-remove-existed-1by1
0
2
1
5
3
4
6
2 cyberlinks was/were already created by
bostrom166tas63rcdezv35jycr8mlfr0qgjdm7rgpzly5
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ from      │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ to_text   │ cyber-prophet is cool                          │
│ to        │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ from_text │ quote                                                                                                            │
│ from      │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna                                                                   │
│ to_text   │ To be fully alive, fully human, and completely awake is to be continually thrown out of the nest. (Pema Chodron) │
│           │                                                                                                                  │
│           │ via [forismatic.com](https://forismatic.com)                                                                     │
│ to        │ QmTVP2xANLC8dRC51uiyFPyGgqtbhY9mMUNwSzL6EDrp2s                                                                   │
╰───────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
So they were removed from the temp table!

╭─#─┬─from_text─┬──────────────────────────────────────────────────to_text──────────────────────────────────────────────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────┬────timestamp────┬─link_exist─╮
│ 1 │ quote     │ If you have made mistakes, there is always another chance for you. You may have a fresh start any mome... │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmT9garztvRBa34Fm8npoKTbZZoSrss95DpYKK71BvLL7s │ 20240627-135044 │ false      │
│ 2 │ quote     │ Life is really simple, but we insist on making it complicated.   (Confucius )                             │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmZpsangk85egnB4iedo1xgbAZu3CUAazU5FVuvnBiG3cr │ 20240627-135103 │ false      │
│   │           │                                                                                                           │                                                │                                                │                 │            │
│   │           │ via [forismatic.com](https://forismatic.com)                                                              │                                                │                                                │                 │            │
│ 3 │ quote     │ I cannot give you the formula for success, but I can give you the formula for failure: which is: Try t... │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ Qmb4Po9pBdD1tVZCAn5W9ZZZwSsti9LpFh1C52CP7mpRbC │ 20240627-135129 │ false      │
│ 4 │ quote     │ Go put your creed into the deed. Nor speak with double tongue.  (Ralph Emerson)                           │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmV5ubhQasCQpsBNFKGgGGQyaoAeqvVSBdHPetcEgbtgYR │ 20240627-135141 │ false      │
│   │           │                                                                                                           │                                                │                                                │                 │            │
│   │           │ via [forismatic.com](https://forismatic.com)                                                              │                                                │                                                │                 │            │
│ 6 │ quote     │ There is never enough time to do everything, but there is always enough time to do the most important ... │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmamGiE4qcyY27unvNtCT2iCCY2YWvckmfMBg2g9fhrJqP │ 20240627-135226 │ false      │
╰─#─┴─from_text─┴──────────────────────────────────────────────────to_text──────────────────────────────────────────────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────┴────timestamp────┴─link_exist─╯

> cy graph-links-df | polars filter-with ((polars col timestamp) > ((date now) - 15day | format date %F)) | polars filter-with ((polars col timestamp) < (date now | format date %F)) | graph-stats | get neurons
34

> cy graph-links-df | graph-neurons-stats | polars select nick links_count karma karma_norm karma_norm_bar | polars first 2 | polars into-nu | get 0.links_count | $in > 0
true

> cy graph-links-df test-graph.csv | graph-filter-system-particles particle_from | polars shape | polars into-nu
╭─rows─┬─columns─╮
│   76 │       5 │
╰─rows─┴─columns─╯

> cy graph-links-df test-graph.csv | graph-filter-system-particles particle_from --exclude | polars shape | polars into-nu
╭─rows─┬─columns─╮
│ 1205 │       5 │
╰─rows─┴─columns─╯

> cy graph-links-df test-graph.csv
╭──#───┬─────────────────────neuron─────────────────────┬─────────────────particle_from──────────────────┬──────────────────particle_to───────────────────┬──height──┬──────timestamp──────╮
│ 0    │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │     9029 │ 2021-11-06 03:52:13 │
│ 1    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │ QmY4X4SkVBkoUGZdTzdcW7SKY8t4ULj5GJBRcRr4UMyahp │    12863 │ 2021-11-06 09:59:22 │
│ 2    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmY4X4SkVBkoUGZdTzdcW7SKY8t4ULj5GJBRcRr4UMyahp │    12869 │ 2021-11-06 09:59:57 │
│ 3    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmRBxwqwNhLUjnsKwm8giYNVv4wwa77XUk51bYoo67tbah │    15287 │ 2021-11-06 13:52:52 │
│ 4    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmSDCFfY1S2UxoDkhbAtFbnm2vp97eefNyb5NQKpXENwDj │    15303 │ 2021-11-06 13:54:27 │
│ 5    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ Qmd4suKEMpRKuFkEeGbsHqDAKJfSQdNkkxPie6cfVacm8X │    15315 │ 2021-11-06 13:55:38 │
│ 6    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmWjcFRoVPeYXWug6NsoWFGA8PWqfFWcJ6G2HFNLf5QyXR │    15340 │ 2021-11-06 13:58:01 │
│ 7    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmWjcFRoVPeYXWug6NsoWFGA8PWqfFWcJ6G2HFNLf5QyXR │    15343 │ 2021-11-06 13:58:19 │
│ 8    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmcwgfBG21fQ3sqiQhwnvFmadijd2GYZDF81QyQLXoJtEM │    15379 │ 2021-11-06 14:01:50 │
│ 9    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmcwgfBG21fQ3sqiQhwnvFmadijd2GYZDF81QyQLXoJtEM │    15400 │ 2021-11-06 14:03:50 │
│ ...  │ ...                                            │ ...                                            │ ...                                            │ ...      │ ...                 │
│ 1271 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ 12570332 │ 2024-03-13 13:27:52 │
│ 1272 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ QmeQDBrFavhzKY6zVXPfoRKJgnbGSpjSH7fe7PdkuohfXw │ 12596377 │ 2024-03-15 08:15:50 │
│ 1273 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641050 │ 2024-03-18 09:49:09 │
│ 1274 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSS1GaRdKBdkvxrbQnnW7FrXcVCyZMBcuZsV7qPGWCEBS │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641076 │ 2024-03-18 09:51:42 │
│ 1275 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmTto1JaBHqT354oLjqxook2ikN7kanrfmB4eLGXw917AB │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │ 12641084 │ 2024-03-18 09:52:28 │
│ 1276 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │ Qme1RyD7Jtxg8LyUKcFLURoZXJvNTuK2sh3VbbsPDvRDsq │ 12641093 │ 2024-03-18 09:53:21 │
│ 1277 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPjz7yuUboFSV95yJXzUG8BDXK66bEBmDEbrcBqgafWqb │ QmUvxAbodisXtZDpiKpB9sZbHLhjNMxqWCpEm4doqWk1Cq │ 12641123 │ 2024-03-18 09:56:20 │
│ 1278 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmSozQsP5FXmWYuVGkZMVEdmj3as2WawzkGhJkyw6gGRz9 │ 12667642 │ 2024-03-20 05:16:12 │
│ 1279 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmQ8ntTiVnJxxBQSoeaAnNQR2oHvbpTgHLwWKWxGngZgbm │ 12667658 │ 2024-03-20 05:17:46 │
│ 1280 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmZdKqcYqYGy88QpUGZpqjmDUkwm6gZBhygxtSHbCKzbAV │ 12847309 │ 2024-04-01 13:14:37 │
╰──#───┴─────────────────────neuron─────────────────────┴─────────────────particle_from──────────────────┴──────────────────particle_to───────────────────┴──height──┴──────timestamp──────╯

> cy graph-links-df test-graph.csv
╭──#───┬─────────────────────neuron─────────────────────┬─────────────────particle_from──────────────────┬──────────────────particle_to───────────────────┬──height──┬──────timestamp──────╮
│ 0    │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │     9029 │ 2021-11-06 03:52:13 │
│ 1    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │ QmY4X4SkVBkoUGZdTzdcW7SKY8t4ULj5GJBRcRr4UMyahp │    12863 │ 2021-11-06 09:59:22 │
│ 2    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmY4X4SkVBkoUGZdTzdcW7SKY8t4ULj5GJBRcRr4UMyahp │    12869 │ 2021-11-06 09:59:57 │
│ 3    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmRBxwqwNhLUjnsKwm8giYNVv4wwa77XUk51bYoo67tbah │    15287 │ 2021-11-06 13:52:52 │
│ 4    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmSDCFfY1S2UxoDkhbAtFbnm2vp97eefNyb5NQKpXENwDj │    15303 │ 2021-11-06 13:54:27 │
│ 5    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ Qmd4suKEMpRKuFkEeGbsHqDAKJfSQdNkkxPie6cfVacm8X │    15315 │ 2021-11-06 13:55:38 │
│ 6    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmWjcFRoVPeYXWug6NsoWFGA8PWqfFWcJ6G2HFNLf5QyXR │    15340 │ 2021-11-06 13:58:01 │
│ 7    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmWjcFRoVPeYXWug6NsoWFGA8PWqfFWcJ6G2HFNLf5QyXR │    15343 │ 2021-11-06 13:58:19 │
│ 8    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │ QmcwgfBG21fQ3sqiQhwnvFmadijd2GYZDF81QyQLXoJtEM │    15379 │ 2021-11-06 14:01:50 │
│ 9    │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmcwgfBG21fQ3sqiQhwnvFmadijd2GYZDF81QyQLXoJtEM │    15400 │ 2021-11-06 14:03:50 │
│ ...  │ ...                                            │ ...                                            │ ...                                            │ ...      │ ...                 │
│ 1271 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ 12570332 │ 2024-03-13 13:27:52 │
│ 1272 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ QmeQDBrFavhzKY6zVXPfoRKJgnbGSpjSH7fe7PdkuohfXw │ 12596377 │ 2024-03-15 08:15:50 │
│ 1273 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641050 │ 2024-03-18 09:49:09 │
│ 1274 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSS1GaRdKBdkvxrbQnnW7FrXcVCyZMBcuZsV7qPGWCEBS │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641076 │ 2024-03-18 09:51:42 │
│ 1275 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmTto1JaBHqT354oLjqxook2ikN7kanrfmB4eLGXw917AB │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │ 12641084 │ 2024-03-18 09:52:28 │
│ 1276 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │ Qme1RyD7Jtxg8LyUKcFLURoZXJvNTuK2sh3VbbsPDvRDsq │ 12641093 │ 2024-03-18 09:53:21 │
│ 1277 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPjz7yuUboFSV95yJXzUG8BDXK66bEBmDEbrcBqgafWqb │ QmUvxAbodisXtZDpiKpB9sZbHLhjNMxqWCpEm4doqWk1Cq │ 12641123 │ 2024-03-18 09:56:20 │
│ 1278 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmSozQsP5FXmWYuVGkZMVEdmj3as2WawzkGhJkyw6gGRz9 │ 12667642 │ 2024-03-20 05:16:12 │
│ 1279 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmQ8ntTiVnJxxBQSoeaAnNQR2oHvbpTgHLwWKWxGngZgbm │ 12667658 │ 2024-03-20 05:17:46 │
│ 1280 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmZdKqcYqYGy88QpUGZpqjmDUkwm6gZBhygxtSHbCKzbAV │ 12847309 │ 2024-04-01 13:14:37 │
╰──#───┴─────────────────────neuron─────────────────────┴─────────────────particle_from──────────────────┴──────────────────particle_to───────────────────┴──height──┴──────timestamp──────╯
```
