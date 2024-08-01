use /Users/user/git/numd/numd

export def main [] {}

export def 'main testing' [] {
    cd numd-lazy-tests/
    ( numd run lazy-tests-links.md --result-md-path numd-links-lazy-with-output.md
        --print-block-results --table-width 200 --intermid-script lazy-test-links.nu )
}
