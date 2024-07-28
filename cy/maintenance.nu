use cy-complete.nu *

# Check if all necessary dependencies are installed
export def check-requirements []: nothing -> nothing {

    ['ipfs', 'rich', 'curl', 'cyber', 'pussy']
    | each {
        if (which ($in) | is-empty) {
            $'($in) is missing'
        }
    }
    | if ($in | is-empty) {
        'all required apps are installed'
    }
}

export def --env 'use-recommended-nushell-settings' []: nothing -> nothing {
    $env.config.show_banner = false
    $env.config.table.trim.methodology = 'truncating'
    $env.config.completions.algorithm = 'fuzzy'
    $env.config.completions.quick = false
}

# Clear the cache folder
export def 'cache-clear' [] {
    cy-path cache | backup-and-echo
    make-default-folders-fn
}

# Update Cy and Nushell to the latest versions
export def 'update-cy' [
    --branch: string@'nu-complete-git-branches' = 'dev' # the branch to get updates from
] {
    # check if nushell is installed using brew
    if (brew list nushell | complete | get exit_code | $in == 0) {
        brew upgrade nushell
    } else {
        if (which cargo | length | $in > 0) {
            cargo install --features=dataframe nu
        }
    }

    cd (cy-path)
    git stash
    git checkout $branch
    git pull
    git stash pop
    cd -
}
