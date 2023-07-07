# Cy

Cy - a [nushell](https://www.nushell.sh/) wrapper, a client for the Cyber family blockchains (bostrom, pussy) and IPFS.

## The Goals of Cy:

1. To demonstrate the use cases of cybergraphs and the capabilities of Cyber family blockchains.
2. To showcase the beauty and power of the Nushell environment and its scripting language.
3. To aid me in learning cool apps and programming languages.

## Cyber-family blockchains

Bostrom is the name of the consensus computer that maintains a general-purpose, permissionless informational graph where nodes are CIDs of files in the IPFS network, and edges are Cyberlinks (consisting of source, destination, author, height - records) written into the blockchain. The information written into the blockchain is secured to remain in existence as long as the blockchain is operative. The blockchain is designed with economic incentives that motivate validators to sustain the network. For further information about Cyber blockchains, please refer to [Bostrom Journal.](https://github.com/cyber-prophet/bostrom-journal/blob/manual/BostromJournal001.md)

## Key features of Cy

- Setting different settings for different profiles (RPC endpoints, private keys, networks, etc...)
- Seamlessly upload and download data to cyber node or to a local IPFS node
- Creating multiple cyber links
- Shortcuts for interacting with passport smart contract
- Cyber search in terminal
- Many more (see list of functions below)

## Installation (Mac, Linux)

Open Terminal app on your computer.

1. Install [brew](https://brew.sh/)
2. Add a custom tap to your Homebrew: `brew tap cyber-prophet/homebrew-taps`
3. Install all the dependencies for running Cy: `brew install cybundle`
   This command will install the following software on your computer:

   1. curl (if needed)
   2. [gum](https://github.com/charmbracelet/gum)
   3. [cyber](https://github.com/cybercongress/go-cyber)
   4. [pussy](https://github.com/greatweb/space-pussy)
   5. [nushell](https://www.nushell.sh/) app
   6. [ipfs - kubo](https://github.com/ipfs/kubo) app
   7. [wezterm](https://wezfurlong.org/wezterm/) terminal
   8. [pueue](https://github.com/Nukesor/pueue) app
   9. [cybundle script](https://github.com/cyber-prophet/homebrew-taps/blob/main/src/cybundle)

4. To continue installation of configs and execute necessary init steps, run: `cybundle`

After installation, you can launch `nu` in your terminal with already configured `cy` in it.
Or, if your system is MacOS or Linux (but not Linux under WSL) - you can launch Wezterm app.
It should be configured to use `nu` with `cy` from the very start.

To start using Cy, follow the instructions on your screen. They should include:

1. Go through the wizard `cy config new`.
2. See all the commands in logical order by executing `cy`.
3. See all the commands suggestions by entering `cy` + tab.

## Installation (Windows)

Windows supports WSL2. Install it first: https://learn.microsoft.com/en-us/windows/wsl/install.
By default, it should install Ubuntu on your computer. And when Ubuntu is installed and launched,
proceed with the steps described in the [section of installation for MacOS and Linux](#installation-mac-linux)
of this manual.

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
  
  > "cyber" | save -f cyber.txt; cy pin-text 'cyber.txt' --dont_follow_path
  QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
  
  > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
  QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
  
  > cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --dont_detect_cid
  QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F
  
Flags:
  --only_hash - calculate hash only, don't pin anywhere
  --dont_detect_cid - work with CIDs as regular texts
  --dont_follow_path - treat existing file paths as reuglar texts

Parameters:
  text_param <string>:  (optional)

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

Parameters:
  text_from <any>: 
  text_to <any>: 

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
  ...rest <any>: 

```

### cy link-files
```
  Pin files from the current folder to the local node and append their cyberlinks to the temp table
  
Usage:
  > link-files {flags} ...(files) 

  > mkdir linkfilestest; cd linkfilestest
  > 'cyber' | save cyber.txt; 'bostrom' | save bostrom.txt
  > cy link-files --link_filenames --yes | to yaml
  - from: QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k
    to: QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb
  - from: QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6
    to: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
  > cd ..; rm -r linkfilestest
  
Flags:
  -n, --link_filenames - Add filenames as a from link
  -D, --disable_append - Don't append links to the tmp table
  --quiet - Don't output results page
  -y, --yes - Confirm uploading files without request

Parameters:
  ...files <string>: filenames to add into the local ipfs node

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
  neuron <any>: 

```

### cy tweet
```
  Add a tweet and send it immediately (unless of disable_send flag)
  
Usage:
  > tweet {flags} <text_to> 

  > cy tmp-clear; cy tweet 'cyber-prophet is cool' --disable_send | to yaml
  from_text: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
  to_text: cyber-prophet is cool
  from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
  to: QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK
  
Flags:
  -D, --disable_send - 

Parameters:
  text_to <any>: 

```

### cy link-random
```
  Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)
  
Usage:
  > link-random {flags} (source) 

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
  -n <Int> - Number of links to append (default: 1)

Parameters:
  source <string>:  (optional)

```

### cy tmp-view
```
  View the temp cyberlinks table
  
Usage:
  > tmp-view {flags} 

  > cy tmp-view | to yaml
  There are 2 cyberlinks in the temp table:
  - from_text: chuck norris
    to_text: |-
      Chuck Norris IS Lukes father.
  
      via [Chucknorris.io](https://chucknorris.io)
    from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
    to: QmSLPzbM5NVmXuYCPiLZiePAhUcDCQncYUWDLs7GkLqC7J
    date_time: 20230701-134134
  - from_text: quote
    to_text: |-
      He who knows himself is enlightened. (Lao Tzu )
  
      via [forismatic.com](https://forismatic.com)
    from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
    to: QmWoxYsWYuTP4E2xaQHr3gUZZTBC7HdNDVhis1BK9X3qjX
    date_time: 20230702-113842
  
Flags:
  -q, --quiet - Don't print info

```

### cy tmp-append
```
  Append piped-in table to the temp cyberlinks table
  
Usage:
  > tmp-append {flags} (cyberlinks) 

Flags:
  -q, --quiet - 

Parameters:
  cyberlinks <any>: cyberlinks table (optional)

```

### cy tmp-replace
```
  Replace the temp table with piped-in table
  
Usage:
  > tmp-replace {flags} (cyberlinks) 

Flags:
  -q, --quiet - 

Parameters:
  cyberlinks <any>: cyberlinks table (optional)

```

### cy tmp-clear
```
  Empty the temp cyberlinks table
  
Usage:
  > tmp-clear 

```

### cy tmp-link-all
```
  Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table
  
Usage:
  > tmp-link-all {flags} <text> 

  > [[from_text, to_text]; ['cyber-prophet' null] ['tweet' 'cy is cool!']] 
  | cy tmp-pin-columns | cy tmp-link-all 'master' --column 'to' --non_empty | to yaml
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

```

### cy tmp-pin-columns
```
  Pin values from column 'text_from' and 'text_to' to an IPFS node and fill according columns with their CIDs
  
Usage:
  > tmp-pin-columns {flags} 

  > [{from_text: 'cyber' to_text: 'cyber-prophet'} {from_text: 'tweet' to_text: 'cy is cool!'}] 
  | cy tmp-pin-columns | to yaml
  - from_text: cyber
    to_text: cyber-prophet
    from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
    to: QmXFUupJCSfydJZ85HQHD8tU1L7CZFErbRdMTBxkAmBJaD
  - from_text: tweet
    to_text: cy is cool!
    from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
    to: QmddL5M8JZiaUDcEHT2LgUnZZGLMTTDEYVKWN1iMLk6PY8
  
Flags:
  -D, --dont_replace - Don't replace the tmp cyberlinks table

```

### cy tmp-remove-existed
```
  Remove existing cyberlinks from the temp cyberlinks table
  
Usage:
  > tmp-remove-existed 

```

### cy tmp-send-tx
```
  Create a tx from the piped in or temp cyberlinks table, sign and broadcast it
  
Usage:
  > tmp-send-tx 

  > cy tmp-send-tx | to yaml
  cy: 2 cyberlinks should be successfully sent
  code: 0
  txhash: 9B37FA56D666C2AA15E36CDC507D3677F9224115482ACF8CAF498A246DEF8EB0
  
```

### cy tsv-copy
```
  Copy a table from the pipe into the clipboard (in tsv format)
  
Usage:
  > tsv-copy 

```

### cy tsv-paste
```
  Paste a table from the clipboard to stdin (so it can be piped further)
  
Usage:
  > tsv-paste 

```

### cy update-cy
```
  Update-cy to the latest version
  
Usage:
  > update-cy {flags} 

Flags:
  --branch <Custom(String, 1665)> -  (default: 'main')

```

### cy passport-get
```
  Get a passport by providing a neuron's address or nick
  
Usage:
  > passport-get <address_or_nick> 

  > cy passport-get cyber-prophet | to yaml
  owner: bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
  addresses:
  - label: null
    address: cosmos1sgy27lctdrc5egpvc8f02rgzml6hmmvhhagfc3
  avatar: Qmdwi54WNiu1phvMA2digYHRzQRHRkS1pKWAnpawjSWUZi
  nickname: cyber-prophet
  data: null
  particle: QmRumrGFrqxayDpySEkhjZS1WEtMyJcfXiqeVsngqig3ak
  
Parameters:
  address_or_nick <string>: Name of passport or neuron's address

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

```

### cy graph-download-snapshot
```
  Download a snapshot of cybergraph by graphkeeper
  
Usage:
  > graph-download-snapshot {flags} 

Flags:
  -D, --disable_update_parquet - Don't update the particles parquet file

```

### cy graph-to-particles
```
  Output unique list of particles from piped in cyberlinks table
  
Usage:
  > graph-to-particles {flags} 

  > cy graph-to-particles --include_content | dfr into-df | dfr into-nu | first 2 | to yaml
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
  --include_content - Include column with particles' content
  -c, --cids_only - Output one column with CIDs only

```

### cy graph-update-particles-parquet
```
  Update the 'particles.parquet' file (it inculdes content of text files)
  
Usage:
  > graph-update-particles-parquet {flags} 

Flags:
  --full_content - 

```

### cy graph-filter-neurons
```
  Filter the graph to chosen neurons only
  
Usage:
  > graph-filter-neurons ...(neurons_nicks) 

Parameters:
  ...neurons_nicks <string>: 

```

### cy graph-append-related
```
  Append related cyberlinks to the piped in graph
  
Usage:
  > graph-append-related 

```

### cy graph-update-neurons
```
  Update neurons YAML-dictionary
  
Usage:
  > graph-update-neurons {flags} 

Flags:
  --passport - Update passport data
  --balance - Update balances data
  --karma - Update karma
  -a, --all - Update passport, balance, karma
  -t, --threads <Int> - Number of threads to use for downloading (default: 30)
  --dont_save - Don't update file on disk, just output results
  -q, --quiet - Don't output results table

```

### cy graph-to-gephi
```
  Export the entire graph into CSV file for import to Gephi
  
Usage:
  > graph-to-gephi 

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
  config_name <string>: --quiet (-q) (optional)

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

```

### cy config-activate
```
  Activate the config JSON
  
Usage:
  > config-activate (config_name) 

Parameters:
  config_name <string>:  (optional)

```

### cy search
```
  Use the built-in node search function in cyber or pussy
  
Usage:
  > search {flags} <query> 

Flags:
  -p, --page <Int> -  (default: 0)
  -r, --results_per_page <Int> -  (default: 10)
  --search_type <Custom(String, 1661)> -  (default: 'search-with-backlinks')

Parameters:
  query <any>: 

```

### cy cid-get-type-gateway
```
  Obtain cid info
  
Usage:
  > cid-get-type-gateway {flags} <cid> 

Flags:
  --gate_url <String> -  (default: 'https://gateway.ipfs.cybernode.ai/ipfs/')
  --to_csv - 

Parameters:
  cid <string>: 

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

```

### cy cid-download
```
  Download cid immediately and mark it in the queue
  
Usage:
  > cid-download {flags} <cid> 

Flags:
  --source <String> - kubo or gateway
  --info_only <Boolean> - Don't download the file by write a card with filetype and size (default: false)
  --folder <String> - 

Parameters:
  cid <string>: 

```

### cy cid-download-gateway
```
  Download a cid from gateway immediately
  
Usage:
  > cid-download-gateway {flags} <cid> 

Flags:
  --gate_url <String> -  (default: 'https://gateway.ipfs.cybernode.ai/ipfs/')
  --folder <String> - 
  --info_only <Boolean> - Don't download the file by write a card with filetype and size (default: false)

Parameters:
  cid <string>: 

```

### cy watch-search-folder
```
  Watch the queue folder, and if there are updates, request files to download
  
Usage:
  > watch-search-folder 

```

### cy queue-check
```
  Check the queue for the new CIDs, and if there are any, safely download the text ones
  
Usage:
  > queue-check {flags} (attempts) 

Flags:
  --info - 
  --quiet - 

Parameters:
  attempts <int>:  (optional, default: 0)

```

### cy cache-clear
```
  Clear the cache folder
  
Usage:
  > cache-clear 

```

### cy query-current-height
```
  Get a current height for a network chosen in config
  
Usage:
  > query-current-height (exec) 

Parameters:
  exec <string>:  (optional)

```

### cy karma-get
```
  Get a karma metric for a given neuron
  
Usage:
  > karma-get <address> 

  > cy karma-get bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8 | to yaml
  karma: 852564186396
  
Parameters:
  address <string>: 

```

### cy balance-get
```
  Get a balance for a given account
  
Usage:
  > balance-get <address> 

  > cy balance-get bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | to yaml
  boot: 348358
  hydrogen: 486000000
  milliampere: 25008
  millivolt: 7023
  
Parameters:
  address <string>: 

```

### cy balances
```
  Check balances for the keys added to the active CLI
  
Usage:
  > balances {flags} ...(name) 

  > cy balances --test | to yaml
  - name: bot3f
    boot: 654582269
    hydrogen: 50
    address: bostrom1aypv5wxute0nnhfv44jkhyfkzt7zyrden85tel
  
Flags:
  --test - Use keyring-backend test (with no password)

Parameters:
  ...name <string>: 

```

### cy ipfs-bootstrap-add-congress
```
  Add the cybercongress node to bootstrap nodes
  
Usage:
  > ipfs-bootstrap-add-congress 

```

### cy ibc-denoms
```
  Check IBC denoms
  
Usage:
  > ibc-denoms 

```

### cy validator-generate-persistent-peers-string
```
  Dump the peers connected to the given node to the comma-separated 'persistent_peers' list
  
Usage:
  > validator-generate-persistent-peers-string <node_address> 

Parameters:
  node_address <string>: 

```

### cy help
```
  An ordered list of cy commands
  
Usage:
  > help {flags} 

Subcommands:
  help aliases - Show help on nushell aliases.
  help commands - Show help on nushell commands.
  help externs - Show help on nushell externs.
  help modules - Show help on nushell modules.
  help operators - Show help on nushell operators.

Flags:
  -m, --to_md - export table as markdown

```

### cy cprint
```
  Print string colourfully
  
Usage:
  > cprint {flags} ...(args) 

Flags:
  -c, --color <String> -  (default: 'default')
  -h, --highlight_color <String> -  (default: 'green_bold')
  -r, --frame_color <String> -  (default: 'dark_gray')
  -f, --frame <String> - A symbol (or a string) to frame text
  -b, --before <Int> - A number of new lines before text (default: 0)
  -a, --after <Int> - A number of new lines after text (default: 1)
  -e, --echo - Echo text string instead of printing

Parameters:
  ...args <any>: 

```


