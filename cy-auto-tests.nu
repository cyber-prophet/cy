overlay use ~/cy/cy.nu -p -r

# module tests {
    def 'test link texts' [] {
        print 'test link texts'
        let expect = [
            [from_text, to_text, from, to]; 
            [cyber, bostrom, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"]
        ]

        let result = (
            cy tmp clear; 
            cy link texts "cyber" "bostrom" | select from_text to_text from to
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test link files' [] {
        print 'test link files'
        let expect = [
            [from, to]; 
            # [null, "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"], 
            # [null, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"], 
            ["QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"], 
            ["QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"]
        ]
    

        let result = (
            cd /Users/user/apps-files/github/cytests/files;
            cy tmp clear ;
            # pin files
            cy pin files --link_filenames
            | select from to
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test link chuck' [] {
        print 'test link chuck'
        let expect = 1

        let result = (
            cy tmp clear ;
            cy link chuck | length
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test tmp send tx' [] {
        print 'test tmp send tx'
        let expect = 0

        cy config activate hot-pussy 

        let result = (
            cy tmp send tx | get code
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test get passport by address' [] {
        print 'test get passport by address'
            let expect = {data: {owner: "bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8", 
            approvals: [], token_uri: null, extension: {addresses: null, 
            avatar: "QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j", 
            nickname: maxim, data: null, 
            particle: "QmRumrGFrqxayDpySEkhjZS1WEtMyJcfXiqeVsngqig3ak"}}
        }

        let result = (
            cy passport get bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }
    
    export def run-tests [] {
        [
            [test result];
            ['link texts' (do { test link texts })]
            ['link files' (do { test link files })]
            ['link chuck' (do { test link chuck })]
            ['tmp send tx' (do { test tmp send tx })]
            ['passport get by address' (do { test get passport by address })]
        ]
    }
# }

run-tests