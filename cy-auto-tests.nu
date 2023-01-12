source /Users/user/cy/cy.nu

# module tests {
    def 'test link texts' [] {
        let expect = [
            [from_text, to_text, from, to]; 
            [cyber, bostrom, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"]
        ]

        let result = (
            tmp clear; 
            link texts "cyber" "bostrom" | select from_text to_text from to
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test link files' [] {
        let expect = [
            [from, to]; 
            # [null, "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"], 
            # [null, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"], 
            ["QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"], 
            ["QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"]
        ]
    

        let result = (
            cd /Users/user/apps-files/github/cytests/files;
            tmp clear ;
            # pin files
            pin files --cyberlink_filenames_to_their_files
            | select from to
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test link chuck' [] {
        let expect = 1

        let result = (
            tmp clear ;
            link chuck | length
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test tmp send tx' [] {
        let expect = 0

        let result = (
            config activate hot-pussy ;
            tx send | get code
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def 'test get passport by address' [] {
            let expect = {data: {owner: "bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8", 
            approvals: [], token_uri: null, extension: {addresses: null, 
            avatar: "QmNprvRpqVsQEqEoTRJfZUB57RHEVSK2KLPsaHSULWb28j", 
            nickname: maxim, data: null, 
            particle: "QmRumrGFrqxayDpySEkhjZS1WEtMyJcfXiqeVsngqig3ak"}}
        }

        let result = (
            cy get passport by address bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
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
            ['get passport by address' (do { test get passport by address })]
        ]
    }
# }

run-tests