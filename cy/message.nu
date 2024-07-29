# send message to neuron with (in 1boot transaction with memo)
export def 'message-send' [
    $neuron: string
    $message: string
    --amount: string = 1boot
    --from: string
] {
    let $from = $from | default $env.cy.address

    ^$env.cy.exec tx bank send $from $neuron $amount --note (pin-text $message) --output json
    | from json
}
