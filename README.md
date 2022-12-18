# cy

Cy - nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy) and IPFS

## Installation

1. Install the kubo app (IPFS in Go) https://github.com/ipfs/kubo
2. Install the nushell app https://www.nushell.sh/
3. Launch nushell by typing `nu` in your terminal app
4. Clone this repository or download the `cy.nu` file
5. Type command in nushell: `overlay use ~/path/to/cy.nu as cy -p`. For more information on how to use overlays check [nushell's help](https://www.nushell.sh/book/overlays.html)
6. Go trough a wizzard `cy create config json`
7. See all the commands by entering `cy` + tab

## Commands

```
cy config                Create config JSON to set env varables, to use as parameters

cy pin-text              Pin text particle to the local node
cy pin-files             Add files from folder (all or only listed as arguments) to ipfs, output the cyberlinks table

cy link-texts            Add 2 texts cyberlink to temp table
cy link-chuck            Add chuck norris cyberlink to temp table
cy link-quote            Add random quote cyberlink to temp table

cy temp-append           Append cyberlinks to temp table
cy temp-view             View current temp cyberlinks table
cy temp-clear            Empty temp cyberlinks table

cy tx-send               Create tx from temp table, sign and broadcast transaction

cy copy-tsv              Copy table from the pipe into clipboard (in tsv format)
cy paste-tsv             Paste table from clipboard

cy pin-column            Upload values from the given column ('text' by default) to the local IPFS node and add the column w

cy link-to               Add text particle into 'to' column of temp cyberlinks table
cy link-from             Add text particle into 'from' column of temp cyberlinks table
```
