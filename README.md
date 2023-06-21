# cy

Cy - a [nushell](https://www.nushell.sh/) wrapper, an interface to the cyber family blockchains CLIs (bostrom, pussy) and IPFS.

## Cyber-family blockchains

Cyber-family blockchains maintain permissionless informational graphs where nodes are CIDs of files in the IPFS network and edges are Cyberlinks (consisting of source, destination, author, height - records) written into the blockchain.Information written into the blockchain is secured to remain in existence as long as the blockchain is operational. The blockchain is designed with economic incentives that motivate validators to sustain the network.
For further information about Cyber blockchains, please refer to [Bostrom Journal.](https://github.com/cyber-prophet/bostrom-journal/blob/manual/BostromJournal001.md)

## Key features of Cy

- Setting different settings for different profiles (RPC endpoints, private keys, networks, etc...)
- Seamlessly uploading and downloading data to cyber node or to a local IPFS node
- Creating multiple cyber links
- Shortcuts for interacting with passport smart contract
- Cyber search in terminal
- Many more (see list of functions below)

## Installation (Mac, Linux)

Open Terminal app on your computer.

1. Install [brew](https://brew.sh/)
2. Add a custom tap to your Homebrew: `brew tap cyber-prophet/homebrew-taps`
3. Install all the dependencies for running cy: `brew install cybundle`
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

To start using cy, follow the instructions on your screen. They should include:

1. Go through the wizard `cy config new`.
2. See all the commands in logical order by executing `cy`.
3. See all the commands suggestions by entering `cy` + tab.

## Installation (Windows)

Windows supports WSL2. Install it first: https://learn.microsoft.com/en-us/windows/wsl/install. 
By default, it should install Ubuntu on your computer. And when Ubuntu is installed and launched, 
proceed with the steps described in the [section of installation for MacOS and Linux](#installation-mac-linux) 
of this manual.

## Examples

```
❯ cy pin text "bostrom"
QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb


❯ ls
╭─────────────┬──────┬──────┬────────────╮
│    name     │ type │ size │  modified  │
├─────────────┼──────┼──────┼────────────┤
│ bostrom.txt │ file │  7 B │ 2 days ago │
│ cyber.txt   │ file │  5 B │ 2 days ago │
╰─────────────┴──────┴──────┴────────────╯

❯ cy pin files --cyberlink_filenames_to_their_files
There are 2 cyberlinks in the temp table:
╭────────────────────────────────────────────────┬────────┬────────────────────────────────────────────────┬─────────────┬─────────────╮
│                      from                      │ status │                       to                       │  filename   │  date_time  │
├────────────────────────────────────────────────┼────────┼────────────────────────────────────────────────┼─────────────┼─────────────┤
│ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ added  │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ bostrom.txt │ 230112-2353 │
│ QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6 │ added  │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ cyber.txt   │ 230112-2353 │
╰────────────────────────────────────────────────┴────────┴────────────────────────────────────────────────┴─────────────┴─────────────╯

❯ cy link texts "bostrom" "cyber"
There are 1 cyberlinks in the temp table:
╭────────────┬─────────┬────────────────────────────────────────────────┬────────────────────────────────────────────────┬─────────────╮
│ from_text  │ to_text │                      from                      │                       to                       │  date_time  │
├────────────┼─────────┼────────────────────────────────────────────────┼────────────────────────────────────────────────┼─────────────┤
│ bostrom    │ cyber   │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ 230112-2355 │
╰────────────┴─────────┴────────────────────────────────────────────────┴────────────────────────────────────────────────┴─────────────╯
```

## Commands

|command|desc|
|-|-|
|cy pin-text|Pin a text particle|
|cy link-texts|Add a 2-texts cyberlink to the temp table|
|cy link-chain|Add a link chain to the temp table|
|cy link-files|Pin files from the current folder to the local node and output the cyberlinks table|
|cy follow|Follow a neuron|
|cy tweet|Add a tweet|
|cy link-random|Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)|
|cy tmp-append|Append cyberlinks to the temp table|
|cy tmp-replace|Replace cyberlinks in the temp table|
|cy tmp-clear|Empty the temp cyberlinks table|
|cy tmp-link-to|Add a text particle into the 'to' column of the temp cyberlinks table|
|cy tmp-link-from|Add a text particle into the 'from' column of the temp cyberlinks table|
|cy tmp-pin-columns|Pin values from column 'text_from' and 'text_to' to an IPFS node and fill according columns with their CIDs|
|cy tmp-remove-existed|Remove existing cyberlinks from the temp cyberlinks table|
|cy tmp-send-tx|Create a tx from the temp cyberlinks table, sign and broadcast it|
|cy tsv-copy|Copy a table from the pipe into the clipboard (in tsv format)|
|cy tsv-paste|Paste a table from the clipboard to stdin (so it can be piped further)|
|cy update-cy|Update-cy to the latest version|
|cy passport-get|Get a passport by providing a neuron's address or nick|
|cy passport-set|Set a passport's particle, data or avatar field for a given nickname|
|cy graph-download-snapshoot|Download a snapshot of cybergraph by graphkeeper|
|cy graph-to-particles|Output unique list of particles from piped in cyberlinks table|
|cy graph-to-gephi|Export the entire graph into CSV file for import to Gephi|
|cy config-view|View a saved JSON config file|
|cy config-save|Save the piped-in JSON into config file|
|cy config-activate|Activate the config JSON|
|cy search|Use the built-in node search function in cyber or pussy|
|cy cid-get-type-gateway|Obtain cid info|
|cy cid-read-or-download|Read a CID from the cache, and if the CID is absent - add it into the queue|
|cy cid-download-async|Add a cid into queue to download asynchronously|
|cy cid-download|Download cid immediately and mark it in the queue|
|cy cid-download-gateway|Download a cid from gateway immediately|
|cy watch-search-folder|Watch the queue folder, and if there are updates, request files to download|
|cy queue-check|Check the queue for the new CIDs, and if there are any, safely download the text ones|
|cy cache-clear|Clear the cache folder|
|cy balances|Check the balances for the keys added to the active CLI|
|cy ipfs-bootstrap-add-congress|Add the cybercongress node to bootstrap nodes|
|cy ibc-denoms|Check IBC denoms|
|cy validator-generate-persistent-peers-string|Dump the peers connected to the given node to the comma-separated `persistent_peers` list|
|cy help|An ordered list of cy commands|
|cy cprint|Print string colourfully|
