```nushell
> graph-links-df test-graph.csv
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
│ 1271 │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmRSyyB1TVSyJRbKCXPJVvd... │ 12570332 │ 2024-03-13 13:27:52 │
│ 1272 │ bostrom1nngr5aj3gcvphl... │ QmRSyyB1TVSyJRbKCXPJVvd... │ QmeQDBrFavhzKY6zVXPfoRK... │ 12596377 │ 2024-03-15 08:15:50 │
│ 1273 │ bostrom1nngr5aj3gcvphl... │ QmbdH2WBamyKLPE5zu4mJ9v... │ QmaViP33J9V7v2HYiXjbhH6... │ 12641050 │ 2024-03-18 09:49:09 │
│ 1274 │ bostrom1nngr5aj3gcvphl... │ QmSS1GaRdKBdkvxrbQnnW7F... │ QmaViP33J9V7v2HYiXjbhH6... │ 12641076 │ 2024-03-18 09:51:42 │
│ 1275 │ bostrom1nngr5aj3gcvphl... │ QmTto1JaBHqT354oLjqxook... │ QmWm9pmmz66cq41t1vtZWoR... │ 12641084 │ 2024-03-18 09:52:28 │
│ 1276 │ bostrom1nngr5aj3gcvphl... │ QmPLSA5oPqYxgc8F7EwrM8W... │ Qme1RyD7Jtxg8LyUKcFLURo... │ 12641093 │ 2024-03-18 09:53:21 │
│ 1277 │ bostrom1nngr5aj3gcvphl... │ QmPjz7yuUboFSV95yJXzUG8... │ QmUvxAbodisXtZDpiKpB9sZ... │ 12641123 │ 2024-03-18 09:56:20 │
│ 1278 │ bostrom1nngr5aj3gcvphl... │ QmSZmi6xpwhxb7juxw61HoT... │ QmSozQsP5FXmWYuVGkZMVEd... │ 12667642 │ 2024-03-20 05:16:12 │
│ 1279 │ bostrom1nngr5aj3gcvphl... │ QmSZmi6xpwhxb7juxw61HoT... │ QmQ8ntTiVnJxxBQSoeaAnNQ... │ 12667658 │ 2024-03-20 05:17:46 │
│ 1280 │ bostrom1nngr5aj3gcvphl... │ QmR7zZv2PNo477ixpKBVYVU... │ QmZdKqcYqYGy88QpUGZpqjm... │ 12847309 │ 2024-04-01 13:14:37 │
╰──#───┴──────────neuron───────────┴───────particle_from────────┴────────particle_to─────────┴──height──┴──────timestamp──────╯

> graph-links-df test-graph.csv | graph-to-particles | particles-keep-only-first-neuron
╭────────────────┬────────────────────────────────────────────────────────────────────────────────────────╮
│ plan           │ DF ["neuron", "particle", "height", "timestamp"]; PROJECT */5 COLUMNS; SELECTION: None │
│ optimized_plan │ DF ["neuron", "particle", "height", "timestamp"]; PROJECT */5 COLUMNS; SELECTION: None │
╰────────────────┴────────────────────────────────────────────────────────────────────────────────────────╯
```
