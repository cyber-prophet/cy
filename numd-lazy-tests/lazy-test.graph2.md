```nushell
> overlay use -r ~/cy/cy.nu
> graph-links-df test-graph.csv | graph-filter-neurons maxim@n6r76m8
╭──#───┬──────────neuron───────────┬───────particle_from────────┬────────particle_to─────────┬──height──┬──────timestamp──────╮
│ 0    │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmaxuSoSUkgKBGBJkT2Ypk9... │    87794 │ 2021-11-11 10:36:24 │
│ 1    │ bostrom1nngr5aj3gcvphl... │ Qmf89bXkJH9jw4uaLkHmZkx... │ QmYnLm5MFGFwcoXo65XpUyC... │    88371 │ 2021-11-11 11:31:54 │
│ 2    │ bostrom1nngr5aj3gcvphl... │ QmST3fBarm3M783FpwhsqBc... │ QmRCcwFq9JjYEGCE22CTWfP... │    88449 │ 2021-11-11 11:39:25 │
│ 3    │ bostrom1nngr5aj3gcvphl... │ QmTbiVj2kq4nqAaQH6zym5E... │ Qmdo6FeBhcu1rW3bC2eu62g... │   115916 │ 2021-11-13 08:04:59 │
│ 4    │ bostrom1nngr5aj3gcvphl... │ QmS6mcrMTFsZnT3wAptqEb8... │ QmSMFYqexjmnkUNTqsSfnuY... │   147365 │ 2021-11-15 10:41:07 │
│ 5    │ bostrom1nngr5aj3gcvphl... │ QmWTv7PenVdghkjWuMbP3Qk... │ QmSMFYqexjmnkUNTqsSfnuY... │   147373 │ 2021-11-15 10:41:53 │
│ 6    │ bostrom1nngr5aj3gcvphl... │ QmPcfxEfW317u3bbz8MbEhj... │ QmSMFYqexjmnkUNTqsSfnuY... │   147377 │ 2021-11-15 10:42:16 │
│ 7    │ bostrom1nngr5aj3gcvphl... │ QmZsS2pqk4diswHzrW3FFNn... │ QmSMFYqexjmnkUNTqsSfnuY... │   147398 │ 2021-11-15 10:44:16 │
│ 8    │ bostrom1nngr5aj3gcvphl... │ QmPLSA5oPqYxgc8F7EwrM8W... │ QmbgP8xhzcYo6BY4jiFDeHQ... │   147416 │ 2021-11-15 10:45:59 │
│ 9    │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmXJzxAxsJf5gBAWGzFua4Z... │   147422 │ 2021-11-15 10:46:34 │
│ ...  │ ...                       │ ...                        │ ...                        │ ...      │ ...                 │
│ 1011 │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmRSyyB1TVSyJRbKCXPJVvd... │ 12570332 │ 2024-03-13 13:27:52 │
│ 1012 │ bostrom1nngr5aj3gcvphl... │ QmRSyyB1TVSyJRbKCXPJVvd... │ QmeQDBrFavhzKY6zVXPfoRK... │ 12596377 │ 2024-03-15 08:15:50 │
│ 1013 │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmaViP33J9V7v2HYiXjbhH6... │ 12641050 │ 2024-03-18 09:49:09 │
│ 1014 │ bostrom1nngr5aj3gcvphl... │ QmSS1GaRdKBdkvxrbQnnW7F... │ QmaViP33J9V7v2HYiXjbhH6... │ 12641076 │ 2024-03-18 09:51:42 │
│ 1015 │ bostrom1nngr5aj3gcvphl... │ QmTto1JaBHqT354oLjqxook... │ QmWm9pmmz66cq41t1vtZWoR... │ 12641084 │ 2024-03-18 09:52:28 │
│ 1016 │ bostrom1nngr5aj3gcvphl... │ QmPLSA5oPqYxgc8F7EwrM8W... │ Qme1RyD7Jtxg8LyUKcFLURo... │ 12641093 │ 2024-03-18 09:53:21 │
│ 1017 │ bostrom1nngr5aj3gcvphl... │ QmPjz7yuUboFSV95yJXzUG8... │ QmUvxAbodisXtZDpiKpB9sZ... │ 12641123 │ 2024-03-18 09:56:20 │
│ 1018 │ bostrom1nngr5aj3gcvphl... │ QmSZmi6xpwhxb7juxw61HoT... │ QmSozQsP5FXmWYuVGkZMVEd... │ 12667642 │ 2024-03-20 05:16:12 │
│ 1019 │ bostrom1nngr5aj3gcvphl... │ QmSZmi6xpwhxb7juxw61HoT... │ QmQ8ntTiVnJxxBQSoeaAnNQ... │ 12667658 │ 2024-03-20 05:17:46 │
│ 1020 │ bostrom1nngr5aj3gcvphl... │ QmR7zZv2PNo477ixpKBVYVU... │ QmZdKqcYqYGy88QpUGZpqjm... │ 12847309 │ 2024-04-01 13:14:37 │
╰──#───┴──────────neuron───────────┴───────particle_from────────┴────────particle_to─────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts
╭─#──┬───────────neuron───────────┬───────particle_from────────┬─────────particle_to─────────┬──height──┬──────timestamp──────╮
│ 0  │ bostrom1jkte0pytr85qg0w... │ QmVww6z5eshB4puR74xCwmN... │ QmPhByrCLn4E8buNkYjPag9P... │  3627537 │ 2022-07-08 16:17:49 │
│ 1  │ bostrom16y344e8ryydmeu2... │ QmZbcRTU4fdrMy2YzDKEUAX... │ QmbNve1YGn7vtSRm3XWvjG2A... │  3627649 │ 2022-07-08 16:28:33 │
│ 2  │ bostrom10fqy0npt7djm8lg... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmbekqiHTAPeiHM16Miw9Vff... │  3627651 │ 2022-07-08 16:28:45 │
│ 3  │ bostrom1jkte0pytr85qg0w... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmbgP8xhzcYo6BY4jiFDeHQa... │  3627651 │ 2022-07-08 16:28:45 │
│ 4  │ bostrom1jkte0pytr85qg0w... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmbgP8xhzcYo6BY4jiFDeHQa... │  3627651 │ 2022-07-08 16:28:45 │
│ 5  │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmdmTTWFQ4EY7Rcs781qTZ52... │  3627694 │ 2022-07-08 16:32:54 │
│ 6  │ bostrom1jkte0pytr85qg0w... │ QmP6FL1hkgP1cdj1SxJ81P3... │ Qmb6ckJ1zaYx2htqzsgJSK4D... │  3627714 │ 2022-07-08 16:34:48 │
│ 7  │ bostrom10fqy0npt7djm8lg... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmNprvRpqVsQEqEoTRJfZUB5... │  3628490 │ 2022-07-08 17:49:17 │
│ 8  │ bostrom1jkte0pytr85qg0w... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmTHDFzGs6ph7HMCVovRn746... │  3628490 │ 2022-07-08 17:49:17 │
│ 9  │ bostrom16y344e8ryydmeu2... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmaNY1eb7GNiUm6wCoKKGp3S... │  3628701 │ 2022-07-08 18:09:37 │
│ 10 │ bostrom16y344e8ryydmeu2... │ QmZbcRTU4fdrMy2YzDKEUAX... │ QmW9i7RJnpuLLiyHFbJqhsPk... │  3637974 │ 2022-07-09 09:00:44 │
│ 11 │ bostrom16y344e8ryydmeu2... │ QmZbcRTU4fdrMy2YzDKEUAX... │ QmPohTpW8TNyjbtLJM61R7Ts... │  3637979 │ 2022-07-09 09:01:13 │
│ 12 │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmZuMzS6rbFS4p95kW3qhS4K... │  7708791 │ 2023-04-12 03:21:39 │
│ 13 │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmRNi4x7JmHFLJMvebrXKsHZ... │  7708794 │ 2023-04-12 03:21:57 │
│ 14 │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ Qmbb8FUJ4EBLj3nDZWowZrjE... │  7708801 │ 2023-04-12 03:22:39 │
│ 15 │ bostrom16y344e8ryydmeu2... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmVkT4wPn4XV2GAwAxYawApw... │ 12234453 │ 2024-02-19 12:01:57 │
│ 16 │ bostrom16y344e8ryydmeu2... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmPoomrqMFTTBhsgDWH2pmTA... │ 12234459 │ 2024-02-19 12:02:32 │
╰─#──┴───────────neuron───────────┴───────particle_from────────┴─────────particle_to─────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts --exclude
╭──#───┬──────────neuron───────────┬───────particle_from────────┬────────particle_to─────────┬──height──┬──────timestamp──────╮
│ 0    │ bostrom1ay267fakkrgfy9... │ QmPcfxEfW317u3bbz8MbEhj... │ QmXQ4k4ciK5ieaSwtccmH9m... │     9029 │ 2021-11-06 03:52:13 │
│ 1    │ bostrom1d8754xqa9245pc... │ QmYrXCXqunhqqirz3LBmvbn... │ QmY4X4SkVBkoUGZdTzdcW7S... │    12863 │ 2021-11-06 09:59:22 │
│ 2    │ bostrom1d8754xqa9245pc... │ QmRX8qYgeZoYM3M5zzQaWEp... │ QmY4X4SkVBkoUGZdTzdcW7S... │    12869 │ 2021-11-06 09:59:57 │
│ 3    │ bostrom1d8754xqa9245pc... │ QmRkxeB7V537fVc8913TmQw... │ QmRBxwqwNhLUjnsKwm8giYN... │    15287 │ 2021-11-06 13:52:52 │
│ 4    │ bostrom1d8754xqa9245pc... │ QmRkxeB7V537fVc8913TmQw... │ QmSDCFfY1S2UxoDkhbAtFbn... │    15303 │ 2021-11-06 13:54:27 │
│ 5    │ bostrom1d8754xqa9245pc... │ QmRkxeB7V537fVc8913TmQw... │ Qmd4suKEMpRKuFkEeGbsHqD... │    15315 │ 2021-11-06 13:55:38 │
│ 6    │ bostrom1d8754xqa9245pc... │ QmRkxeB7V537fVc8913TmQw... │ QmWjcFRoVPeYXWug6NsoWFG... │    15340 │ 2021-11-06 13:58:01 │
│ 7    │ bostrom1d8754xqa9245pc... │ QmRX8qYgeZoYM3M5zzQaWEp... │ QmWjcFRoVPeYXWug6NsoWFG... │    15343 │ 2021-11-06 13:58:19 │
│ 8    │ bostrom1d8754xqa9245pc... │ QmRkxeB7V537fVc8913TmQw... │ QmcwgfBG21fQ3sqiQhwnvFm... │    15379 │ 2021-11-06 14:01:50 │
│ 9    │ bostrom1d8754xqa9245pc... │ QmRX8qYgeZoYM3M5zzQaWEp... │ QmcwgfBG21fQ3sqiQhwnvFm... │    15400 │ 2021-11-06 14:03:50 │
│ ...  │ ...                       │ ...                        │ ...                        │ ...      │ ...                 │
│ 1254 │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmRSyyB1TVSyJRbKCXPJVvd... │ 12570332 │ 2024-03-13 13:27:52 │
│ 1255 │ bostrom1nngr5aj3gcvphl... │ QmRSyyB1TVSyJRbKCXPJVvd... │ QmeQDBrFavhzKY6zVXPfoRK... │ 12596377 │ 2024-03-15 08:15:50 │
│ 1256 │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmaViP33J9V7v2HYiXjbhH6... │ 12641050 │ 2024-03-18 09:49:09 │
│ 1257 │ bostrom1nngr5aj3gcvphl... │ QmSS1GaRdKBdkvxrbQnnW7F... │ QmaViP33J9V7v2HYiXjbhH6... │ 12641076 │ 2024-03-18 09:51:42 │
│ 1258 │ bostrom1nngr5aj3gcvphl... │ QmTto1JaBHqT354oLjqxook... │ QmWm9pmmz66cq41t1vtZWoR... │ 12641084 │ 2024-03-18 09:52:28 │
│ 1259 │ bostrom1nngr5aj3gcvphl... │ QmPLSA5oPqYxgc8F7EwrM8W... │ Qme1RyD7Jtxg8LyUKcFLURo... │ 12641093 │ 2024-03-18 09:53:21 │
│ 1260 │ bostrom1nngr5aj3gcvphl... │ QmPjz7yuUboFSV95yJXzUG8... │ QmUvxAbodisXtZDpiKpB9sZ... │ 12641123 │ 2024-03-18 09:56:20 │
│ 1261 │ bostrom1nngr5aj3gcvphl... │ QmSZmi6xpwhxb7juxw61HoT... │ QmSozQsP5FXmWYuVGkZMVEd... │ 12667642 │ 2024-03-20 05:16:12 │
│ 1262 │ bostrom1nngr5aj3gcvphl... │ QmSZmi6xpwhxb7juxw61HoT... │ QmQ8ntTiVnJxxBQSoeaAnNQ... │ 12667658 │ 2024-03-20 05:17:46 │
│ 1263 │ bostrom1nngr5aj3gcvphl... │ QmR7zZv2PNo477ixpKBVYVU... │ QmZdKqcYqYGy88QpUGZpqjm... │ 12847309 │ 2024-04-01 13:14:37 │
╰──#───┴──────────neuron───────────┴───────particle_from────────┴────────particle_to─────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-keep-standard-columns-only
╭──#──┬───────────neuron───────────┬───────particle_from────────┬─────────particle_to─────────┬─height──┬──────timestamp──────╮
│ 0   │ bostrom1jkte0pytr85qg0w... │ QmVww6z5eshB4puR74xCwmN... │ QmPhByrCLn4E8buNkYjPag9P... │ 3627537 │ 2022-07-08 16:17:49 │
│ 1   │ bostrom1qjf43tsdhzfk5ap... │ QmVww6z5eshB4puR74xCwmN... │ QmPWdU4mAqaxcwV6UboiH24a... │ 4544674 │ 2022-09-08 01:47:01 │
│ 2   │ bostrom16y344e8ryydmeu2... │ QmVww6z5eshB4puR74xCwmN... │ QmPohTpW8TNyjbtLJM61R7Ts... │ 5983239 │ 2022-12-14 16:11:51 │
│ 3   │ bostrom1d8754xqa9245pct... │ QmVww6z5eshB4puR74xCwmN... │ QmPpLZkjEDbD1QXdfue1zEx3... │ 8258496 │ 2023-05-20 08:42:09 │
│ 4   │ bostrom1d8754xqa9245pct... │ QmVww6z5eshB4puR74xCwmN... │ QmPzEHHUm9pGd3Fot55sNA9U... │ 8242153 │ 2023-05-19 05:28:50 │
│ 5   │ bostrom10fqy0npt7djm8lg... │ QmVww6z5eshB4puR74xCwmN... │ QmQUfxrT1Vb3rwrhiCrxSaDs... │ 3627537 │ 2022-07-08 16:17:49 │
│ 6   │ bostrom1d8754xqa9245pct... │ QmVww6z5eshB4puR74xCwmN... │ QmRMMbTqFQ3o2NmHNYzLoS5f... │  395741 │ 2021-12-02 06:45:13 │
│ 7   │ bostrom1d8754xqa9245pct... │ QmVww6z5eshB4puR74xCwmN... │ QmRX8qYgeZoYM3M5zzQaWEpV... │  395730 │ 2021-12-02 06:44:07 │
│ 8   │ bostrom1d8754xqa9245pct... │ QmVww6z5eshB4puR74xCwmN... │ QmSVa1XLM3XcY9Rm9XzXg9Nn... │  395739 │ 2021-12-02 06:45:01 │
│ 9   │ bostrom1d8754xqa9245pct... │ QmVww6z5eshB4puR74xCwmN... │ QmTN9CZ2n5c1un3mNSNymSyK... │  395743 │ 2021-12-02 06:45:24 │
│ ... │ ...                        │ ...                        │ ...                         │ ...     │ ...                 │
│ 107 │ bostrom1823qj9q6eruxv8m... │ QmNprvRpqVsQEqEoTRJfZUB... │ QmW5GREog52duzpQbHQ2da8N... │ 7825065 │ 2023-04-20 05:31:02 │
│ 108 │ bostrom10fqy0npt7djm8lg... │ QmTR3QWRK6k4uZspKSPnJqV... │ QmNprvRpqVsQEqEoTRJfZUB5... │ 3628878 │ 2022-07-08 18:26:41 │
│ 109 │ bostrom1pc4ep362vkyrquq... │ QmW5GREog52duzpQbHQ2da8... │ QmNprvRpqVsQEqEoTRJfZUB5... │ 7912873 │ 2023-04-26 07:32:57 │
│ 110 │ bostrom10fqy0npt7djm8lg... │ QmZid7P7oYhV43dpv7WkVyr... │ QmNprvRpqVsQEqEoTRJfZUB5... │ 6406162 │ 2023-01-12 12:53:56 │
│ 111 │ bostrom1qnlxnneluedfg3l... │ QmTHDFzGs6ph7HMCVovRn74... │ QmVYMVibAfUtHdneRnwaBRWH... │ 4546075 │ 2022-09-08 04:03:17 │
│ 112 │ bostrom1taq9pscnws852tf... │ QmTHDFzGs6ph7HMCVovRn74... │ QmVas7T5i9rRcqFDndhynhYX... │  150903 │ 2021-11-15 16:23:22 │
│ 113 │ bostrom1zy8knphzhf9u8xe... │ QmTHDFzGs6ph7HMCVovRn74... │ Qmc3Xpzc4B3KMaqRFACg4Fpb... │  552203 │ 2021-12-12 20:31:59 │
│ 114 │ bostrom1jkte0pytr85qg0w... │ QmZid7P7oYhV43dpv7WkVyr... │ QmTHDFzGs6ph7HMCVovRn746... │ 6406162 │ 2023-01-12 12:53:56 │
│ 115 │ bostrom1nngr5aj3gcvphlh... │ QmfQdNw9ajQwNW6eA35DRS7... │ QmTHDFzGs6ph7HMCVovRn746... │ 6700597 │ 2023-02-01 16:36:31 │
│ 116 │ bostrom1nngr5aj3gcvphlh... │ QmfQdNw9ajQwNW6eA35DRS7... │ QmaNY1eb7GNiUm6wCoKKGp3S... │ 6700597 │ 2023-02-01 16:36:31 │
╰──#──┴───────────neuron───────────┴───────particle_from────────┴─────────particle_to─────────┴─height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related --only_first_neuron  | graph-keep-standard-columns-only
╭──#──┬───────────neuron───────────┬───────particle_from────────┬────────particle_to─────────┬──height──┬──────timestamp──────╮
│ 0   │ bostrom1jkte0pytr85qg0w... │ QmVww6z5eshB4puR74xCwmN... │ QmPhByrCLn4E8buNkYjPag9... │  3627537 │ 2022-07-08 16:17:49 │
│ 1   │ bostrom16y344e8ryydmeu2... │ QmZbcRTU4fdrMy2YzDKEUAX... │ QmbNve1YGn7vtSRm3XWvjG2... │  3627649 │ 2022-07-08 16:28:33 │
│ 2   │ bostrom16y344e8ryydmeu2... │ QmVww6z5eshB4puR74xCwmN... │ QmbNve1YGn7vtSRm3XWvjG2... │  8303189 │ 2023-05-23 11:00:52 │
│ 3   │ bostrom10fqy0npt7djm8lg... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmbekqiHTAPeiHM16Miw9Vf... │  3627651 │ 2022-07-08 16:28:45 │
│ 4   │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmRNi4x7JmHFLJMvebrXKsH... │  7708794 │ 2023-04-12 03:21:57 │
│ 5   │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmZuMzS6rbFS4p95kW3qhS4... │  7708791 │ 2023-04-12 03:21:39 │
│ 6   │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ Qmbb8FUJ4EBLj3nDZWowZrj... │  7708801 │ 2023-04-12 03:22:39 │
│ 7   │ bostrom1jkte0pytr85qg0w... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmbgP8xhzcYo6BY4jiFDeHQ... │  3627651 │ 2022-07-08 16:28:45 │
│ 8   │ bostrom16y344e8ryydmeu2... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmdmTTWFQ4EY7Rcs781qTZ5... │  3627694 │ 2022-07-08 16:32:54 │
│ 9   │ bostrom1d8754xqa9245pct... │ QmYkSwEwVSWW8dGWrwfsuYE... │ QmeNdaP5sgZL7RtwvQsWLcT... │  4476775 │ 2022-09-03 11:37:13 │
│ ... │ ...                        │ ...                        │ ...                        │ ...      │ ...                 │
│ 18  │ bostrom1679yrs8dmska7wc... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmWTmGZdx6JbDfU5n7418Nc... │ 12031008 │ 2024-02-05 08:14:06 │
│ 19  │ bostrom16y344e8ryydmeu2... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmaNY1eb7GNiUm6wCoKKGp3... │  3628701 │ 2022-07-08 18:09:37 │
│ 20  │ bostrom1nngr5aj3gcvphlh... │ QmaMhB3x2dM6pp3dWo4oHWv... │ Qmbdpsk6d4tqMjZJmBf4WUU... │  6638028 │ 2023-01-28 10:17:49 │
│ 21  │ bostrom1679yrs8dmska7wc... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmeBgEfMAWb6iFSsYVx2TGS... │ 11834968 │ 2024-01-22 16:39:52 │
│ 22  │ bostrom1v5x5vl4c0zjua37... │ QmaMhB3x2dM6pp3dWo4oHWv... │ QmfQdNw9ajQwNW6eA35DRS7... │  5255875 │ 2022-10-26 06:07:51 │
│ 23  │ bostrom1nngr5aj3gcvphlh... │ QmfQdNw9ajQwNW6eA35DRS7... │ QmaNY1eb7GNiUm6wCoKKGp3... │  6700597 │ 2023-02-01 16:36:31 │
│ 24  │ bostrom16y344e8ryydmeu2... │ QmZbcRTU4fdrMy2YzDKEUAX... │ QmW9i7RJnpuLLiyHFbJqhsP... │  3637974 │ 2022-07-09 09:00:44 │
│ 25  │ bostrom16y344e8ryydmeu2... │ QmVww6z5eshB4puR74xCwmN... │ QmW9i7RJnpuLLiyHFbJqhsP... │  5983204 │ 2022-12-14 16:08:26 │
│ 26  │ bostrom16y344e8ryydmeu2... │ QmZbcRTU4fdrMy2YzDKEUAX... │ QmPohTpW8TNyjbtLJM61R7T... │  3637979 │ 2022-07-09 09:01:13 │
│ 27  │ bostrom16y344e8ryydmeu2... │ QmVww6z5eshB4puR74xCwmN... │ QmPohTpW8TNyjbtLJM61R7T... │  5983239 │ 2022-12-14 16:11:51 │
╰──#──┴───────────neuron───────────┴───────particle_from────────┴────────particle_to─────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-neurons-stats | graph-keep-standard-columns-only --extra_columns [nickname links_count neuron]
╭──#──┬──────nickname──────┬─links_count─┬───────────────────────────────neuron───────────────────────────────╮
│ 0   │ mastercyb          │          24 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t                     │
│ 1   │ ?                  │          16 │ bostrom16y344e8ryydmeu2g8yyfznq79j7jfnar4p59ngpvaazcj83jzsmsts7qxt │
│ 2   │ cyberacademy       │          14 │ bostrom1679yrs8dmska7wcsawgy2m25kwucm3z0hwr74y                     │
│ 3   │ ?                  │          12 │ bostrom1jkte0pytr85qg0whmgux3vmz9ehmh82w40h8gaqeg435fnkyfxqq9qaku3 │
│ 4   │ cicada             │           8 │ bostrom1qjf43tsdhzfk5apchznuheqf6sux0wwmt4q4qq                     │
│ 5   │ ?                  │           6 │ bostrom10fqy0npt7djm8lg847v9rqlng88kqfdvl8tyt4ge204wf52sy68qlq7nz2 │
│ 6   │ jooy               │           6 │ bostrom1k7nssnnvxezpp4una7lvk6j53895vadpqe6jh6                     │
│ 7   │ maxim              │           4 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8                     │
│ 8   │ el-nivvo           │           4 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k                     │
│ 9   │ cyberdbot          │           3 │ bostrom135ca8hdpy9sk0ntwqzpzsvatyl48ptx5j359lz                     │
│ ... │ ...                │ ...         │ ...                                                                │
│ 16  │ superhuman         │           1 │ bostrom1pntx8ql2v7cqxu05etg8c4v0r2vz7qnq9uqmpy                     │
│ 17  │ ?                  │           1 │ bostrom15xx4xh3p7f773ssyz25ydrk27g09cl7qfh75mh                     │
│ 18  │ cybergudwin        │           1 │ bostrom1v5x5vl4c0zjua37ymqjy4267fy9m6x8yvzvkfp                     │
│ 19  │ elonamusk          │           1 │ bostrom19wtkh935tx2ut2n4m6tjvkfvew4shaeezfl7em                     │
│ 20  │ synthetic          │           1 │ bostrom12tdulmvjmsmpaqrpshz0emu0h9sqz5x58hv36e                     │
│ 21  │ kalpemo            │           1 │ bostrom1rj7zt2pzuzwhjlr24u0prnqqxm3xexavtpqtzx                     │
│ 22  │ mazw1010           │           1 │ bostrom13eehekx464l2qtl4xfyzggvd77nef22x82asv8                     │
│ 23  │ castigaojetes      │           1 │ bostrom1kwwp7f5pszyxr39whf2rwm7gly596mdw5gmmf4                     │
│ 24  │ laurentiu          │           1 │ bostrom1zy8knphzhf9u8xeyjc6k3eps96q48hlmj03zsk                     │
│ 25  │ digital-oppression │           1 │ bostrom1g70uv8y47s5pn07n4gtgakz278vps228r9emvt                     │
╰──#──┴──────nickname──────┴─links_count─┴───────────────────────────────neuron───────────────────────────────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-stats
╭───────────┬───────────────────╮
│ neurons   │ 26                │
│ links     │ {record 6 fields} │
│ particles │ {record 4 fields} │
╰───────────┴───────────────────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-append-related | graph-stats | table -e
╭───────────┬───────────────────────────────────╮
│ neurons   │ 26                                │
│           │ ╭─────────┬─────────────────────╮ │
│ links     │ │ links   │ 117                 │ │
│           │ │ first   │ 2021-11-06 09:12:42 │ │
│           │ │ last    │ 2024-05-21 11:41:52 │ │
│           │ │ unique  │ 117                 │ │
│           │ │ follows │ 0                   │ │
│           │ │ tweets  │ 0                   │ │
│           │ ╰─────────┴─────────────────────╯ │
│           │ ╭────────────────┬─────╮          │
│ particles │ │ unique         │ 104 │          │
│           │ │ text           │ 81  │          │
│           │ │ nontext        │ 10  │          │
│           │ │ not_downloaded │ 13  │          │
│           │ ╰────────────────┴─────╯          │
╰───────────┴───────────────────────────────────╯

> graph-links-df test-graph.csv | graph-filter-contracts | graph-to-gephi

> graph-links-df test-graph.csv | graph-filter-contracts | graph-to-cosmograph
You can upload the file to https://cosmograph.app/run
/Users/user/cy/export/cybergraph-in-cosmograph20240627-125937.csv

> graph-links-df test-graph.csv | graph-filter-contracts | graph-to-graphviz
digraph G {

"mastercyb|W4sJiUP" -> "bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t|Abm5U1N";
"master|BVe3UhW" -> "0xb2e19dd996848818d972dd3a60a1b7faffb82330|A2zEuhJ";
"el-nivvo|Ev6PRFv" -> "\"MIME type\" = \"image/jpeg\"⏎Size = 533643⏎|NKXic5Y";
"el-nivvo|Ev6PRFv" -> "bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k|w3iRrjz";
"el-nivvo|Ev6PRFv" -> "bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k|w3iRrjz";
"el-nivvo|Ev6PRFv" -> "osmo1ay267fakkrgfy9lf2m7wsj8uez2dgylhq722dr|cUFnut3";
"cyberdbot|Wm1p3DC" -> "bostrom135ca8hdpy9sk0ntwqzpzsvatyl48ptx5j359lz|q5EVnkg";
"maxim|FPcw8pT" -> "\"MIME type\" = \"image/gif\"⏎Size = 218789⏎|ULWb28j";
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

> graph-links-df test-graph.csv | graph-filter-contracts | graph-add-metadata | graph-keep-standard-columns-only --out | polars collect
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
