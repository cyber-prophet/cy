
export def 'nu-complete-random-sources' [] {
    ['chucknorris.io' 'forismatic.com']
}

export def 'nu-complete-search-functions' [] {
    ['search-auto-refresh' 'search-with-backlinks', 'search-sync']
}

export def 'nu-complete-neurons-nicks' [] {
    dict-neurons-view | get nick
}

export def 'nu-complete-config-names' [] {
    ls (cy-path config)
    | sort-by modified
    | select name
    | where ($it.name | path parse | get extension) == 'toml'
    | upsert address {|i| open $i.name | get address}
    | sort-by name -r
    | upsert name {|i| $i.name | path parse | get stem}
    | rename value description
}

export def 'nu-complete-git-branches' [] {
    ['main', 'dev']
}

export def 'nu-complete-executables' [] {
    ['cyber' 'pussy']
}

export def 'nu-complete dict-nicks' [] {
    dict-neurons-view
    | select -i nickname neuron
    | uniq-by nickname
    | where nickname not-in [null '' '?']
    | rename value description
}

export def 'nu-complete-settings-variants' [] {
    open (cy-path kickstart settings-variants.yaml)
    | items {|key value| {value: $key, description: $value.description?}}
}

export def 'nu-complete-settings-variant-options' [
    context: string
] {
    open (cy-path kickstart settings-variants.yaml)
    | get -i ($context | str trim | split row ' ' | last)
    | get variants
}

export def 'nicks-and-keynames' [] {
    nu-complete key-names
    | append (nu-complete dict-nicks)
}

export def 'nu-complete-bool' [] {
    [true, false]
}

export def 'nu-complete-props' [] {
    let term_size = term size | get columns

    governance-view-props --dont_format
    | reverse
    | each {|i| {
        value: $i.proposal_id,
        description: $'($i.content.title | str substring 0..$term_size)($i | governance-prop-summary)'
    }}
}

export def 'nu-complete-authz-types' [] {
    open (cy-path dictionaries tx_message_types.csv)
    | get type
}

export def 'nu-complete-validators-monikers' [ ] {
    query-staking-validators | select moniker operator_address | rename value description
}

export def 'nu-complete-graph-csv-files' [] {
    ls -s (cy-path graph '*.csv' | into glob)
    | sort-by modified -r
    | select name size
    | upsert size {|i| $i.size | into string}
    | rename value description
}

export def 'nu-complete-links-csv-files' [] {
    ls -s (cy-path mylinks '*.csv' | into glob)
    | where name !~ '_cyberlinks_archive.csv'
    | update name {|i| $i.name | str replace -r '\.csv$' ''}
    | sort-by modified -r
    | select name size
    | upsert size {|i| $i.size | into string}
    | rename value description
}

export def 'nu-complete-graph-provider' [] {
    ['hasura' 'clickhouse']
}

export def 'nu-complete-graphviz-presets' [] {
    [ 'sfdp', 'dot' ]
}
