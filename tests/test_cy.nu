use ~/cy/cy.nu 
use std 'assert equal'

export def 'test_link_texts' [] {
    use ~/cy/cy.nu 
    let expect = [
        [from_text, to_text, from, to]; 
        [cyber, bostrom, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"]
    ]

    let result = (
        cy tmp clear; 
        cy link texts "cyber" "bostrom" | select from_text to_text from to
    )

    assert equal $expect $result
}

export def 'test_link_files' [] {
    use ~/cy/cy.nu 
    let expect = [
        [from, to]; 
        ["QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"], 
        ["QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"]
    ]

    let result = (
        cd /Users/user/apps-files/github/cytests/files;
        cy tmp clear ;
        cy pin files --link_filenames
        | select from to
    )

    assert equal $result $expect 
}

export def 'test_link_random' [] {
    use ~/cy/cy.nu 
    let expect = 1

    let result = (
        cy tmp clear ;
        cy link random | length
    )

    assert equal $expect $result
}

export def 'test_tmp_send_tx' [] {
    use ~/cy/cy.nu 
    print 'test tmp send tx'
    let expect = 0

    cy config activate hot-pussy 
    cy tmp clear ;
    cy link random

    let result = (
        cy tmp send tx | get code
    )

    assert equal $result $expect 
}

export def 'test_get_passport_by_address' [] {
    use ~/cy/cy.nu 
    print 'test get passport by address'
        cy config activate hacks+cyber
        let expect = {data: {owner: "bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8", 
        approvals: [], token_uri: null, extension: {addresses: null, 
        avatar: "QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j", 
        nickname: maxim, data: null, 
        particle: "QmRumrGFrqxayDpySEkhjZS1WEtMyJcfXiqeVsngqig3ak"}}
    }

    let result = (
        cy passport get bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
    )

    assert equal $result $expect
}