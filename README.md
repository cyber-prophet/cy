# cy

Cy - a [nushell](https://www.nushell.sh/) wrapper, an interface to the cyber family blockchains CLIs (bostrom, pussy) and IPFS.

## Installation

1. Install the kubo app (IPFS in Go) https://github.com/ipfs/kubo `brew install ipfs`
2. Install the nushell app https://www.nushell.sh/ `brew install nushell`
3. Launch nushell by typing `nu` in your terminal app
4. Execute `mkdir ~/cy | fetch https://raw.githubusercontent.com/cyber-prophet/cy/main/cy.nu | save ~/cy/cy.nu -f`
5. Execute: `overlay use ~/cy/cy.nu as cy -p`. For more information on how to use overlays check [nushell's help](https://www.nushell.sh/book/overlays.html)
6. Go through the wizzard `cy config`
7. See all the commands by entering `cy` + tab

## Commands

```
cy config               Create config JSON to set env variables, to use them as parameters in cyber cli

cy pin-text             Pin a text particle
cy pin-files            Pin files from the current folder to the local node, output the cyberlinks table

cy link-texts           Add a 2-texts cyberlink to the temp table
cy link-chuck           Add a random chuck norris cyberlink to the temp table
cy link-quote           Add a random quote cyberlink to the temp table

cy tmp-append           Append cyberlinks to the temp table
cy tmp-replace          Replace cyberlinks in the temp table
cy tmp-view             View the temp cyberlinks table
cy tmp-clear            Empty the temp cyberlinks table

cy tmp-link-to          Add a text particle into 'to' column of the temp cyberlinks table
cy tmp-link-from        Add a text particle into the 'from' column of the temp cyberlinks table

cy tx-send              Create a tx from the temp cyberlinks table, sign and broadcast it

cy copy-tsv             Copy a table from the pipe into clipboard (in tsv format)
cy paste-tsv            Paste a table from clipboard

cy tmp-pin-col          Upload values from a given column ('text' by default) to the local IPFS node and add a column w
```
