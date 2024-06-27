```nushell
> graph-links-df test-graph.csv | graph-to-particles | polars first 3
╭─#─┬────────────────neuron────────────────┬───────────────particle────────────────┬─height─┬──────timestamp──────┬─init-role─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2m7wsj8ue... │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5T... │   9029 │ 2021-11-06 03:52:13 │ from      │
│ 1 │ bostrom1ay267fakkrgfy9lf2m7wsj8ue... │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd2... │   9029 │ 2021-11-06 03:52:13 │ to        │
│ 2 │ bostrom1d8754xqa9245pctlfcyv8eah4... │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7do... │  12863 │ 2021-11-06 09:59:22 │ from      │
╰─#─┴────────────────neuron────────────────┴───────────────particle────────────────┴─height─┴──────timestamp──────┴─init-role─╯

> graph-links-df test-graph.csv | graph-to-particles --cids_only  | polars first 3
╭─#─┬────────────────────particle────────────────────╮
│ 0 │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │
│ 1 │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │
│ 2 │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │
╰─#─┴────────────────────particle────────────────────╯

> graph-links-df test-graph.csv | graph-to-particles --from | polars first 3
╭─#─┬────────────────neuron────────────────┬───────────────particle────────────────┬─height─┬──────timestamp──────┬─init-role─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2m7wsj8ue... │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5T... │   9029 │ 2021-11-06 03:52:13 │ from      │
│ 1 │ bostrom1d8754xqa9245pctlfcyv8eah4... │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7do... │  12863 │ 2021-11-06 09:59:22 │ from      │
│ 2 │ bostrom1d8754xqa9245pctlfcyv8eah4... │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVX... │  12869 │ 2021-11-06 09:59:57 │ from      │
╰─#─┴────────────────neuron────────────────┴───────────────particle────────────────┴─height─┴──────timestamp──────┴─init-role─╯

> graph-links-df test-graph.csv | graph-to-particles --to | polars first 3
╭─#─┬────────────────neuron────────────────┬───────────────particle────────────────┬─height─┬──────timestamp──────┬─init-role─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2m7wsj8ue... │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd2... │   9029 │ 2021-11-06 03:52:13 │ to        │
│ 1 │ bostrom1d8754xqa9245pctlfcyv8eah4... │ QmY4X4SkVBkoUGZdTzdcW7SKY8t4ULj5GJ... │  12863 │ 2021-11-06 09:59:22 │ to        │
│ 2 │ bostrom1d8754xqa9245pctlfcyv8eah4... │ QmRBxwqwNhLUjnsKwm8giYNVv4wwa77XUk... │  15287 │ 2021-11-06 13:52:52 │ to        │
╰─#─┴────────────────neuron────────────────┴───────────────particle────────────────┴─height─┴──────timestamp──────┴─init-role─╯

> graph-links-df test-graph.csv | graph-to-particles --include_global  | polars first 3
╭─#─┬───neuron────┬──particle───┬─height──┬──timestamp──┬─init-role─┬─neuron_g...─┬─height_g...─┬─timestamp...─┬──content_s───╮
│ 0 │ bostrom1... │ QmVmq6QR... │ 5995169 │ 2022-12-... │ from      │ bostrom1... │         701 │ 2021-11-0... │ genesis|H... │
│ 1 │ bostrom1... │ QmbdH2WB... │   87794 │ 2021-11-... │ from      │ bostrom1... │         794 │ 2021-11-0... │ tweet|R5V... │
│ 2 │ bostrom1... │ QmRX8qYg... │   12869 │ 2021-11-... │ from      │ bostrom1... │        1052 │ 2021-11-0... │ cyber|QK3... │
╰─#─┴───neuron────┴──particle───┴─height──┴──timestamp──┴─init-role─┴─neuron_g...─┴─height_g...─┴─timestamp...─┴──content_s───╯

> graph-links-df test-graph.csv | graph-to-particles --include_particle_index   | polars first 3
╭─#─┬────────────neuron────────────┬───────────particle───────────┬─height─┬──────timestamp──────┬─init-role─┬─particle_index─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2... │ QmPcfxEfW317u3bbz8MbEhjoM... │   9029 │ 2021-11-06 03:52:13 │ from      │              0 │
│ 1 │ bostrom1ay267fakkrgfy9lf2... │ QmXQ4k4ciK5ieaSwtccmH9mm4... │   9029 │ 2021-11-06 03:52:13 │ to        │              1 │
│ 2 │ bostrom1d8754xqa9245pctlf... │ QmYrXCXqunhqqirz3LBmvbnQb... │  12863 │ 2021-11-06 09:59:22 │ from      │              2 │
╰─#─┴────────────neuron────────────┴───────────particle───────────┴─height─┴──────timestamp──────┴─init-role─┴─particle_index─╯
```
