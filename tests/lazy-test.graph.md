```nushell
> overlay use ~/cy/cy/cy-full.nu --reload
> graph-links-df test-graph.csv | polars collect
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

> graph-links-df test-graph.csv | graph-to-particles | particles-keep-only-first-neuron | polars collect
╭──#──┬───────────────────────────────neuron───────────────────────────────┬────────────────────particle────────────────────┬──height──┬──────timestamp──────┬─init-role─╮
│ 0   │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k                     │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │     9029 │ 2021-11-06 03:52:13 │ to        │
│ 1   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmRkxeB7V537fVc8913TmQwtxwuZBAVsWNedRMDyQ8Df97 │    15287 │ 2021-11-06 13:52:52 │ from      │
│ 2   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │    12863 │ 2021-11-06 09:59:22 │ from      │
│ 3   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmY4X4SkVBkoUGZdTzdcW7SKY8t4ULj5GJBRcRr4UMyahp │    12863 │ 2021-11-06 09:59:22 │ to        │
│ 4   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmRBxwqwNhLUjnsKwm8giYNVv4wwa77XUk51bYoo67tbah │    15287 │ 2021-11-06 13:52:52 │ to        │
│ 5   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmSDCFfY1S2UxoDkhbAtFbnm2vp97eefNyb5NQKpXENwDj │    15303 │ 2021-11-06 13:54:27 │ to        │
│ 6   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ Qmd4suKEMpRKuFkEeGbsHqDAKJfSQdNkkxPie6cfVacm8X │    15315 │ 2021-11-06 13:55:38 │ to        │
│ 7   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmWjcFRoVPeYXWug6NsoWFGA8PWqfFWcJ6G2HFNLf5QyXR │    15340 │ 2021-11-06 13:58:01 │ to        │
│ 8   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmcwgfBG21fQ3sqiQhwnvFmadijd2GYZDF81QyQLXoJtEM │    15379 │ 2021-11-06 14:01:50 │ to        │
│ 9   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmZ2ohGiRRVRpErM2ieLhTSStofUdqszibLYdJinzvk8P2 │    16689 │ 2021-11-06 16:09:05 │ to        │
│ ... │ ...                                                                │ ...                                            │ ...      │ ...                 │ ...       │
│ 972 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmPoomrqMFTTBhsgDWH2pmTArgfvb5XqogXz3qZoGDjbmp │ 12234459 │ 2024-02-19 12:02:32 │ to        │
│ 973 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmfWCTr1JKbyGnSqH7FA39MNwQyvHKQwzPCHBKL3dnjLAR │ 12554140 │ 2024-03-12 10:49:28 │ to        │
│ 974 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ 12570332 │ 2024-03-13 13:27:52 │ to        │
│ 975 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641050 │ 2024-03-18 09:49:09 │ to        │
│ 976 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmSS1GaRdKBdkvxrbQnnW7FrXcVCyZMBcuZsV7qPGWCEBS │ 12641076 │ 2024-03-18 09:51:42 │ from      │
│ 977 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmTto1JaBHqT354oLjqxook2ikN7kanrfmB4eLGXw917AB │ 12641084 │ 2024-03-18 09:52:28 │ from      │
│ 978 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmUvxAbodisXtZDpiKpB9sZbHLhjNMxqWCpEm4doqWk1Cq │ 12641123 │ 2024-03-18 09:56:20 │ to        │
│ 979 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmSozQsP5FXmWYuVGkZMVEdmj3as2WawzkGhJkyw6gGRz9 │ 12667642 │ 2024-03-20 05:16:12 │ to        │
│ 980 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmQ8ntTiVnJxxBQSoeaAnNQR2oHvbpTgHLwWKWxGngZgbm │ 12667658 │ 2024-03-20 05:17:46 │ to        │
│ 981 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmZdKqcYqYGy88QpUGZpqjmDUkwm6gZBhygxtSHbCKzbAV │ 12847309 │ 2024-04-01 13:14:37 │ to        │
╰──#──┴───────────────────────────────neuron───────────────────────────────┴────────────────────particle────────────────────┴──height──┴──────timestamp──────┴─init-role─╯
```
