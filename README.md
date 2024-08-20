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

  pin text 'cyber', get it's cid
  > cy pin-text 'cyber'
  QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

  pin text 'cyber.txt', get it's cid
  > cy pin-text 'cyber.txt'
  QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6

  save text 'cyber' to the file. Use flag `--follow_file_path` to pin the content of file, but not it's name
  > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt' --follow_file_path
  QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

  use `cy pin-text` with some cid, to see that it will return the cid by default unchanged
  > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
  QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

  use `--ignore_cid` flag to calculate hash from the initial cid as if it is a regular text
  > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
  QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F

Flags:
  --only_hash - calculate hash only, don't pin anywhere
  --ignore_cid - work with CIDs as regular texts, don't use them as they are
  --follow_file_path - check if `text_param` is a valid path, and if yes - try to open it
  --skip_save_particle_in_cache - don't save particle to local cache in cid.md file #totest

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
  --ignore_cid - work with CIDs as regular texts
  --follow_file_path - check if `text_param` is a valid path, and if yes - try to open it

Parameters:
  text_from <string>:
  text_to <string>:

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
  ╭───input───┬─output─╮
  │ nothing   │ table  │
  │ list<any> │ table  │
  ╰───────────┴────────╯

```

### cy link-files

```
  Pin files from the current folder to the local node and append their cyberlinks to the temp table

Usage:
  > link-files {flags} ...(files)

  Create cyberlinks for saved in the example file.
  > cd (mktemp -d); 'cyber' | save cyber.txt; 'bostrom' | save bostrom.txt;
  > cy link-files --link_filenames --yes | to yaml
  - from_text: bostrom.txt
    to_text: pinned_file:bostrom.txt
    from: QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k
    to: QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb
  - from_text: cyber.txt
    to_text: pinned_file:cyber.txt
    from: QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
    to: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

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

### cy link-folder

```
  Create cyberlinks to hierarchies (if any) `parent_folder - child_folder`, `folder - filename`, `filename - content`

Usage:
  > link-folder {flags} (folder_path)

Flags:
  --include_extension - Include a file extension
  -D, --disable_append - Don't append links to the links table
  --no_content - Use only directory and filenames, don't create cyberlinks to file contents
  --no_folders - Don't link folders to their child members (is not available if `--no_content` is used)
  -y, --yes - Confirm uploading files without request

Parameters:
  folder_path <path>: path to a folder to link files at (optional)

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ table  │
  ╰─────────┴────────╯

```

### cy follow

```
  Create a cyberlink according to `following a neuron` semantic convention

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
  Add a tweet and send it immediately (unless of `--disable_send`)

Usage:
  > tweet {flags} (text_to)

  > cy links-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
  from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
  to_text: cyber-prophet is cool
  from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
  to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK

Flags:
  -D, --disable_send - don't send tweet immediately, but put it into the temp table

Parameters:
  text_to <string>: text to tweet (optional)

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  │ string  │ record │
  ╰─────────┴────────╯

```

### cy link-random

```
  Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)

Usage:
  > link-random {flags} (n)

  > cy link-random | to yaml
  - from_text: quote
    to_text: |
      text: Those who are blessed with the most talent don't necessarily outperform everyone else. It's the people with follow-through who excel.
      author: Mary Kay Ash
      source: https://forismatic.com
    from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
    to: QmXfF8iWJUA37T7fDWbSLM6ASHBtXMTfnJx9jhg6g5A9eE

  > cy link-random --source chucknorris.io | to yaml
  - from_text: chuck norris
    to_text: |
      text: Chuck Norris is like God, sex and kung-fu put in a blender to create undiluted manliness.
      source: https://chucknorris.io
    from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
    to: Qmd3y4evbAZYwKPojDsvZiwSnWdnrPugY7CF95E4Jxp4Me

Flags:
  --source choose the source to take random links from (default: 'forismatic.com')

Parameters:
  n <int>: Number of links to append (optional, default: 1)

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ record │
  │ nothing │ table  │
  ╰─────────┴────────╯

```

### cy link-number

```
  Command to link numbers. Useful for testing and using bandwidth.

Usage:
  > link-number {flags} (count)

Flags:
  --from <Int> - number including which to create a range

Parameters:
  count <int>: the count of numbers to cyberlink (optional, default: 10)

```

### cy links-view

```
  View the temp cyberlinks table

Usage:
  > links-view {flags}

  > cy links-view | to yaml
  There are 2 cyberlinks in the temp
  table:
  - from_text: quote
    to_text: |
      text: Those who are blessed with the most talent don't necessarily outperform everyone else. It's the people with follow-through who excel.
      author: Mary Kay Ash
      source: https://forismatic.com
    from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
    to: QmXfF8iWJUA37T7fDWbSLM6ASHBtXMTfnJx9jhg6g5A9eE
    timestamp: 20240801-072212
  - from_text: chuck norris
    to_text: |
      text: Chuck Norris is like God, sex and kung-fu put in a blender to create undiluted manliness.
      source: https://chucknorris.io
    from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
    to: Qmd3y4evbAZYwKPojDsvZiwSnWdnrPugY7CF95E4Jxp4Me
    timestamp: 20240801-072216

Flags:
  -q, --quiet - Disable informational messages
  --no_timestamp - Don't output a timestamps column

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ table  │
  ╰─────────┴────────╯

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
  Swap columns `from` and `to`

Usage:
  > links-swap-from-to {flags}

Flags:
  -D, --dont_replace - output results only, without modifying the links table
  --keep_original - append results to original links

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ table  │
  │ table   │ table  │
  ╰─────────┴────────╯

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
  ╭──input──┬─output─╮
  │ nothing │ table  │
  │ table   │ table  │
  ╰─────────┴────────╯

```

### cy links-pin-columns

```
  Pin values of 'from_text' and 'to_text' columns to an IPFS node and fill `from` and `to` with their CIDs

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
  ╭──input──┬─output─╮
  │ nothing │ table  │
  │ table   │ table  │
  ╰─────────┴────────╯

```

### cy links-pin-columns-using-kubo

```
Usage:
  > links-pin-columns-using-kubo {flags}

Flags:
  -D, --dont_replace - Don't replace the links cyberlinks table
  --pin_to_local_ipfs - Pin to local kubo
  --ignore_cid - work with CIDs as regular texts
  --skip_save_particle_in_cache - don't save particles to local cache in cid.md file
  -q, --quiet - don't print information about tem folder

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ table  │
  │ table   │ table  │
  ╰─────────┴────────╯

```

### cy pin-file-or-folder-to-cybernode

```
Usage:
  > pin-file-or-folder-to-cybernode <$path>

Parameters:
  $path <path>: the path to a folder or a file to pin

```

### cy links-remove-existed-1by1

```
  Remove existing in cybergraph cyberlinks from the temp table

Usage:
  > links-remove-existed-1by1 {flags}

Flags:
  --all_links - check all links in the temp table
  --threads <Int> - number threads to request cyberlinks (default: 10)

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ table   │
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy links-remove-existed-using-snapshot

```
  Remove existing links using graph snapshot data

Usage:
  > links-remove-existed-using-snapshot

```

### cy links-publish

```
  Publish all links from the temp table to cybergraph

Usage:
  > links-publish {flags}

Flags:
  --links_per_trans <Int>

```

### cy set-links-table-name

```
  Set a custom name for the temp links csv table

Usage:
  > set-links-table-name (name)

Parameters:
  name <string>: a name for a temporary cyberlinks table file (optional)

Input/output types:
  ╭──input──┬─output──╮
  │ nothing │ nothing │
  ╰─────────┴─────────╯

```

### cy config-new

```
  Create a config JSON to set env variables, to use them as parameters in cyber cli

Usage:
  > config-new

```

### cy config-view

```
  View a saved JSON config file

Usage:
  > config-view (config_name)

Parameters:
  config_name <string>:  (optional)

```

### cy config-save

```
  Save the piped-in JSON into a config file inside of `cy/config` folder

Usage:
  > config-save {flags} (config_name)

Flags:
  --inactive - Don't activate current config
  --quiet - Don't pring config

Parameters:
  config_name <string>:  (optional)

```

### cy config-activate

```
  Activate the config JSON

Usage:
  > config-activate <config_name>

Parameters:
  config_name <string>:

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

```

### cy load-default-env

```
Usage:
  > load-default-env

```

### cy help-cy

```
  An ordered list of cy commands

Usage:
  > help-cy

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

### cy query-links-bandwidth-neuron

```
Usage:
  > query-links-bandwidth-neuron (neuron)

Parameters:
  neuron <any>: an address of a neuron (optional)

Input/output types:
  ╭──input──┬─output─╮
  │ nothing │ table  │
  ╰─────────┴────────╯

```
