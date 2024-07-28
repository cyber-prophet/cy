
def 'search-sync' [
    query
    --page (-p): int = 0
    --results_per_page (-r): int = 10
] {
    let $cid = if (is-cid $query) {
        $query
    } else {
        pin-text $query --only_hash
    }

    print $'searching ($env.cy.exec) for ($cid)'

    caching-function query rank search $cid $page 10
    | get result
    | upsert particle {|i|
        let $particle = ^ipfs cat $i.particle -l 400

        $particle
        | file -
        | if (
            $in | str contains '/dev/stdin: ASCII text'
        ) {
            $"($particle | mdcat --columns 100 -)(char nl)(ansi grey)($i.particle)(ansi reset)"
        } else {
            $"Non-text particle. Is not supported yet.(char nl)(ansi grey)($i.particle)(ansi reset)"
        }
    }
    | select particle rank
}

def 'search-with-backlinks' [
    query: string
    --page (-p): int = 0
    --results_per_page (-r): int: int = 10
] {
    let $cid = pin-text $query --only_hash

    def search_or_back_request [
        type: string
    ] {
        caching-function query rank $type $cid $page $results_per_page
        | get -i result
        | if $in == null {
            null
        } else {
            select particle rank
            | par-each {
                |$r| $r
                | upsert particle (cid-read-or-download $r.particle)
            }
            | upsert source $type
            | sort-by rank -r -n
        }
    }

    print $'searching ($env.cy.exec) for ($cid)'

    search_or_back_request search
    | append (search_or_back_request backlinks)
}

def 'search-auto-refresh' [
    query: string
    --page (-p): int = 0
    --results_per_page (-r): int = 10
] {
    let $cid = pin-text $query --only_hash

    print $'searching ($env.cy.exec) for ($cid)'

    let $out = ^($env.cy.exec) query rank search $cid $page $results_per_page ...[
            --output json
            --node $env.cy.rpc-address
        ] | complete

    let $results = if $out.exit_code == 0 {
        $out.stdout | from json
    } else {
        null
    }

    if $results == null {
        print $'there is no search results for ($cid)'
        return
    }

    $results | save (cy-path cache search '($cid)-(date now|into int).json')

    clear
    print $'Searching ($env.cy.exec) for ($cid)'

    serp1 $results

    watch (cy-path cache queue_cids_to_download) {||
        clear
        print $'Searching ($env.cy.exec) for ($cid)'
        serp1 $results
    }
}

export def search-walk [
    query: string
    --results_per_page: int = 100
    --duration: duration = 2min
] {
    let $cid = pin-text $query --only_hash

    def serp [page: int] {
        caching-function query rank search $cid $page $results_per_page --cache_validity_duration $duration
        | upsert page $page
    }

    generate {|i|
        {out: $i.result}
        | if ($i.pagination.total / $results_per_page - 1 | math ceil) > $i.page {
            upsert next (serp ($i.page + 1))
        } else {}
    } {
        result: [],
        page : -1,
        pagination: {total: $results_per_page}
    }
    | flatten
    | into int rank
}

# Use the built-in node search function in cyber or pussy
export def 'search' [
    query
    --page (-p): int = 0
    --results_per_page (-r): int = 10
    --search_type: string@'nu-complete-search-functions' = 'search-with-backlinks'
] {
    match $search_type {
        'search-with-backlinks' => {
            search-with-backlinks $query --page $page --results_per_page $results_per_page
        }
        'search-auto- =>refresh' => {
            search-auto-refresh $query --page $page --results_per_page $results_per_page
        }
        'search-sync' => {
            search-sync $query --page $page --results_per_page $results_per_page
        }
    }
}

def serp1 [
    results
    --pretty
] {
    $results
    | get result
    | upsert particle {
        |i| cid-read-or-download $i.particle
    }
    | select particle rank
}

# Watch the queue folder, and if there are updates, request files to download
export def 'watch-search-folder' [] {
    watch (cy-path cache search) {|| queue-cids-download }
}
