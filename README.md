# Cy💎

Cy - a [Nushell](https://www.nushell.sh/) wrapper for `cyber`, `ipfs` and other CLIs for interacting with Cybergraphs.

## Status

Very much WIP. Actively developed.

## Key features of Cy

- Different settings for different profiles (RPC endpoints, private keys, networks, etc.)
- Seamlessly upload and download data to a Cybernode or to a local IPFS node
- Create multiple cyberlinks and publish them simoltaneously
- Export Cybergraphs to formats of Cosmograph, Gephi, Graphviz
- Shortcuts for interacting with the Bostrom's passport smart contract
- Cyber search in terminal
- Many more (see list of functions below)

## Installation

### Quick start

If you have `nushell`, `git` and `cyber` CLI-s installed:

```nushell
git clone https://github.com/cyber-prophet/cy; cd cy;
overlay use -pr cy/
```

### Install all the necessary apps using homebrew (Mac, Linux)

Open Terminal app on your computer.

1. Install [brew](https://brew.sh/)
2. Add a custom tap to your Homebrew, install all the dependencies for running Cy:

```sh
brew tap cyber-prophet/homebrew-taps; brew install cybundle; cybundle
```

3. The commands above will install the following software on your computer if it is not installed yet:

   1. [cybundle script](https://github.com/cyber-prophet/homebrew-taps/blob/main/src/cybundle)
   1. [nushell](https://www.nushell.sh/) app
   1. [rustup](https://github.com/rust-lang/rustup): the Rust toolchain installer (needed for installation of `nu_plugin_polars`)
   1. [curl](https://curl.se/) (optional)
   1. [cyber](https://github.com/cybercongress/go-cyber) (optional)
   1. [pussy](https://github.com/greatweb/space-pussy) (optional)
   1. [kubo](https://github.com/ipfs/kubo): ipfs cli (optional)
   1. [mdcat](https://github.com/swsnr/mdcat): markdown viewer (optional)

After installation, you can launch `nu` in your terminal with already configured `cy` in it.

## First steps using Cy

To start using Cy, follow the instructions on your screen. They should include:

0. Add a key to your `cyber` cli (`cyber keys add 'test'`)
1. Go through the wizard `cy config-new`.
2. See all the commands in logical order by executing `cy`.
3. See all the commands suggestions by entering `cy` + tab.

## Installation (Windows)

Windows supports WSL2. Install it first: https://learn.microsoft.com/en-us/windows/wsl/install.
By default, it should install Ubuntu on your computer. And when Ubuntu is installed and launched,
proceed with the steps described in the [section of installation for MacOS and Linux](#installation-mac-linux)
of this manual.

## Cyber-family blockchains

Bostrom is the name of the consensus computer that maintains a general-purpose, permissionless informational graph where nodes are CIDs of files in the IPFS network, and edges are Cyberlinks (consisting of source, destination, author, height - records) written into the blockchain. The information written into the blockchain is secured to remain in existence as long as the blockchain is operative. The blockchain is designed with economic incentives that motivate validators to sustain the network. For further information about Cyber blockchains, please refer to [Bostrom Journal.](https://github.com/cyber-prophet/bostrom-journal/blob/manual/BostromJournal001.md)

## References to the documentation of Cy

I intend to locate all the documentation of Cy in one place to prevent fragmentation of attention.

1. In the comments to its code (`.nu` files of this repository, mainly in [cy.nu](https://github.com/cyber-prophet/cy/blob/dev/cy.nu)).
2. From the code, the documentation is semi-automatically parsed and written to `.md` documents of this repository (mainly to [README.md](https://github.com/cyber-prophet/cy/blob/dev/README.md)).

The main feedback resource is GitHub [issues](https://github.com/cyber-prophet/cy/issues).


## Commands

### cy pin-text

```
  Pin a text particle

Usage:
  > pin-text {flags} (text_param)

  > cy pin-text 'cyber'
  QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

  > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt'
  QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

  > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt' --follow_file_path
  QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6

  > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
  QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

  > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --dont_detect_cid
  QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F

Flags:
  --only_hash - calculate hash only, don't pin anywhere
  --dont_detect_cid - work with CIDs as regular texts
  --follow_file_path - check if `text_param` is a valid path, and if yes - try to open it
  --dont_save_particle_in_cache - don't save particle to local cache in cid.md file

Parameters:
  text_param <string>:  (optional)

Input/output types:
  ╭──input──┬─output─╮
  │ string  │ string │
  │ nothing │ string │
  ╰─────────┴────────╯

```

### cy link-texts

```
  Add a 2-texts cyberlink to the temp table

Usage:
  > link-texts {flags} <text_from> <text_to>

  > cy link-texts 'cyber' 'cyber-prophet' --disable_append | to yaml
  from_text: cyber
  to_text: cyber-prophet
  from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
  to: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD

Flags:
  -D, --disable_append - Disable adding the cyberlink into the temp table
  -q, --quiet - Don't output a cyberlink record after executing the command
  --only_hash - calculate hash only, don't pin anywhere
  --dont_detect_cid - work with CIDs as regular texts
  --follow_file_path - check if `text_param` is a valid path, and if yes - try to open it

Parameters:
  text_from <string>:
  text_to <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy link-chain

```
  Add a link chain to the temp table

Usage:
  > link-chain ...(rest)

  > cy link-chain "a" "b" "c" | to yaml
  - from_text: a
    to_text: b
    from: QmfDmsHTywy6L9Ne5RXsj5YumDedfBLMvCvmaxjBoe6w4d
    to: QmQLd9KEkw5eLKfr9VwfthiWbuqa9LXhRchWqD4kRPPWEf
  - from_text: b
    to_text: c
    from: QmQLd9KEkw5eLKfr9VwfthiWbuqa9LXhRchWqD4kRPPWEf
    to: QmS4ejbuxt7JvN3oYyX85yVfsgRHMPrVzgxukXMvToK5td

Parameters:
  ...rest <string>: consecutive particles to cyberlink in a linkchain

Input/output types:
  ╭───input───┬output─╮
  │ nothing   │ table │
  │ list<any> │ table │
  ╰───────────┴───────╯

```

### cy link-files

```
  Pin files from the current folder to the local node and append their cyberlinks to the temp table

Usage:
  > link-files {flags} ...(files)

  > mkdir linkfilestest; cd linkfilestest
  > 'cyber' | save cyber.txt; 'bostrom' | save bostrom.txt
  > cy link-files --link_filenames --yes | to yaml
  - from_text: bostrom.txt
    to_text: pinned_file:bostrom.txt
    from: QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k
    to: QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb
  - from_text: cyber.txt
    to_text: pinned_file:cyber.txt
    from: QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
    to: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
  > cd ..; rm -r linkfilestest

Flags:
  -n, --link_filenames - Add filenames as a `from` link
  --include_extension - Include a file extension (works only with `--link_filenames`)
  -D, --disable_append - Don't append links to the links table
  --quiet - Don't output results page
  -y, --yes - Confirm uploading files without request

Parameters:
  ...files <path>: filenames of files to pin to the local ipfs node

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ table   │
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy follow

```
  Create a cyberlink according to semantic construction of following a neuron

Usage:
  > follow {flags} <neuron>

  > cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
  from_text: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
  to_text: bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
  from: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
  to: QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af

Flags:
  --use_local_list_only - follow a neuron locally only

Parameters:
  neuron <string>: neuron's address to follow

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  ╰─────────┴────────╯

```

### cy tweet

```
  Add a tweet and send it immediately (unless of disable_send flag)

Usage:
  > tweet {flags} <text_to>

  > cy links-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
  from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
  to_text: cyber-prophet is cool
  from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
  to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK

Flags:
  -D, --disable_send - don't send tweet immediately, but put it into the temp table

Parameters:
  text_to <string>: text to tweet

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  ╰─────────┴────────╯

```

### cy link-random

```
  Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)

Usage:
  > link-random {flags} (n)

  > cy link-random
  ==========================================================
  Chuck Norris IS Lukes father.

  via [Chucknorris.io](https://chucknorris.io)
  ==========================================================

  > cy link-random forismatic.com
  ==========================================================
  He who knows himself is enlightened.   (Lao Tzu )

  via [forismatic.com](https://forismatic.com)
  ==========================================================

Flags:
  --source choose the source to take random links from (default: 'forismatic.com')

Parameters:
  n <int>: Number of links to append (optional, default: 1)

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy links-view

```
  View the temp cyberlinks table

Usage:
  > links-view {flags}

  > cy links-view | to yaml
  There are 2 cyberlinks in the temp table:
  - from_text: chuck norris
    to_text: |-
      Chuck Norris IS Lukes father.

      via [Chucknorris.io](https://chucknorris.io)
    from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
    to: QmSLPzbM5NVmXuYCPiLZiePAhUcDCQncYUWDLs7GkLqC7J
    timestamp: 20230701-134134
  - from_text: quote
    to_text: |-
      He who knows himself is enlightened. (Lao Tzu )

      via [forismatic.com](https://forismatic.com)
    from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
    to: QmWoxYsWYuTP4E2xaQHr3gUZZTBC7HdNDVhis1BK9X3qjX
    timestamp: 20230702-113842

Flags:
  -q, --quiet - Disable informational messages
  --no_timestamp - Don't output a timestamps column

Input/output types:
  ╭──input──┬output─╮
  │ nothing │ table │
  ╰─────────┴───────╯

```

### cy links-append

```
  Append piped-in table to the temp cyberlinks table

Usage:
  > links-append {flags}

Flags:
  -q, --quiet - suppress output the resulted temp links table

Input/output types:
  ╭─input──┬─output──╮
  │ table  │ table   │
  │ table  │ nothing │
  │ record │ table   │
  │ record │ nothing │
  ╰────────┴─────────╯

```

### cy links-replace

```
  Replace the temp table with piped-in table

Usage:
  > links-replace {flags}

Flags:
  -q, --quiet - suppress output the resulted temp links table

Input/output types:
  ╭─input─┬─output──╮
  │ table │ table   │
  │ table │ nothing │
  ╰───────┴─────────╯

```

### cy links-swap-from-to

```
  Swap columns from and to

Usage:
  > links-swap-from-to {flags}

Flags:
  -D, --dont_replace - output results only, without modifying the links table
  --keep_original - append results to original links

Input/output types:
  ╭──input──┬output─╮
  │ nothing │ table │
  │ table   │ table │
  ╰─────────┴───────╯

```

### cy links-clear

```
  Empty the temp cyberlinks table

Usage:
  > links-clear

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy links-link-all

```
  Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table

Usage:
  > links-link-all {flags} <text>

  > [[from_text, to_text]; ['cyber-prophet' null] ['tweet' 'cy is cool!']]
  | cy links-pin-columns | cy links-link-all 'master' --column 'to' --empty | to yaml
  - from_text: cyber-prophet
    to_text: master
    from: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
    to: QmZbcRTU4fdrMy2YzDKEUAXezF3pRDmFSMXbXYABVe3UhW
  - from_text: tweet
    to_text: cy is cool!
    from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
    to: QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8

Flags:
  -D, --dont_replace - don't replace the temp cyberlinks table, just output results
  --keep_original - append results to original links
  -c, --column <String> - a column to use for values ('from' or 'to'). 'from' is default (default: 'from')
  --empty - fill cids in empty cells only

Parameters:
  text <string>: a text to upload to ipfs

Input/output types:
  ╭──input──┬output─╮
  │ nothing │ table │
  │ table   │ table │
  ╰─────────┴───────╯

```

### cy links-pin-columns

```
  Pin values from column 'text_from' and 'text_to' to an IPFS node and fill according columns with their CIDs

Usage:
  > links-pin-columns {flags}

  > [{from_text: 'cyber' to_text: 'cyber-prophet'} {from_text: 'tweet' to_text: 'cy is cool!'}]
  | cy links-pin-columns | to yaml
  - from_text: cyber
    to_text: cyber-prophet
    from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
    to: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
  - from_text: tweet
    to_text: cy is cool!
    from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
    to: QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8

Flags:
  -D, --dont_replace - Don't replace the links cyberlinks table
  --threads <Int> - A number of threads to use to pin particles (default: 3)

Input/output types:
  ╭──input──┬output─╮
  │ nothing │ table │
  │ table   │ table │
  ╰─────────┴───────╯

```

### cy links-pin-columns-2

```
Usage:
  > links-pin-columns-2 {flags}

Flags:
  -D, --dont_replace - Don't replace the links cyberlinks table
  --pin_to_local_ipfs - Pin to local kubo
  --dont_detect_cid - work with CIDs as regular texts
  --dont_save_particle_in_cache - don't save particles to local cache in cid.md file

Input/output types:
  ╭──input──┬output─╮
  │ nothing │ table │
  │ table   │ table │
  ╰─────────┴───────╯

```

### cy pin-file-or-folder-to-cybernode

```
Usage:
  > pin-file-or-folder-to-cybernode <$path>

Parameters:
  $path <path>: the path to a folder or a file to pin

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-remove-existed-1by1

```
  Remove existing cyberlinks from the temp cyberlinks table

Usage:
  > links-remove-existed-1by1 {flags}

Flags:
  --all_links - check all links in the temp table

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ table   │
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy links-remove-existed-2

```
  Remove existing links using graph snapshot data

Usage:
  > links-remove-existed-2

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-publish

```
  Publish all links from the temp table to cybergraph

Usage:
  > links-publish {flags}

Flags:
  --links_per_trans <Int>

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tsv-copy

```
  Copy a table from the pipe into the clipboard (in tsv format)

Usage:
  > tsv-copy

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tsv-paste

```
  Paste a table from the clipboard to stdin (so it can be piped further)

Usage:
  > tsv-paste

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy update-cy

```
  Update Cy and Nushell to the latest versions

Usage:
  > update-cy {flags}

Flags:
  --branch the branch to get updates from (default: 'dev')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy passport-get

```
  Get a passport by providing a neuron's address or nick

Usage:
  > passport-get {flags} <address_or_nick>

  > cy passport-get cyber-prophet | to yaml
  owner: bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
  addresses:
  - label: null
    address: cosmos1sgy27lctdrc5egpvc8f02rgzml6hmmvhhagfc3
  avatar: Qmdwi54WNiu1phvMA2digYHRzQRHRkS1pKWAnpawjSWUZi
  nickname: cyber-prophet
  data: null
  particle: QmRumrGFrqxayDpySEkhjZS1WEtMyJcfXiqeVsngqig3ak

Flags:
  --quiet

Parameters:
  address_or_nick <string>: Name of passport or neuron's address

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy passport-set

```
  Set a passport's particle, data or avatar field for a given nickname

Usage:
  > passport-set {flags} <cid> (nickname)

  > cy passport-set QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
  The particle field for maxim should be successfully set to QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd

Flags:
  --field <String> - A passport's field to set: particle, data, new_avatar (default: 'particle')
  --verbose - Show the node's response

Parameters:
  cid <string>: cid to set
  nickname <any>: Provide a passport's nickname. If null - the nick from config will be used. (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy dict-neurons-view

```
  Output neurons dict

Usage:
  > dict-neurons-view {flags}

Flags:
  --df - output as a dataframe
  --path - output path of the dict
  --karma_bar - output karma bar

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy dict-neurons-add

```
  Add piped in neurons to YAML-dictionary with tag and category

Usage:
  > dict-neurons-add {flags} (tag)

Flags:
  --category <String> - category of tag to write to dict (default: 'default')

Parameters:
  tag <string>: tag to add to neuron (optional, default: '')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy dict-neurons-tags

```
  Output dict-neurons tags

Usage:
  > dict-neurons-tags {flags}

Flags:
  --path - return the path of tags file
  --wide - return wide table with categories as columns
  --timestamp - output the timestamp of the last neuron's update

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy doctor

```
  Fix some problems of cy (for example caused by updates)

Usage:
  > doctor

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy dict-neurons-update

```
  Update neurons YAML-dictionary

Usage:
  > dict-neurons-update {flags}

Flags:
  --passport - Update passport data
  --balance - Update balances data
  --karma - Update karma
  -a, --all - Update passport, balance, karma
  --neurons_from_graph - Update info for neurons from graph, and not from current dict
  -t, --threads <Int> - Number of threads to use for downloading (default: 30)
  --dont_save - Don't update the file on a disk, just output the results
  -q, --quiet - Don't output results table

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-download-snapshot

```
  Download a snapshot of cybergraph

Usage:
  > graph-download-snapshot {flags}

Flags:
  -D, --disable_update_parquet - Don't update the particles parquet file
  --neuron <String> -  (default: 'graphkeeper')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-receive-new-links

```
  Download the latest cyberlinks from a hasura cybernode endpoint

Usage:
  > graph-receive-new-links {flags} (filename)

Flags:
  --source (default: 'hasura')

Parameters:
  filename <string>: graph csv filename in the 'cy/graph' folder (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-download-missing-particles

```
  download particles missing from local cache for followed neurons or the whole graph

Usage:
  > graph-download-missing-particles {flags}

Flags:
  --dont_update_parquet
  --whole_graph - download particles for whole graph

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-filter-system-particles

```
  filter system particles out

Usage:
  > graph-filter-system-particles {flags} (column)

Flags:
  --exclude

Parameters:
  column <string>: the column to look for system cids (optional, default: 'particle')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-merge

```
  merge two graphs together, add the `source` column

Usage:
  > graph-merge {flags} <df2>

Flags:
  --source_a <String> -  (default: 'a')
  --source_b <String> -  (default: 'b')

Parameters:
  df2 <any>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-to-particles

```
  Output unique list of particles from piped in cyberlinks table

Usage:
  > graph-to-particles {flags}

  > cy graph-to-particles --include_global | dfr into-nu | first 2 | to yaml
  - index: 0
    particle: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
    neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
    height: 490
    timestamp: 2021-11-05
    nick: mrbro_bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
    particle_index: 0
    size: 5
    content_s: cyber
  - index: 1
    particle: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
    neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
    height: 490
    timestamp: 2021-11-05
    nick: mrbro_bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
    particle_index: 1
    size: 11
    content_s: fuckgoogle!

Flags:
  --from - Use only particles from the 'from' column
  --to - Use only particles from the 'to' column
  --include_global - Include column with global particles' df (that includes content)
  --include_particle_index - Include local 'particle_index' column
  -c, --cids_only - Output one column with CIDs only
--init_role # Output if particle originally was in 'from' or 'to' column

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy particles-keep-only-first-neuron

```
  In the piped in particles df leave only particles appeared for the first time

Usage:
  > particles-keep-only-first-neuron

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-update-particles-parquet

```
  Update the 'particles.parquet' file (it includes content of text files)

Usage:
  > graph-update-particles-parquet {flags}

Flags:
  -q, --quiet - Disable informational messages about the saved parquet file
  --all - re-read all downloaded particles

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-filter-neurons

```
  Filter the graph to chosen neurons only

Usage:
  > graph-filter-neurons ...(neurons_nicks)

Parameters:
  ...neurons_nicks <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-filter-contracts

```
  Filter the graph to keep or exclude links from contracts

Usage:
  > graph-filter-contracts {flags}

Flags:
  --exclude

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-append-related

```
  Append related cyberlinks to the piped in graph

Usage:
  > graph-append-related {flags}

Flags:
  -o, --only_first_neuron

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-neurons-stats

```
  Output neurons stats based on piped in or the whole graph

Usage:
  > graph-neurons-stats

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-stats

```
  Output graph stats based on piped in or the whole graph

Usage:
  > graph-stats

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-to-gephi

```
  Export a graph into CSV file for import to Gephi

Usage:
  > graph-to-gephi

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-to-logseq

```
  Logseq export WIP

Usage:
  > graph-to-logseq

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-to-txt-feed

```
  Output particles into txt formatted feed

Usage:
  > graph-to-txt-feed

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-to-cosmograph

```
  Export piped-in graph to a CSV file in cosmograph format

Usage:
  > graph-to-cosmograph

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-to-graphviz

```
  Export piped-in graph into graphviz format

Usage:
  > graph-to-graphviz {flags}

Flags:
  --options <String> -  (default: '')
  --preset (default: '')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-add-metadata

```
  Add content_s and neuron's nicknames columns to piped in or the whole graph df

Usage:
  > graph-add-metadata {flags}

  > cy graph-filter-neurons maxim_bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
  | cy graph-add-metadata | dfr into-nu | first 2 | to yaml
  - index: 0
    neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
    particle_from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
    particle_to: QmaxuSoSUkgKBGBJkT2Ypk9zWdXor89JEmaeEB66wZUHYo
    height: 87794
    timestamp: 2021-11-11
    content_s_from: tweet
    content_s_to: '"MIME type" = "image/svg+xml"'
    nick: maxim_bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
  - index: 1
    neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
    particle_from: Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs
    particle_to: QmYnLm5MFGFwcoXo65XpUyCEKX4yV7HbCAZiDZR95aKr4t
    height: 88371
    timestamp: 2021-11-11
    content_s_from: avatar
    content_s_to: '"MIME type" = "image/svg+xml"'
    nick: maxim_bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8

Flags:
  --escape-quotes

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-links-df

```
  Output a full graph, or pass piped in graph further

Usage:
  > graph-links-df {flags} (filename)

  > cy graph-links-df | dfr into-nu | first 1 | to yaml
  - index: 0
    particle_from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
    particle_to: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
    neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
    height: 490
    timestamp: 2021-11-05

Flags:
  --not_in - don't catch pipe in
  --exclude_system - exclude system particles in from column (tweet, follow, avatar)

Parameters:
  filename <string>: graph csv filename in the 'cy/graph' folder or a path to the graph (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-particles-df

```
Usage:
  > graph-particles-df

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy particles-filter-by-type

```
Usage:
  > particles-filter-by-type {flags}

Flags:
  --exclude
  --media
  --timeout

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy config-new

```
  Create a config JSON to set env variables, to use them as parameters in cyber cli

Usage:
  > config-new

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy config-view

```
  View a saved JSON config file

Usage:
  > config-view (config_name)

Parameters:
  config_name <string>: --quiet (-q) (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy config-save

```
  Save the piped-in JSON into config file

Usage:
  > config-save {flags} <config_name>

Flags:
  --inactive - Don't activate current config

Parameters:
  config_name <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy config-activate

```
  Activate the config JSON

Usage:
  > config-activate (config_name)

Parameters:
  config_name <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy search-walk

```
Usage:
  > search-walk {flags} <query>

Flags:
  --results_per_page <Int> -  (default: 100)
  --duration <Duration> -  (default: 2min)

Parameters:
  query <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy search

```
  Use the built-in node search function in cyber or pussy

Usage:
  > search {flags} <query>

Flags:
  -p, --page <Int> -  (default: 0)
  -r, --results_per_page <Int> -  (default: 10)
  --search_type (default: 'search-with-backlinks')

Parameters:
  query <any>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy cid-get-type-gateway

```
  Obtain cid info

Usage:
  > cid-get-type-gateway {flags} <cid>

  > cy cid-get-type-gateway QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV | to yaml
  type: text/plain; charset=utf-8
  size: '5'

Flags:
  --gate_url <String> -  (default: 'https://gateway.ipfs.cybernode.ai/ipfs/')
  --to_csv

Parameters:
  cid <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy log_row_csv

```
Usage:
  > log_row_csv {flags}

Flags:
  --cid <String> -  (default: '')
  --source <String> -  (default: '')
  --type <String> -  (default: '')
  --size <String> -  (default: '')
  --status <String> -  (default: '')
  --file <Filepath> -  (default: '')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy cid-read-or-download

```
  Read a CID from the cache, and if the CID is absent - add it into the queue

Usage:
  > cid-read-or-download {flags} <cid>

Flags:
  --full - output full text of a particle

Parameters:
  cid <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy cid-download-async

```
  Add a cid into queue to download asynchronously

Usage:
  > cid-download-async {flags} <cid>

Flags:
  -f, --force
  --source <String> - kubo or gateway
  --info_only - Don't download the file by write a card with filetype and size
  --folder <String>

Parameters:
  cid <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy cid-download

```
  Download cid immediately and mark it in the queue

Usage:
  > cid-download {flags} <cid>

Flags:
  --source <String> - kubo or gateway
  --info_only - Generates a card with the specified filetype and size instead of downloading the file
  --folder <Filepath> - Folder path to save the file

Parameters:
  cid <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy queue-cid-add

```
  Add a CID to the download queue

Usage:
  > queue-cid-add <cid> (symbol)

Parameters:
  cid <string>:
  symbol <string>:  (optional, default: '')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy watch-search-folder

```
  Watch the queue folder, and if there are updates, request files to download

Usage:
  > watch-search-folder

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy queue-cids-download

```
  Check the queue for the new CIDs, and if there are any, safely download the text ones

Usage:
  > queue-cids-download {flags} (attempts)

Flags:
  --info - don't download data, just check queue
  --quiet - Disable informational messagesrmation
  --threads <Int> - a number of threads to use for downloading (default: 15)
  --cids_in_run <Int> - a number of files to download in one command run. 0 - means all (default) (default: 0)

Parameters:
  attempts <int>: limit a number of previous download attempts for cids in queue (optional, default: 0)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy cache-clean-cids-queue

```
  remove from queue CIDs with many attempts

Usage:
  > cache-clean-cids-queue (attempts)

Parameters:
  attempts <int>: limit a number of previous download attempts for cids in queue (optional, default: 15)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy cache-clear

```
  Clear the cache folder

Usage:
  > cache-clear

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy query-current-height

```
  Get a current height for the active network in config

Usage:
  > query-current-height (exec)

  > cy query-current-height | to yaml
  height: '9010895'
  time: 2023-07-11T11:37:40.708298734Z
  chain_id: bostrom

Parameters:
  exec <string>: executable to use for the query (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy query-rank-karma

```
  Get a karma metric for a given neuron

Usage:
  > query-rank-karma (neuron)

  > cy query-rank-karma bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | to yaml
  karma: 852564186396

Parameters:
  neuron <string>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-balance-get

```
  Get a balance for a given account

Usage:
  > tokens-balance-get {flags} (neuron)

  > cy tokens-balance-get bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
  - denom: boot
    amount: 348358
  - denom: hydrogen
    amount: 486000000
  - denom: milliampere
    amount: 25008
  - denom: millivolt
    amount: 7023

Flags:
  --height <Int> - a height to request a state on (default: 0)
  --record - output the results as a record

Parameters:
  neuron <string>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-supply-get

```
  Get supply of all tokens in a network

Usage:
  > tokens-supply-get {flags}

  > tokens-supply-get | select boot hydrogen milliampere | to yaml
  boot: 1187478088996451
  hydrogen: 320740400170941
  milliampere: 9760366733

Flags:
  --height <Int> - a height to request a state on (default: 0)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-pools-table-get

```
Usage:
  > tokens-pools-table-get {flags}

Flags:
  --height <Int> - a height to request a state on (default: 0)
  --short - get only basic information

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-pools-convert-value

```
Usage:
  > tokens-pools-convert-value {flags}

Flags:
  --height <Int> - a height to request a state on (default: 0)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-delegations-table-get

```
Usage:
  > tokens-delegations-table-get {flags} (address)

Flags:
  --height <Int> - a height to request a state on (default: 0)
  --sum

Parameters:
  address <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-rewards-get

```
Usage:
  > tokens-rewards-get {flags} (neuron)

Flags:
  --height <Int> - a height to request a state on (default: 0)
  --sum

Parameters:
  neuron <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-investmint-status-table

```
Usage:
  > tokens-investmint-status-table {flags} (neuron)

Flags:
  --h_liquid - return amount of liquid H
  --quiet - don't print amount of H liquid
  --height <Int> - a height to request a state on (default: 0)
  --sum

Parameters:
  neuron <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-routed-from

```
Usage:
  > tokens-routed-from {flags} (neuron)

Flags:
  --height <Int> - a height to request a state on (default: 0)

Parameters:
  neuron <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-routed-to

```
Usage:
  > tokens-routed-to {flags} (neuron)

Flags:
  --height <Int> - a height to request a state on (default: 0)

Parameters:
  neuron <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-ibc-denoms-table

```
  Check IBC denoms

Usage:
  > tokens-ibc-denoms-table {flags}

  > cy tokens-ibc-denoms-table | first 2 | to yaml
  - path: transfer/channel-2
    base_denom: uosmo
    denom: ibc/13B2C536BB057AC79D5616B8EA1B9540EC1F2170718CAFF6F0083C966FFFED0B
    amount: '59014043327'
  - path: transfer/channel-2/transfer/channel-0
    base_denom: uatom
    denom: ibc/5F78C42BCC76287AE6B3185C6C1455DFFF8D805B1847F94B9B625384B93885C7
    amount: '150000'

Flags:
  --full - return all the columns

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-denoms-decimals-dict

```
Usage:
  > tokens-denoms-decimals-dict

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-info-from-registry

```
  Get info about tokens from the on-chain-registry contract

Usage:
  > tokens-info-from-registry (chain_name)

  https://github.com/Snedashkovsky/on-chain-registry

Parameters:
  chain_name <string>:  (optional, default: 'bostrom')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-price-in-h-naive

```
Usage:
  > tokens-price-in-h-naive {flags}

Flags:
  --all_data
  --height <Int> - a height to request a state on (default: 0)

Input/output types:
  ╭──input──┬output─╮
  │ nothing │ table │
  ╰─────────┴───────╯

```

### cy tokens-in-h-naive

```
Usage:
  > tokens-in-h-naive {flags}

Flags:
  --price - leave price in h column

Input/output types:
  ╭─input─┬output─╮
  │ table │ table │
  ╰───────┴───────╯

```

### cy tokens-in-token-naive

```
Usage:
  > tokens-in-token-naive {flags} (token)

Flags:
  --price - leave price in h column

Parameters:
  token <string>:  (optional, default: 'ATOM')

Input/output types:
  ╭─input─┬output─╮
  │ table │ table │
  ╰───────┴───────╯

```

### cy tokens-in-h-swap-calc

```
Usage:
  > tokens-in-h-swap-calc (percentage)

Parameters:
  percentage <float>:  (optional, default: 0.3)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-format

```
Usage:
  > tokens-format {flags}

Flags:
  --clean - display only formatted values

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy balances

```
  Check balances for the keys added to the active CLI

Usage:
  > balances {flags} ...(address)

  > cy balances --test | to yaml
  name: bot3f
  boot: 654582269
  hydrogen: 50
  address: bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel

Flags:
  --test - Use keyring-backend test (with no password)

Parameters:
  ...address <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-undelegations

```
Usage:
  > tokens-undelegations {flags} ($neuron)

Flags:
  --height <Int> - a height to request a state on (default: 0)
  --sum

Parameters:
  $neuron <string>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-balance-all

```
Usage:
  > tokens-balance-all {flags} ($neuron)

Flags:
  --height <Int> - a height to request a state on (default: 0)
  --routes <String> -  (default: 'from')
  --dont_convert_pools

Parameters:
  $neuron <string>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-sum

```
Usage:
  > tokens-sum {flags}

Flags:
  --state <String> -  (default: '-')

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-rewards-withdraw

```
  Withdraw rewards, make stats

Usage:
  > tokens-rewards-withdraw (neuron)

Parameters:
  neuron <string>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy rewards-withdraw-tx-analyse

```
Usage:
  > rewards-withdraw-tx-analyse <tx_hash>

Parameters:
  tx_hash <string>: a hash of a transaction to check

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-delegate-wizard

```
Usage:
  > tokens-delegate-wizard ($neuron)

Parameters:
  $neuron <string>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-investmint-wizard

```
Usage:
  > tokens-investmint-wizard ($neuron)

Parameters:
  $neuron <string>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy tokens-fraction-input

```
Usage:
  > tokens-fraction-input {flags}

Flags:
  --dust_to_leave <Int> - the amount of token to leave for paing fee (default: 50000)
  --denom <String> - a denom of a token (default: '')
  --yes - proceed without confirmation

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy governance-view-props

```
  info about props current and past

Usage:
  > governance-view-props {flags} (id)

Flags:
  --dont_format - don't format proposals

Parameters:
  id <string>: id of a proposal to check (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy set-links-table-name

```
  Set the custom name for links csv table

Usage:
  > set-links-table-name <name>

Parameters:
  name <string>: a name for a temporary cyberlinks table file

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy set-cy-setting

```
Usage:
  > set-cy-setting {flags} (key) (value)

Flags:
  --output_value_only

Parameters:
  key <string>:  (optional)
  value <any>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy ipfs-bootstrap-add-congress

```
  Add the cybercongress node to bootstrap nodes

Usage:
  > ipfs-bootstrap-add-congress

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy validator-generate-persistent-peers-string

```
  Dump the peers connected to the given node to the comma-separated 'persistent_peers' list

Usage:
  > validator-generate-persistent-peers-string (node_address)

  > validator-generate-persistent-peers-string https://rpc.bostrom.cybernode.ai:443
  Nodes list for https://rpc.bostrom.cybernode.ai:443

  70 peers found
  persistent_peers = "7ad32f1677ffb11254e7e9b65a12da27a4f877d6@195.201.105.229:36656,d0518..."

Parameters:
  node_address <string>:  (optional)

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ string │
  ╰─────────┴────────╯

```

### cy validator-query-delegators

```
  Query all delegators to a specified validator

Usage:
  > validator-query-delegators {flags} <validator_or_moniker>

Flags:
  --limit <Int> -  (default: 1000)

Parameters:
  validator_or_moniker <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy query-tx

```
  Query tx by hash

Usage:
  > query-tx {flags} <hash>

Flags:
  --full_info - display all columns of a transaction

Parameters:
  hash <string>:

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  ╰─────────┴────────╯

```

### cy query-tx-seq

```
  Query tx by acc/seq

Usage:
  > query-tx-seq <neuron> <seq>

Parameters:
  neuron <string>:
  seq <int>:

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  ╰─────────┴────────╯

```

### cy query-account

```
  Query account

Usage:
  > query-account {flags} <neuron>

Flags:
  --height <Int> - a height to request a state on (default: 0)
  --seq - return sequence

Parameters:
  neuron <string>:

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  ╰─────────┴────────╯

```

### cy query-links-max-in-block

```
Usage:
  > query-links-max-in-block

Input/output types:
  ╭──input──┬output╮
  │ nothing │ int  │
  ╰─────────┴──────╯

```

### cy query-authz-grants-by-granter

```
  Query status of authz grants for address

Usage:
  > query-authz-grants-by-granter (neuron)

  > query-authz-grants-by-granter (qnbn bb🔑) | first 2 | to yaml
  - expired: true
    expiration: 2023-04-25 05:40:44 +00:00
    grantee: bostrom1yrv70gskxcn04xu03rpywd044gvz9l0mmhad2d
    msg: /cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward
    granter: bostrom1mcslqq8ghtuf6xu987qtk64shy6rd86a2xtwu8
    '@type': /cosmos.authz.v1beta1.GenericAuthorization
  - expired: true
    expiration: 2023-04-25 05:42:25 +00:00
    grantee: bostrom1yrv70gskxcn04xu03rpywd044gvz9l0mmhad2d
    msg: /cosmos.staking.v1beta1.MsgDelegate
    granter: bostrom1mcslqq8ghtuf6xu987qtk64shy6rd86a2xtwu8
    '@type': /cosmos.authz.v1beta1.GenericAuthorization

Parameters:
  neuron <any>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy query-authz-grants-by-grantee

```
  Query status of authz grants for address

Usage:
  > query-authz-grants-by-grantee (neuron)

  > query-authz-grants-by-grantee bostrom1sgy27lctdrc5egpvc8f02rgzml6hmmvh5wu6xk | to yaml
  - expired: true
    expiration: 2023-05-05 11:43:49 +00:00
    granter: bostrom1angqedc8vu2dxa2d2cx7z5jjzm6vjldgtqm005
    msg: /cyber.resources.v1beta1.MsgInvestmint
    grantee: bostrom1sgy27lctdrc5egpvc8f02rgzml6hmmvh5wu6xk
    '@type': /cosmos.authz.v1beta1.GenericAuthorization

Parameters:
  neuron <any>: an address of a neuron (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy authz-give-grant

```
Usage:
  > authz-give-grant <$neuron> <$message_type> <$expiration>

Parameters:
  $neuron <any>: an address of a neuron
  $message_type <string>:
  $expiration <duration>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy query-links-bandwidth-neuron

```
Usage:
  > query-links-bandwidth-neuron (neuron)

Parameters:
  neuron <any>: an address of a neuron (optional)

Input/output types:
  ╭──input──┬output─╮
  │ nothing │ table │
  ╰─────────┴───────╯

```

### cy query-staking-validators

```
Usage:
  > query-staking-validators

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy validator-chooser

```
Usage:
  > validator-chooser {flags}

Flags:
  --only_my_validators

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy caching-function

```
  A wrapper, to cache CLI requests

Usage:
  > caching-function {flags} ...(rest)

Flags:
  --exec <String> - The name of executable (default: '')
  --cache_validity_duration <Duration> - Sets the cache's valid duration.
No updates initiated during this period. (default: 1hr)
  --cache_stale_refresh <Duration> - Sets stale cache's usable duration.
Triggers background update and returns cache results.
If exceeded, requests immediate data update. (default: 1wk)
  --force_update
  -U, --disable_update
  --quiet - Don't output execution's result
  --no_default_params - Don't use default params (like output, chain-id)
  --error - raise error instead of null in case of cli's error
  --retries <Int>

Parameters:
  ...rest <any>:

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  ╰─────────┴────────╯

```

### cy qnbn

```
  query neuron addrsss by his nick

Usage:
  > qnbn {flags} ...(nicks)

Flags:
  --df
  -f, --force_list_output

Parameters:
  ...nicks <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy crypto-prices

```
Usage:
  > crypto-prices

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy help-cy

```
  An ordered list of cy commands

Usage:
  > help-cy {flags}

Flags:
  -m, --to_md - export table as markdown

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy echo_particle_txt

```
  echo particle for publishing

Usage:
  > echo_particle_txt {flags} <i>

Flags:
  -m, --markdown

Parameters:
  i <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy queue-task-add

```
Usage:
  > queue-task-add {flags} <command>

Flags:
  -o, --priority <Int> -  (default: 1)

Parameters:
  command <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy queue-tasks-monitor

```
Usage:
  > queue-tasks-monitor {flags}

Flags:
  --threads <Int> -  (default: 10)
  --cids_in_run <Int> - a number of files to download in one command run. 0 - means all (default) (default: 10)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy queue-execute-task

```
Usage:
  > queue-execute-task <task_path>

Parameters:
  task_path <path>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy check-requirements

```
  Check if all necessary dependencies are installed

Usage:
  > check-requirements

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy use-recommended-nushell-settings

```
Usage:
  > use-recommended-nushell-settings

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy nu-complete-graph-csv-files

```
Usage:
  > nu-complete-graph-csv-files

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy cp-banner

```
Usage:
  > cp-banner (index)

Parameters:
  index <int>:  (optional, default: 0)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```
