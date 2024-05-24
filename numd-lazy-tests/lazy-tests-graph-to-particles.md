```nushell
> graph-links-df test-graph.csv | graph-to-particles | polars first 3 | polars collect
╭─#─┬─────────────────────neuron─────────────────────┬────────────────────particle────────────────────┬─height─┬──────timestamp──────┬─init-role─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │   9029 │ 2021-11-06 03:52:13 │ from      │
│ 1 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │   9029 │ 2021-11-06 03:52:13 │ to        │
│ 2 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │  12863 │ 2021-11-06 09:59:22 │ from      │
╰─#─┴─────────────────────neuron─────────────────────┴────────────────────particle────────────────────┴─height─┴──────timestamp──────┴─init-role─╯

> graph-links-df test-graph.csv | graph-to-particles --cids_only  | polars first 3 | polars collect
╭─#─┬────────────────────particle────────────────────╮
│ 0 │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │
│ 1 │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │
│ 2 │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │
╰─#─┴────────────────────particle────────────────────╯

> graph-links-df test-graph.csv | graph-to-particles --from | polars first 3 | polars collect
╭─#─┬─────────────────────neuron─────────────────────┬────────────────────particle────────────────────┬─height─┬──────timestamp──────┬─init-role─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │   9029 │ 2021-11-06 03:52:13 │ from      │
│ 1 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │  12863 │ 2021-11-06 09:59:22 │ from      │
│ 2 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │  12869 │ 2021-11-06 09:59:57 │ from      │
╰─#─┴─────────────────────neuron─────────────────────┴────────────────────particle────────────────────┴─height─┴──────timestamp──────┴─init-role─╯

> graph-links-df test-graph.csv | graph-to-particles --to | polars first 3 | polars collect
╭─#─┬─────────────────────neuron─────────────────────┬────────────────────particle────────────────────┬─height─┬──────timestamp──────┬─init-role─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │   9029 │ 2021-11-06 03:52:13 │ to        │
│ 1 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmY4X4SkVBkoUGZdTzdcW7SKY8t4ULj5GJBRcRr4UMyahp │  12863 │ 2021-11-06 09:59:22 │ to        │
│ 2 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRBxwqwNhLUjnsKwm8giYNVv4wwa77XUk51bYoo67tbah │  15287 │ 2021-11-06 13:52:52 │ to        │
╰─#─┴─────────────────────neuron─────────────────────┴────────────────────particle────────────────────┴─height─┴──────timestamp──────┴─init-role─╯

> graph-links-df test-graph.csv | graph-to-particles --include_global  | polars first 3 | polars collect
╭─#─┬─────────────────────neuron─────────────────────┬────────────────────particle────────────────────┬─height──┬──────timestamp──────┬─init-role─┬─────────────────neuron_global──────────────────┬─height_global─┬──timestamp_global───┬────content_s────╮
│ 0 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │   12869 │ 2021-11-06 09:59:57 │ from      │ bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt │           490 │ 2021-11-05T14:11:41 │ cyber|QK3oufV   │
│ 1 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmVmq6QRfTykfY8YaUqjLSYEhRRXSFC9z9qmS5DHS9WqZC │ 5995169 │ 2022-12-15 11:41:31 │ from      │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │           701 │ 2021-11-05 14:32:19 │ genesis|HS9WqZC │
│ 2 │ bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │   87794 │ 2021-11-11 10:36:24 │ from      │ bostrom1hmkqhy8ygl6tnl5g8tc503rwrmmrkjcq3lduwj │           794 │ 2021-11-05 14:41:28 │ tweet|R5V4Rvx   │
╰─#─┴─────────────────────neuron─────────────────────┴────────────────────particle────────────────────┴─height──┴──────timestamp──────┴─init-role─┴─────────────────neuron_global──────────────────┴─height_global─┴──timestamp_global───┴────content_s────╯

> graph-links-df test-graph.csv | graph-to-particles --include_particle_index   | polars first 3 | polars collect
╭─#─┬─────────────────────neuron─────────────────────┬────────────────────particle────────────────────┬─height─┬──────timestamp──────┬─init-role─┬─particle_index─╮
│ 0 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmPcfxEfW317u3bbz8MbEhjoMZ5HMFsx5TbsEHWPd1kLLw │   9029 │ 2021-11-06 03:52:13 │ from      │              0 │
│ 1 │ bostrom1ay267fakkrgfy9lf2m7wsj8uez2dgylhtkdf9k │ QmXQ4k4ciK5ieaSwtccmH9mm4QdPS6Spd21DTqLFrEwDWR │   9029 │ 2021-11-06 03:52:13 │ to        │              1 │
│ 2 │ bostrom1d8754xqa9245pctlfcyv8eah468neqzn3a0y0t │ QmYrXCXqunhqqirz3LBmvbnQb2pFFCk7douQkHDPDvQ3iE │  12863 │ 2021-11-06 09:59:22 │ from      │              2 │
╰─#─┴─────────────────────neuron─────────────────────┴────────────────────particle────────────────────┴─height─┴──────timestamp──────┴─init-role─┴─particle_index─╯
```
