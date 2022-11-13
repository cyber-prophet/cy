# cy

Cy - nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy) and IPFS

## Installation

1. Install kubo (IPFS in Go) https://github.com/ipfs/kubo
2. Install nushell https://www.nushell.sh/
3. Launch nushell by typing `nu` in your terminal app
4. Clone this repository or download the `cy.nu` file
5. Type command in nushell: `overlay use ~/path/to/cy.nu as cy -p`. For more information on how to use overlays check [nushell's help](https://www.nushell.sh/book/overlays.html)
6. Go trough wizzard `cy create config json`
7. See all the commands by entering `cy` + tab

## Commands

```
cy create config json                      Create config JSON to set env varables, to use as parameters

cy add two texts cyberlink                 Add 2 texts cyberlink to temp table
cy add chuck norris cyberlink              Add chuck norris cyberlink to temp table
cy add quote forismatic cyberlink          Add random quote cyberlink to temp table

cy paste table from clipboard              Paste table from clipboard
cy copy in table to clipboard              Copy table from the pipe into clipboard (in tsv format)

cy upload text values from column to ipfs  Upload values from the given column ('text' by default) to the local IPFS node an
cy add text particle into to column        Add text particle into 'to' column of local_cyberlinks table
cy add text particle into from column      Add text particle into 'from' column of local_cyberlinks table

cy view temp cyberlinks table              View current temp cyberlinks table
cy append in cyberlinks to temp table      Append cyberlinks from pipe or parameters to temp table
cy clear temp cyberlinks table             Empty temp cyberlinks table

cy add files from folder to ipfs           Add files from folder to ipfs, create table. Without parameters all files will be

cy create sign broadcast cyberlinks tx     Create sign and broadcast transaction

cy create and pin text particle            Create and pin text particle and pin it to local node
```
