# Cy

Cy - a [nushell](https://www.nushell.sh/) wrapper for `cyber`, `ipfs` and other CLIs for interacting with Cybergraphs.

## Status

Very much WIP. Actively developed.

## Key features of Cy

- Setting different settings for different profiles (RPC endpoints, private keys, networks, etc...)
- Seamlessly upload and download data to cyber node or to a local IPFS node
- Creating multiple cyber links
- Shortcuts for interacting with passport smart contract
- Cyber search in terminal
- Many more (see list of functions below)

## Installation

### Quick start

If you have `nushell`, `git` and `cyber` CLI-s installed:

```nushell
git clone https://github.com/cyber-prophet/cy; cd cy;
overlay use -pr cy.nu
```

### Install all the neccessary apps using homebrew (Mac, Linux)

Open Terminal app on your computer.

1. Install [brew](https://brew.sh/)
2. Add a custom tap to your Homebrew, install all the dependencies for running Cy:

```sh
brew tap cyber-prophet/homebrew-taps; brew install cybundle; cybundle
```

3. The commands above, upon request, will install the following software on your computer if it is not installed yet:

   1. [cybundle script](https://github.com/cyber-prophet/homebrew-taps/blob/main/src/cybundle)
   1. [nushell](https://www.nushell.sh/) app
   1. [curl](https://curl.se/)
   1. [cyber](https://github.com/cybercongress/go-cyber)
   1. [pussy](https://github.com/greatweb/space-pussy)
   1. [ipfs - kubo](https://github.com/ipfs/kubo)
   1. [pueue](https://github.com/Nukesor/pueue)
   1. [rich-cli](https://github.com/Textualize/rich-cli)

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

Parameters:
  text_param <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

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
  -q, --quiet - Don't output the cyberlink record after executing the command
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
  ...rest <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

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
  -n, --link_filenames - Add filenames as a from link
  -D, --disable_append - Don't append links to the links table
  --quiet - Don't output results page
  -y, --yes - Confirm uploading files without request

Parameters:
  ...files <path>: filenames to add into the local ipfs node

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy follow

```
  Create a cyberlink according to semantic construction of following a neuron

Usage:
  > follow <neuron>

  > cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
  from_text: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
  to_text: bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
  from: QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx
  to: QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af

Parameters:
  neuron <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

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
  -D, --disable_send -

Parameters:
  text_to <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

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
  --source (default: 'forismatic.com')

Parameters:
  n <int>: Number of links to append (optional, default: 1)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

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
  -q, --quiet - Don't print info
  --no_timestamp -

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-append

```
  Append piped-in table to the temp cyberlinks table

Usage:
  > links-append {flags}

Flags:
  -q, --quiet -

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-replace

```
  Replace the temp table with piped-in table

Usage:
  > links-replace {flags}

Flags:
  -q, --quiet -

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-clear

```
  Empty the temp cyberlinks table

Usage:
  > links-clear

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-link-all

```
  Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table

Usage:
  > links-link-all {flags} <text>

  > [[from_text, to_text]; ['cyber-prophet' null] ['tweet' 'cy is cool!']]
  | cy links-pin-columns | cy links-link-all 'master' --column 'to' --non_empty | to yaml
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
  -c, --column <String> - a column to use for values ('from' or 'to'). 'from' is default (default: 'from')
  --non_empty - fill non-empty only

Parameters:
  text <string>: a text to upload to ipfs

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

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
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-remove-existed

```
  Remove existing cyberlinks from the temp cyberlinks table

Usage:
  > links-remove-existed

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy links-publish

```
  Publish all links in the temp table to cybergraph

Usage:
  > links-publish

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
  Update Cy to the latest version

Usage:
  > update-cy {flags}

Flags:
  --branch (default: 'dev')

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
  --quiet -

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
  > passport-set {flags} <particle> (nickname)

  > cy passport-set QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd
  The particle field for maxim should be successfuly set to QmZSbGCBAPpqwXHSbUkn4P2RHiL2nRjv7BGFP4vVjcYKHd

Flags:
  --field <String> - A passport's field to set: particle, data, new_avatar (default: 'particle')
  --verbose - Show the node's response

Parameters:
  particle <string>:
  nickname <any>: Provide a passport's nickname. If null - the nick from config will be used. (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy dict-neurons

```
  Output neurons dict

Usage:
  > dict-neurons {flags}

Flags:
  --df - output as a dataframe

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy dict-neurons-add

```
  Add neurons to YAML-dictionary WIP

Usage:
  > dict-neurons-add

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
  --all_neurons - Update info about all neurons
  -t, --threads <Int> - Number of threads to use for downloading (default: 30)
  --dont_save - Don't update the file on a disk, just output the results
  -q, --quiet - Don't output results table

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-download-links

```
  Download the latest cyberlinks from a hasura cybernode endpoint

Usage:
  > graph-download-links

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
  -s, --include_system - Include tweets, follow and avatar paritlces
  --include_global - Include column with global particles' df (that includes content)
  --include_particle_index - Include local 'particle_index' column
  --is_first_neuron - Check if 'neuron' and 'neuron_global' columns are equal
  -o, --only_first_neuron -
  -c, --cids_only - Output one column with CIDs only
--init_role             # Output if particle originally was in 'from' or 'to' column

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
  Update the 'particles.parquet' file (it inculdes content of text files)

Usage:
  > graph-update-particles-parquet {flags}

Flags:
  --full_content - include column with full content of particles
  -q, --quiet - don't print info about the saved parquet file

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

### cy graph-append-related

```
  Append related cyberlinks to the piped in graph

Usage:
  > graph-append-related {flags}

Flags:
  -o, --only_first_neuron -

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
  Output particles into txt formated feed

Usage:
  > graph-to-txt-feed

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-to-cosmograph

```
  Export graph in cosmograph format

Usage:
  > graph-to-cosmograph

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-add-metadata

```
  Add content_s and neuron's nicknames columns to piped in or the whole graph df
  > cy graph-filter-neurons maxim_bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
Usage:
  > graph-add-metadata {flags}

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
  --full_content -
  --include_text_only -

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy graph-links-df

```
  Output a full graph, or pass piped in graph further

Usage:
  > graph-links-df {flags}

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
  --include_contracts - include links from contracts (including passport)

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
  > cy cid-get-type-gateway QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV | to yaml
Usage:
  > cid-get-type-gateway {flags} <cid>

  type: text/plain; charset=utf-8
  size: '5'

Flags:
  --gate_url <String> -  (default: 'https://gateway.ipfs.cybernode.ai/ipfs/')
  --to_csv -

Parameters:
  cid <string>:

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
  -f, --force -
  --source <String> - kubo or gateway
  --info_only - Don't download the file by write a card with filetype and size
  --folder <String> -

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
  --info_only - Don't download the file by write a card with filetype and size
  --folder <String> -

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
  symbol <string>:  (optional, default: '+')

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
  --quiet - don't print information
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
  exec <string>:  (optional)

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
  neuron <string>:  (optional)

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
  --height <Int> -  (default: 0)
  --record -

Parameters:
  neuron <string>:  (optional)

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

Flags:
  --height <Int> -  (default: 0)

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

### cy tokens-rewards-withdraw

```
  Withdraw rewards, make stats

Usage:
  > tokens-rewards-withdraw (neuron)

Parameters:
  neuron <string>:  (optional)

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
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy validator-generate-persistent-peers-string

```
  Dump the peers connected to the given node to the comma-separated 'persistent_peers' list
  Nodes list for https://rpc.bostrom.cybernode.ai:443
Usage:
  > validator-generate-persistent-peers-string (node_address)


  70 peers found
  persistent_peers = "7ad32f1677ffb11254e7e9b65a12da27a4f877d6@195.201.105.229:36656,d0518ce9881a4b0c5872e5e9b7c4ea8d760dad3f@85.10.207.173:26656"

Parameters:
  node_address <string>:  (optional)

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy query-tx

```
  Query tx by hash

Usage:
  > query-tx <hash>

Parameters:
  hash <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

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
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy query-account

```
  Query account

Usage:
  > query-account {flags} <neuron>

Flags:
  --height <Int> -  (default: 0)
  --seq - return sequence

Parameters:
  neuron <string>:

Input/output types:
  ╭input┬output╮
  │ any │ any  │
  ╰─────┴──────╯

```

### cy qnbn

```
  query neuron addrsss by his nick

Usage:
  > qnbn {flags} ...(nicks)

Flags:
  --df -
  -f, --force_list_output -

Parameters:
  ...nicks <string>:

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
