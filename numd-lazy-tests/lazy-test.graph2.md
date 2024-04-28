```nushell
> graph-links-df test-graph.csv | graph-filter-neurons maxim@n6r76m8
╭──#───┬─────────────────────neuron─────────────────────┬─────────────────particle_from──────────────────┬──────────────────particle_to───────────────────┬──height──┬──────timestamp──────╮
│ 0    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmaxuSoSUkgKBGBJkT2Ypk9zWdXor89JEmaeEB66wZUHYo │    87794 │ 2021-11-11 10:36:24 │
│ 1    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs │ QmYnLm5MFGFwcoXo65XpUyCEKX4yV7HbCAZiDZR95aKr4t │    88371 │ 2021-11-11 11:31:54 │
│ 2    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmST3fBarm3M783FpwhsqBcsTjm24Pdxai626XhjZrFDsN │ QmRCcwFq9JjYEGCE22CTWfP7SiLxkJJycykoAujuKmBk1F │    88449 │ 2021-11-11 11:39:25 │
│ 3    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmTbiVj2kq4nqAaQH6zym5E9jABN6FwbGs8h5MSu2PdHvr │ Qmdo6FeBhcu1rW3bC2eu62g9sQifgAZu1wBh47UKgnTdbN │   115916 │ 2021-11-13 08:04:59 │
│ 4    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmS6mcrMTFsZnT3wAptqEb8NpBPnv1H6WwZBMzEjT8SSDv │ QmSMFYqexjmnkUNTqsSfnuYTuDm6dhAPrD33dg4Ugsmzoc │   147365 │ 2021-11-15 10:41:07 │
│ 5    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmWTv7PenVdghkjWuMbP3QkqGn1bXzNVWN63N5WAeVJGY6 │ QmSMFYqexjmnkUNTqsSfnuYTuDm6dhAPrD33dg4Ugsmzoc │   147373 │ 2021-11-15 10:41:53 │
│ 6    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │ QmSMFYqexjmnkUNTqsSfnuYTuDm6dhAPrD33dg4Ugsmzoc │   147377 │ 2021-11-15 10:42:16 │
│ 7    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmZsS2pqk4diswHzrW3FFNn6UpEXr6P1dYeBkZFkHVTqWc │ QmSMFYqexjmnkUNTqsSfnuYTuDm6dhAPrD33dg4Ugsmzoc │   147398 │ 2021-11-15 10:44:16 │
│ 8    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │ QmbgP8xhzcYo6BY4jiFDeHQarnsJ8jWRTzsPTz2w3iRrjz │   147416 │ 2021-11-15 10:45:59 │
│ 9    │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmXJzxAxsJf5gBAWGzFua4Zp86i6sjgWkAvC5UwtzVdQuB │   147422 │ 2021-11-15 10:46:34 │
│ ...  │ ...                                            │ ...                                            │ ...                                            │ ...      │ ...                 │
│ 1011 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ 12570332 │ 2024-03-13 13:27:52 │
│ 1012 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ QmeQDBrFavhzKY6zVXPfoRKJgnbGSpjSH7fe7PdkuohfXw │ 12596377 │ 2024-03-15 08:15:50 │
│ 1013 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641050 │ 2024-03-18 09:49:09 │
│ 1014 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSS1GaRdKBdkvxrbQnnW7FrXcVCyZMBcuZsV7qPGWCEBS │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641076 │ 2024-03-18 09:51:42 │
│ 1015 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmTto1JaBHqT354oLjqxook2ikN7kanrfmB4eLGXw917AB │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │ 12641084 │ 2024-03-18 09:52:28 │
│ 1016 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │ Qme1RyD7Jtxg8LyUKcFLURoZXJvNTuK2sh3VbbsPDvRDsq │ 12641093 │ 2024-03-18 09:53:21 │
│ 1017 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPjz7yuUboFSV95yJXzUG8BDXK66bEBmDEbrcBqgafWqb │ QmUvxAbodisXtZDpiKpB9sZbHLhjNMxqWCpEm4doqWk1Cq │ 12641123 │ 2024-03-18 09:56:20 │
│ 1018 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmSozQsP5FXmWYuVGkZMVEdmj3as2WawzkGhJkyw6gGRz9 │ 12667642 │ 2024-03-20 05:16:12 │
│ 1019 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmQ8ntTiVnJxxBQSoeaAnNQR2oHvbpTgHLwWKWxGngZgbm │ 12667658 │ 2024-03-20 05:17:46 │
│ 1020 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmZdKqcYqYGy88QpUGZpqjmDUkwm6gZBhygxtSHbCKzbAV │ 12847309 │ 2024-04-01 13:14:37 │
╰──#───┴─────────────────────neuron─────────────────────┴─────────────────particle_from──────────────────┴──────────────────particle_to───────────────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts
╭─#──┬───────────────────────────────neuron───────────────────────────────┬─────────────────particle_from──────────────────┬──────────────────particle_to───────────────────┬──height──┬──────timestamp──────╮
│ 0  │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPhByrCLn4E8buNkYjPag9PuxXHPJgo7mAumxVAbm5U1N │  3627537 │ 2022-07-08 16:17:49 │
│ 1  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW │ QmbNve1YGn7vtSRm3XWvjG2AzFrB1zz78VJbAtpA2zEuhJ │  3627649 │ 2022-07-08 16:28:33 │
│ 2  │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmbekqiHTAPeiHM16Miw9VffHbSxuXWoS9grtsVNKXic5Y │  3627651 │ 2022-07-08 16:28:45 │
│ 3  │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmbgP8xhzcYo6BY4jiFDeHQarnsJ8jWRTzsPTz2w3iRrjz │  3627651 │ 2022-07-08 16:28:45 │
│ 4  │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmbgP8xhzcYo6BY4jiFDeHQarnsJ8jWRTzsPTz2w3iRrjz │  3627651 │ 2022-07-08 16:28:45 │
│ 5  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmdmTTWFQ4EY7Rcs781qTZ52Rmy8tD31juwQT39cUFnut3 │  3627694 │ 2022-07-08 16:32:54 │
│ 6  │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmP6FL1hkgP1cdj1SxJ81P3jfbZwpBitFEC8vJgWm1p3DC │ Qmb6ckJ1zaYx2htqzsgJSK4D7QRbJesPtaL9zYHq5EVnkg │  3627714 │ 2022-07-08 16:34:48 │
│ 7  │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j │  3628490 │ 2022-07-08 17:49:17 │
│ 8  │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmTHDFzGs6ph7HMCVovRn746Bf94sP4XMs42kBJ5iW1FAc │  3628490 │ 2022-07-08 17:49:17 │
│ 9  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmaNY1eb7GNiUm6wCoKKGp3Sfg8W5VuZwhKeWnDerHfruG │  3628701 │ 2022-07-08 18:09:37 │
│ 10 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW │ QmW9i7RJnpuLLiyHFbJqhsPkhijmsFw2kU8tZCygQrP7Pr │  3637974 │ 2022-07-09 09:00:44 │
│ 11 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW │ QmPohTpW8TNyjbtLJM61R7TsVdLa8ZPuTHBhteUzYL1Lbv │  3637979 │ 2022-07-09 09:01:13 │
│ 12 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmZuMzS6rbFS4p95kW3qhS4KUXwkLEP4uJJQZtrEkT75ZR │  7708791 │ 2023-04-12 03:21:39 │
│ 13 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmRNi4x7JmHFLJMvebrXKsHZySof2bi7yJzoTaXuDzHGR4 │  7708794 │ 2023-04-12 03:21:57 │
│ 14 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ Qmbb8FUJ4EBLj3nDZWowZrjEAVoFJ28RA7ytbCHJMHwMsa │  7708801 │ 2023-04-12 03:22:39 │
│ 15 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmVkT4wPn4XV2GAwAxYawApwUSVDnccehNaEibLdXphKiW │ 12234453 │ 2024-02-19 12:01:57 │
│ 16 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmPoomrqMFTTBhsgDWH2pmTArgfvb5XqogXz3qZoGDjbmp │ 12234459 │ 2024-02-19 12:02:32 │
╰─#──┴───────────────────────────────neuron───────────────────────────────┴─────────────────particle_from──────────────────┴──────────────────particle_to───────────────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts --exclude
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
│ 1254 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ 12570332 │ 2024-03-13 13:27:52 │
│ 1255 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmRSyyB1TVSyJRbKCXPJVvdjX7Q8ZBAE3hDJoo67TiFKab │ QmeQDBrFavhzKY6zVXPfoRKJgnbGSpjSH7fe7PdkuohfXw │ 12596377 │ 2024-03-15 08:15:50 │
│ 1256 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641050 │ 2024-03-18 09:49:09 │
│ 1257 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSS1GaRdKBdkvxrbQnnW7FrXcVCyZMBcuZsV7qPGWCEBS │ QmaViP33J9V7v2HYiXjbhH6BsJrBqY7ZnwU93nKTaCzs5f │ 12641076 │ 2024-03-18 09:51:42 │
│ 1258 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmTto1JaBHqT354oLjqxook2ikN7kanrfmB4eLGXw917AB │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │ 12641084 │ 2024-03-18 09:52:28 │
│ 1259 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │ Qme1RyD7Jtxg8LyUKcFLURoZXJvNTuK2sh3VbbsPDvRDsq │ 12641093 │ 2024-03-18 09:53:21 │
│ 1260 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmPjz7yuUboFSV95yJXzUG8BDXK66bEBmDEbrcBqgafWqb │ QmUvxAbodisXtZDpiKpB9sZbHLhjNMxqWCpEm4doqWk1Cq │ 12641123 │ 2024-03-18 09:56:20 │
│ 1261 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmSozQsP5FXmWYuVGkZMVEdmj3as2WawzkGhJkyw6gGRz9 │ 12667642 │ 2024-03-20 05:16:12 │
│ 1262 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmSZmi6xpwhxb7juxw61HoT2MNQtxFq6hNutLD5JZdjySW │ QmQ8ntTiVnJxxBQSoeaAnNQR2oHvbpTgHLwWKWxGngZgbm │ 12667658 │ 2024-03-20 05:17:46 │
│ 1263 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna │ QmZdKqcYqYGy88QpUGZpqjmDUkwm6gZBhygxtSHbCKzbAV │ 12847309 │ 2024-04-01 13:14:37 │
╰──#───┴─────────────────────neuron─────────────────────┴─────────────────particle_from──────────────────┴──────────────────particle_to───────────────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-keep-standard-columns-only
╭──#──┬───────────────────────────────neuron───────────────────────────────┬─────────────────particle_from──────────────────┬──────────────────particle_to───────────────────┬─height──┬──────timestamp──────╮
│ 0   │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPhByrCLn4E8buNkYjPag9PuxXHPJgo7mAumxVAbm5U1N │ 3627537 │ 2022-07-08 16:17:49 │
│ 1   │ bostrom1qjf43tsdhzfk5apchznuheqf6sux0wwmt4q4qq                     │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPWdU4mAqaxcwV6UboiH24aoVhcTLVwb4QoZjkA2aCiH4 │ 4544674 │ 2022-09-08 01:47:01 │
│ 2   │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPohTpW8TNyjbtLJM61R7TsVdLa8ZPuTHBhteUzYL1Lbv │ 5983239 │ 2022-12-14 16:11:51 │
│ 3   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPpLZkjEDbD1QXdfue1zEx3hJoJBJjsHAgD3dikeKmcq5 │ 8258496 │ 2023-05-20 08:42:09 │
│ 4   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPzEHHUm9pGd3Fot55sNA9UmQ89db2Car77mCrqzByzEZ │ 8242153 │ 2023-05-19 05:28:50 │
│ 5   │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmQUfxrT1Vb3rwrhiCrxSaDsGHV6n5jBXEcSaEDzX6zYj5 │ 3627537 │ 2022-07-08 16:17:49 │
│ 6   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M │  395741 │ 2021-12-02 06:45:13 │
│ 7   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │  395730 │ 2021-12-02 06:44:07 │
│ 8   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmSVa1XLM3XcY9Rm9XzXg9NnT6RutPPnXpL1kZB5McPCiR │  395739 │ 2021-12-02 06:45:01 │
│ 9   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmTN9CZ2n5c1un3mNSNymSyK9ww3vyt3cKQwm8A3t6e2rf │  395743 │ 2021-12-02 06:45:24 │
│ ... │ ...                                                                │ ...                                            │ ...                                            │ ...     │ ...                 │
│ 106 │ bostrom1823qj9q6eruxv8mfwfay87zd9pp66ayq0ckp9xttk0e758a6kl9qtglw7z │ QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j │ QmW5GREog52duzpQbHQ2da8NCQSkL218TWW9hQzsR11bGM │ 7825065 │ 2023-04-20 05:31:02 │
│ 107 │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │ QmTR3QWRK6k4uZspKSPnJqVAE8qZ9NHaJ5Xf3YQTasZWrh │ QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j │ 3628878 │ 2022-07-08 18:26:41 │
│ 108 │ bostrom1pc4ep362vkyrquq7r27wvm08u2yjxwnuylc509s2dfumw4qwt7hsdavx33 │ QmW5GREog52duzpQbHQ2da8NCQSkL218TWW9hQzsR11bGM │ QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j │ 7912873 │ 2023-04-26 07:32:57 │
│ 109 │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │ QmZid7P7oYhV43dpv7WkVyrf7oHRvqMkBh8JBWtyEJ27m6 │ QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j │ 6406162 │ 2023-01-12 12:53:56 │
│ 110 │ bostrom1qnlxnneluedfg3lusv8r36t5c0s4r2p0xhhszj                     │ QmTHDFzGs6ph7HMCVovRn746Bf94sP4XMs42kBJ5iW1FAc │ QmVYMVibAfUtHdneRnwaBRWH7poxT6BfYEwBWegk6uwUXK │ 4546075 │ 2022-09-08 04:03:17 │
│ 111 │ bostrom1taq9pscnws852tfvd4vrtckztu0kttkkqzx8dv                     │ QmTHDFzGs6ph7HMCVovRn746Bf94sP4XMs42kBJ5iW1FAc │ QmVas7T5i9rRcqFDndhynhYXcqdoMYMR5QkZZRi39HUxya │  150903 │ 2021-11-15 16:23:22 │
│ 112 │ bostrom1zy8knphzhf9u8xeyjc6k3eps96q48hlmj03zsk                     │ QmTHDFzGs6ph7HMCVovRn746Bf94sP4XMs42kBJ5iW1FAc │ Qmc3Xpzc4B3KMaqRFACg4FpbXUXmb56DBEXSTDzSShQhmm │  552203 │ 2021-12-12 20:31:59 │
│ 113 │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmZid7P7oYhV43dpv7WkVyrf7oHRvqMkBh8JBWtyEJ27m6 │ QmTHDFzGs6ph7HMCVovRn746Bf94sP4XMs42kBJ5iW1FAc │ 6406162 │ 2023-01-12 12:53:56 │
│ 114 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmfQdNw9ajQwNW6eA35DRS7tTb1gnFCULRCKQat4zABRC6 │ QmTHDFzGs6ph7HMCVovRn746Bf94sP4XMs42kBJ5iW1FAc │ 6700597 │ 2023-02-01 16:36:31 │
│ 115 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmfQdNw9ajQwNW6eA35DRS7tTb1gnFCULRCKQat4zABRC6 │ QmaNY1eb7GNiUm6wCoKKGp3Sfg8W5VuZwhKeWnDerHfruG │ 6700597 │ 2023-02-01 16:36:31 │
╰──#──┴───────────────────────────────neuron───────────────────────────────┴─────────────────particle_from──────────────────┴──────────────────particle_to───────────────────┴─height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related --only_first_neuron  | graph-keep-standard-columns-only
╭──#──┬───────────────────────────────neuron───────────────────────────────┬─────────────────particle_from──────────────────┬──────────────────particle_to───────────────────┬──height──┬──────timestamp──────╮
│ 0   │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPhByrCLn4E8buNkYjPag9PuxXHPJgo7mAumxVAbm5U1N │  3627537 │ 2022-07-08 16:17:49 │
│ 1   │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW │ QmbNve1YGn7vtSRm3XWvjG2AzFrB1zz78VJbAtpA2zEuhJ │  3627649 │ 2022-07-08 16:28:33 │
│ 2   │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmbNve1YGn7vtSRm3XWvjG2AzFrB1zz78VJbAtpA2zEuhJ │  8303189 │ 2023-05-23 11:00:52 │
│ 3   │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmbekqiHTAPeiHM16Miw9VffHbSxuXWoS9grtsVNKXic5Y │  3627651 │ 2022-07-08 16:28:45 │
│ 4   │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmRNi4x7JmHFLJMvebrXKsHZySof2bi7yJzoTaXuDzHGR4 │  7708794 │ 2023-04-12 03:21:57 │
│ 5   │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmZuMzS6rbFS4p95kW3qhS4KUXwkLEP4uJJQZtrEkT75ZR │  7708791 │ 2023-04-12 03:21:39 │
│ 6   │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ Qmbb8FUJ4EBLj3nDZWowZrjEAVoFJ28RA7ytbCHJMHwMsa │  7708801 │ 2023-04-12 03:22:39 │
│ 7   │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmbgP8xhzcYo6BY4jiFDeHQarnsJ8jWRTzsPTz2w3iRrjz │  3627651 │ 2022-07-08 16:28:45 │
│ 8   │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmdmTTWFQ4EY7Rcs781qTZ52Rmy8tD31juwQT39cUFnut3 │  3627694 │ 2022-07-08 16:32:54 │
│ 9   │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │ QmYkSwEwVSWW8dGWrwfsuYEVshhtttpJ1K9RqVjEv6PRFv │ QmeNdaP5sgZL7RtwvQsWLcTbkc9VHEQ3vQajAbZoCzTU7e │  4476775 │ 2022-09-03 11:37:13 │
│ ... │ ...                                                                │ ...                                            │ ...                                            │ ...      │ ...                 │
│ 18  │ bostrom1679yrs8dmska7wcsawgy2m25kwucm3z0hwr74y                     │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmWTmGZdx6JbDfU5n7418NcNS4PzGV2i2YNC1RDyMw28rB │ 12031008 │ 2024-02-05 08:14:06 │
│ 19  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmaNY1eb7GNiUm6wCoKKGp3Sfg8W5VuZwhKeWnDerHfruG │  3628701 │ 2022-07-08 18:09:37 │
│ 20  │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ Qmbdpsk6d4tqMjZJmBf4WUUYLPVy2oh3JChPR9DRAdDTsf │  6638028 │ 2023-01-28 10:17:49 │
│ 21  │ bostrom1679yrs8dmska7wcsawgy2m25kwucm3z0hwr74y                     │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmeBgEfMAWb6iFSsYVx2TGSZLYEL1Nv2YrFQ9XuLApQCdk │ 11834968 │ 2024-01-22 16:39:52 │
│ 22  │ bostrom1v5x5vl4c0zjua37ymqjy4267fy9m6x8yvzvkfp                     │ QmaMhB3x2dM6pp3dWo4oHWvLjtqXUkA5SMXuMuvFPcw8pT │ QmfQdNw9ajQwNW6eA35DRS7tTb1gnFCULRCKQat4zABRC6 │  5255875 │ 2022-10-26 06:07:51 │
│ 23  │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │ QmfQdNw9ajQwNW6eA35DRS7tTb1gnFCULRCKQat4zABRC6 │ QmaNY1eb7GNiUm6wCoKKGp3Sfg8W5VuZwhKeWnDerHfruG │  6700597 │ 2023-02-01 16:36:31 │
│ 24  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW │ QmW9i7RJnpuLLiyHFbJqhsPkhijmsFw2kU8tZCygQrP7Pr │  3637974 │ 2022-07-09 09:00:44 │
│ 25  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmW9i7RJnpuLLiyHFbJqhsPkhijmsFw2kU8tZCygQrP7Pr │  5983204 │ 2022-12-14 16:08:26 │
│ 26  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW │ QmPohTpW8TNyjbtLJM61R7TsVdLa8ZPuTHBhteUzYL1Lbv │  3637979 │ 2022-07-09 09:01:13 │
│ 27  │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │ QmVww6z5eshB4puR74xCwmNPrsbcou1dfF8Q2zmW4sJiUP │ QmPohTpW8TNyjbtLJM61R7TsVdLa8ZPuTHBhteUzYL1Lbv │  5983239 │ 2022-12-14 16:11:51 │
╰──#──┴───────────────────────────────neuron───────────────────────────────┴─────────────────particle_from──────────────────┴──────────────────particle_to───────────────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-neurons-stats | graph-keep-standard-columns-only --extra_columns [nickname links_count neuron]
╭──#──┬──────nickname──────┬─links_count─┬───────────────────────────────neuron───────────────────────────────╮
│ 0   │ mastercyb          │          24 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │
│ 1   │ ?                  │          16 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │
│ 2   │ cyberacademy       │          14 │ bostrom1679yrs8dmska7wcsawgy2m25kwucm3z0hwr74y                     │
│ 3   │ ?                  │          12 │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │
│ 4   │ cicada             │           8 │ bostrom1qjf43tsdhzfk5apchznuheqf6sux0wwmt4q4qq                     │
│ 5   │ jooy               │           6 │ bostrom1k7nssnnvxezpp4una7lvk6j53895vadpqe6jh6                     │
│ 6   │ ?                  │           6 │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │
│ 7   │ maxim              │           4 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │
│ 8   │ el-nivvo           │           4 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k                     │
│ 9   │ cyberdbot          │           3 │ bostrom135ca8hdpy9sk0ntwqzpzsvatyl48ptx5j359lz                     │
│ ... │ ...                │ ...         │ ...                                                                │
│ 15  │ therealcalmate     │           1 │ bostrom1ltpef4eyh72ly3x8cx6ath6sfg94ag42aga5n5                     │
│ 16  │ mazw1010           │           1 │ bostrom13eehekx464l2qtl4xfyzggvd77nef22x82asv8                     │
│ 17  │ kalpemo            │           1 │ bostrom1rj7zt2pzuzwhjlr24u0prnqqxm3xexavtpqtzx                     │
│ 18  │ elonamusk          │           1 │ bostrom19wtkh935tx2ut2n4m6tjvkfvew4shaeezfl7em                     │
│ 19  │ castigaojetes      │           1 │ bostrom1kwwp7f5pszyxr39whf2rwm7gly596mdw5gmmf4                     │
│ 20  │ belzebuth          │           1 │ bostrom1qnlxnneluedfg3lusv8r36t5c0s4r2p0xhhszj                     │
│ 21  │ ?                  │           1 │ bostrom15xx4xh3p7f773ssyz25ydrk27g09cl7qfh75mh                     │
│ 22  │ superhuman         │           1 │ bostrom1pntx8ql2v7cqxu05etg8c4v0r2vz7qnq9uqmpy                     │
│ 23  │ digital-oppression │           1 │ bostrom1g70uv8y47s5pn07n4gtgakz278vps228r9emvt                     │
│ 24  │ laurentiu          │           1 │ bostrom1zy8knphzhf9u8xeyjc6k3eps96q48hlmj03zsk                     │
╰──#──┴──────nickname──────┴─links_count─┴───────────────────────────────neuron───────────────────────────────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-stats
╭───────────┬───────────────────╮
│ neurons   │ 25                │
│ links     │ {record 6 fields} │
│ particles │ {record 4 fields} │
╰───────────┴───────────────────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-stats | table -e
╭───────────┬───────────────────────────────────╮
│ neurons   │ 25                                │
│           │ ╭─────────┬─────────────────────╮ │
│ links     │ │ links   │ 116                 │ │
│           │ │ first   │ 2021-11-06 09:12:42 │ │
│           │ │ last    │ 2024-04-02 19:27:46 │ │
│           │ │ unique  │ 116                 │ │
│           │ │ follows │ 0                   │ │
│           │ │ tweets  │ 0                   │ │
│           │ ╰─────────┴─────────────────────╯ │
│           │ ╭────────────────┬─────╮          │
│ particles │ │ unique         │ 103 │          │
│           │ │ text           │ 81  │          │
│           │ │ nontext        │ 10  │          │
│           │ │ not_downloaded │ 12  │          │
│           │ ╰────────────────┴─────╯          │
╰───────────┴───────────────────────────────────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-to-gephi 

> graph-links-df test-graph.csv | graph-filter-contracts | graph-to-cosmograph 
You can upload the file to https://cosmograph.app/run
/Users/user/cy/export/cybergraph-in-cosmograph20240428-055955.csv

> graph-links-df test-graph.csv | graph-filter-contracts | graph-to-graphviz 
digraph G {

"mastercyb|W4sJiUP" -> "bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t|Abm5U1N";
"master|BVe3UhW" -> "0xb2e19dd996848818d972dd3a60a1b7faffb82330|A2zEuhJ";
"el-nivvo|Ev6PRFv" -> "\"MIME type\" = \"image/jpeg\"
Size = 533643
|NKXic5Y";
"el-nivvo|Ev6PRFv" -> "bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k|w3iRrjz";
"el-nivvo|Ev6PRFv" -> "bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k|w3iRrjz";
"el-nivvo|Ev6PRFv" -> "osmo1ay267fakkrgfy9lf2m7wsj8uez2dgylhq722dr|cUFnut3";
"cyberdbot|Wm1p3DC" -> "bostrom135ca8hdpy9sk0ntwqzpzsvatyl48ptx5j359lz|q5EVnkg";
"maxim|FPcw8pT" -> "\"MIME type\" = \"image/gif\"
Size = 218789
|ULWb28j";
"maxim|FPcw8pT" -> "bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8|5iW1FAc";
"maxim|FPcw8pT" -> "cosmos173u67p9zefy24y0ze3v3dwh0upsge20a0xrplu|erHfruG";
"master|BVe3UhW" -> "cosmos1qn8sr2hzmktlecusdtxj9hwj0upnm0jfgkyqry|gQrP7Pr";
"master|BVe3UhW" -> "osmo1qn8sr2hzmktlecusdtxj9hwj0upnm0jfqdhs4k|zYL1Lbv";
"el-nivvo|Ev6PRFv" -> "terra1ga62w77l9ry86nncnj0pezl2hw8su5ec60jj2q|EkT75ZR";
"el-nivvo|Ev6PRFv" -> "cosmos1ay267fakkrgfy9lf2m7wsj8uez2dgylhg9e6m3|uDzHGR4";
"el-nivvo|Ev6PRFv" -> "0x81645c8072a592c17f3d8424d74b04bfa0cf299e|JMHwMsa";
"maxim|FPcw8pT" -> "osmo1nngr5aj3gcvphlhnvtqth8k3sl4asq3n3teenj|dXphKiW";
"maxim|FPcw8pT" -> "terra1h9epjq7wp08ypj7g99k0vs4xtvk9acmq3saxrl|oGDjbmp";
}

> graph-links-df test-graph.csv | graph-filter-contracts | graph-add-metadata | graph-keep-standard-columns-only --out
╭─#──┬────────────nick────────────┬──content_s_from───┬──────────────────────content_s_to──────────────────────╮
│ 0  │ passport-address_?@q9qaku3 │ mastercyb|W4sJiUP │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t|Abm5U1N │
│ 1  │ passport-proofs_?@sts7qxt  │ master|BVe3UhW    │ 0xb2e19dd996848818d972dd3a60a1b7faffb82330|A2zEuhJ     │
│ 2  │ passport-image_?@qlq7nz2   │ el-nivvo|Ev6PRFv  │ "MIME type" = "image/jpeg"⏎Size = 533643⏎|NKXic5Y      │
│ 3  │ passport-address_?@q9qaku3 │ el-nivvo|Ev6PRFv  │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k|w3iRrjz │
│ 4  │ passport-address_?@q9qaku3 │ el-nivvo|Ev6PRFv  │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k|w3iRrjz │
│ 5  │ passport-proofs_?@sts7qxt  │ el-nivvo|Ev6PRFv  │ osmo1ay267fakkrgfy9lf2m7wsj8uez2dgylhq722dr|cUFnut3    │
│ 6  │ passport-address_?@q9qaku3 │ cyberdbot|Wm1p3DC │ bostrom135ca8hdpy9sk0ntwqzpzsvatyl48ptx5j359lz|q5EVnkg │
│ 7  │ passport-image_?@qlq7nz2   │ maxim|FPcw8pT     │ "MIME type" = "image/gif"⏎Size = 218789⏎|ULWb28j       │
│ 8  │ passport-address_?@q9qaku3 │ maxim|FPcw8pT     │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8|5iW1FAc │
│ 9  │ passport-proofs_?@sts7qxt  │ maxim|FPcw8pT     │ cosmos173u67p9zefy24y0ze3v3dwh0upsge20a0xrplu|erHfruG  │
│ 10 │ passport-proofs_?@sts7qxt  │ master|BVe3UhW    │ cosmos1qn8sr2hzmktlecusdtxj9hwj0upnm0jfgkyqry|gQrP7Pr  │
│ 11 │ passport-proofs_?@sts7qxt  │ master|BVe3UhW    │ osmo1qn8sr2hzmktlecusdtxj9hwj0upnm0jfqdhs4k|zYL1Lbv    │
│ 12 │ passport-proofs_?@sts7qxt  │ el-nivvo|Ev6PRFv  │ terra1ga62w77l9ry86nncnj0pezl2hw8su5ec60jj2q|EkT75ZR   │
│ 13 │ passport-proofs_?@sts7qxt  │ el-nivvo|Ev6PRFv  │ cosmos1ay267fakkrgfy9lf2m7wsj8uez2dgylhg9e6m3|uDzHGR4  │
│ 14 │ passport-proofs_?@sts7qxt  │ el-nivvo|Ev6PRFv  │ 0x81645c8072a592c17f3d8424d74b04bfa0cf299e|JMHwMsa     │
│ 15 │ passport-proofs_?@sts7qxt  │ maxim|FPcw8pT     │ osmo1nngr5aj3gcvphlhnvtqth8k3sl4asq3n3teenj|dXphKiW    │
│ 16 │ passport-proofs_?@sts7qxt  │ maxim|FPcw8pT     │ terra1h9epjq7wp08ypj7g99k0vs4xtvk9acmq3saxrl|oGDjbmp   │
╰─#──┴────────────nick────────────┴──content_s_from───┴──────────────────────content_s_to──────────────────────╯
```
