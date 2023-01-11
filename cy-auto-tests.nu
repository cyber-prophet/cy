source /Users/user/cy/cy.nu

# module tests {
    def test-link-texts [] {
        let expect = [
            [from_text, to_text, from, to]; 
            [cyber, bostrom, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"]
        ]

        let result = (
            tmp-clear; 
            link-texts "cyber" "bostrom" | select from_text to_text from to
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def test-link-files [] {
        let expect = [
            [from, to]; 
            # [null, "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"], 
            # [null, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"], 
            ["QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k", "QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb"], 
            ["QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6", "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV"]
        ]
    

        let result = (
            cd /Users/user/apps-files/github/cytests/files;
            tmp-clear ;
            # pin-files
            pin-files --cyberlink_filenames_to_their_files
            | select from to
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def test-link-chuck [] {
        let expect = 1

        let result = (
            tmp-clear ;
            link-chuck | length
        )

        if $result == $expect {
            "passed"
        } else {
            $result
        }
    }

    def test-link-chuck [] {
        let expect = 1

        let result = (
            tmp-clear ;
            link-chuck | length
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
            ['link-texts' (do { test-link-texts })]
            ['link-files' (do { test-link-files })]
            ['link-chuck' (do { test-link-chuck })]
        ]
    }
# }

run-tests