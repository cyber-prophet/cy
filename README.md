# cy

Cy - a [nushell](https://www.nushell.sh/) wrapper, an interface to the cyber family blockchains CLIs (bostrom, pussy) and IPFS.

## Installation

1. Install the kubo app (IPFS in Go) https://github.com/ipfs/kubo `brew install ipfs`
2. Install the nushell app https://www.nushell.sh/ `brew install nushell`
3. Launch nushell by typing `nu` in your terminal app
4. Execute `mkdir ~/cy | http get https://raw.githubusercontent.com/cyber-prophet/cy/main/cy.nu | save ~/cy/cy.nu -f`
5. Execute: `overlay use ~/cy/cy.nu as cy -p -r`. For more information on how to use overlays check [nushell's help](https://www.nushell.sh/book/overlays.html)
6. Go through the wizzard `cy config`
7. See all the commands by entering `cy` + tab

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


## Commands

|command|desc|
|-|-|
|cy pin text|Pin a text particle|
|cy pin files|Pin files from the current folder to the local node, output the cyberlinks table|
|cy link texts|Add a 2-texts cyberlink to the temp table|
|cy link chain|Add a link chain to the temp table|
|cy tweet|Add a tweet|
|cy link chuck|Add a random chuck norris cyberlink to the temp table|
|cy link quote|Add a random quote cyberlink to the temp table|
|cy link random|Make a random cyberlink from diffrent APIs|
|cy tmp view|View the temp cyberlinks table|
|cy tmp append|Append cyberlinks to the temp table|
|cy tmp replace|Replace cyberlinks in the temp table|
|cy tmp clear|Empty the temp cyberlinks table|
|cy tmp link to|Add a text particle into the 'to' column of the temp cyberlinks table|
|cy tmp link from|Add a text particle into the 'from' column of the temp cyberlinks table|
|cy tmp pin col|Pin values from a given column to IPFS node and add a column with their CIDs|
|cy tmp remove existed|Remove existed cyberlinks from the temp cyberlinks table|
|cy tmp send tx|Create a tx from the temp cyberlinks table, sign and broadcast it|
|cy tsv copy|Copy a table from the pipe into clipboard (in tsv format)|
|cy tsv paste|Paste a table from clipboard to stdin (so it can be piped further)|
|cy update cy|Update cy to the latest version|
|cy passport get|Get a passport by providing a neuron's address or nick|
|cy passport set|Set a passport's particle, data or avatar field for a given nickname|
|cy config new|Create config JSON to set env variables, to use them as parameters in cyber cli|
|cy config view|View a saved JSON config file|
|cy config save|Save the piped in JSON into config file|
|cy config activate|Activate config JSON|
|cy search|Use built in the node search function in cyber or pussy|
|cy cid download async|Add cid into queue to download asyncasynchronously|
|cy cid add queue|Download cid immediately and mark it in the queue|
|cy cid download kubo|Download cid from kubo (go-ipfs cli) immediately|
|cy cid download gateway|Download cid from gateway immediately|
|cy cid read or download|Read CID from cache, and if it is not - add it into queue|
|cy watch search folder|Watch the queue folder, and if there are updates - request files to download|
|cy queue check|Check queue for the new CIDs, and if there are CIDs - safely download the text ones|
|cy cache clear|Clear the cache folder|
|cy balances|Check the balances for the keys added to the active CLI|
|cy ipfs bootstrap add congress|Add cybercongress node to bootstrap nodes|
|cy ibc denoms|Check ibc denoms|
|cy help|An ordered list of cy commands|
|cy ber|A wrapper, to cache CLI requests|
