# cy

Cy - a [nushell](https://www.nushell.sh/) wrapper, an interface to the cyber family blockchains CLIs (bostrom, pussy) and IPFS.

## Installation

1. Install the kubo app (IPFS in Go) https://github.com/ipfs/kubo `brew install ipfs`
2. Install the nushell app https://www.nushell.sh/ `brew install nushell`
3. Launch nushell by typing `nu` in your terminal app
4. Execute `mkdir ~/cy | fetch https://raw.githubusercontent.com/cyber-prophet/cy/main/cy.nu | save ~/cy/cy.nu -f`
5. Execute: `overlay use ~/cy/cy.nu as cy -p -r`. For more information on how to use overlays check [nushell's help](https://www.nushell.sh/book/overlays.html)
6. Go through the wizzard `cy config`
7. See all the commands by entering `cy` + tab

## Commands

|command|desc|
|-|-|
|cy pin text|Pin a text particle|
|cy pin files|Pin files from the current folder to the local node, output the cyberlinks table|
|cy link texts|Add a 2-texts cyberlink to the temp table|
|cy tweet|Add a tweet|
|cy link chuck|Add a random chuck norris cyberlink to the temp table|
|cy link quote|Add a random quote cyberlink to the temp table|
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
|cy tsv paste|Paste a table from clipboard|
|cy update cy|Update cy to the latest version|
|cy passport get by address|Get a passport by providing a neuron's address|
|cy passport get by nick|Get a passport by providing a neuron's nick|
|cy passport set particle|Set a passport's particle for a given nickname|
|cy config new|Create config JSON to set env variables, to use them as parameters in cyber cli|
|cy config view|View a saved JSON config file|
|cy config save|Save the piped in JSON config file|
|cy config activate|Activate config JSON|
|cy help|An ordered list of cy commands|
