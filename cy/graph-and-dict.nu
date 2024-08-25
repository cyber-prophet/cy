use cy-complete.nu *
use cy-internals.nu *
use nu-utils/ [cprint]

use passport.nu [passport-get]
use query.nu [query-rank-karma]


# Download a snapshot of cybergraph
export def --env 'graph-download-snapshot' [
    --disable_update_parquet (-D) # Don't update the particles parquet file
    --neuron: string = 'graphkeeper'
] {
    set-cy-setting caching-function-force-update 'true'
    let $cur_data_cid = passport-get $neuron | get data -i
    set-cy-setting caching-function-force-update 'false'
    let $path = cy-path --create_missing graph $neuron

    let $update_info = $path
        | path join update.toml
        | if ($in | path exists) {open} else {{}}

    let $last_data_cid = $update_info | get -i last_cid

    if ($last_data_cid == $cur_data_cid) {
        print 'no updates found'
        return
    }

    print '' 'Downloading cyberlinks.csv'
    ipfs get $'($cur_data_cid)/graph/cyberlinks.csv' -o $path

    # print '' 'Downloading cyberlinks.csv'
    # ipfs get $'($cur_data_cid)/graph/cyberlinks_contracts.csv' -o $path

    let $dict_name = 'neurons_dict.yaml'
    let $dict_path = $path | path join neurons_dict.yaml
    print '' $'Downloading ($dict_name)'

    ipfs cat $'($cur_data_cid)/graph/neurons_dict.yaml'
    | from yaml
    | if ($dict_path | path exists) {
        prepend (open $dict_path)
        | uniq-by neuron
    } else {}
    | save -f $dict_path

    print '' 'Downloading particles zips'
    ipfs get $'($cur_data_cid)/graph/particles/' -o $'($path)/particles_arch/'

    let $archives = ls ($path | path join particles_arch/*.zip | into glob) | get name
    let $last_archive = $update_info
        | get -i last_archive
        | default ($archives | first)

    cprint 'Unpacking particles archive(s)'

    $archives
    | skip until {|x| $x == $last_archive}
    | each {
        |i| ^unzip -ojq $i -d ($path | path join particles safe)

        cprint $'*($i)* is unzipped'
    }

    let $path_toml = $path | path join update.toml

    $path_toml
    | if ($in | path exists) {
        open
    } else {{}}
    | upsert 'last_cid' $cur_data_cid
    | upsert 'last_archive' ($archives | last)
    | save -f $path_toml

    cprint $'The graph data has been downloaded to the *"($path)"* directory'

    # if (not $disable_update_parquet) {
    #     print 'Updating particles parquet'
    #     graph-update-particles-parquet
    # }
}

def graph_columns [] {
    ['particle_from' 'particle_to' 'neuron' 'height' 'timestamp']
}

def get_links_hasura [
    height: int
    multiplier: int
    --chunk_size: int = 1000
] {
    $"{cyberlinks\(limit: ($chunk_size), offset: ($multiplier * $chunk_size), order_by: {height: asc},
        where: {height: {_gt: ($height)}}) {(graph_columns | str join ' ')}}"
    | {'query': $in}
    | http post -t application/json $env.cy.indexer-graphql-endpoint $in
    | get data.cyberlinks
}

def 'get_links_clickhouse' [
    height: int
    multiplier: int
] {
    let $url = set-get-env 'indexer-clickhouse-endpoint'
    let $auth = set-get-env 'indexer-clickhouse-auth'
    let $chunk_size = set-get-env 'indexer-clickhouse-chunksize'

    $'SELECT particle_from, particle_to, neuron, height, timestamp
        FROM spacebox.cyberlink
        WHERE height > ($height)
        ORDER BY height
        LIMIT ($chunk_size)
        OFFSET ($chunk_size * $multiplier)
        FORMAT TSVWithNames'
    | curl -s $url -H 'Accept-Encoding: gzip' -u $auth --data-binary @-
    | gunzip -c
    | from tsv
}

def graph_csv_get_last_height [
    path_csv: path
] {
    if ($path_csv | path exists) {
        (open $path_csv -r | lines | first)
        | append (tail -n 1 ($path_csv))
        | str join (char nl)
        | from csv
        | get height.0
        | into int
    } else {
        (graph_columns | str join ',') + (char nl) # csv headers
        | save -r $path_csv

        0
    }
}

# Download the latest cyberlinks from a hasura cybernode endpoint
export def 'graph-receive-new-links' [
    filename?: string@'nu-complete-graph-csv-files' # graph csv filename in the 'cy/graph' folder
    --source: string@'nu-complete-graph-provider' = 'hasura'
] {
    let $cyberlinks_path = set-get-env cyberlinks-csv-table $filename
    let $path_csv = cy-path graph $cyberlinks_path
    let $last_height = graph_csv_get_last_height $path_csv

    mut $new_links_count = 0

    cprint $'Downloading using ($source)'

    for $mult in 0.. {
        let $links = if $source == 'hasura' {
                get_links_hasura $last_height $mult
            } else if $source == 'clickhouse' {
                get_links_clickhouse $last_height $mult
            }

        $new_links_count += ($links | length)

        if $links != [] {
            $links | to csv --noheaders | save --raw --append $path_csv

            cprint -a 0 $'(char cr)Since the last update (char lp)which was on ($last_height
                ) height(char rp) ($new_links_count) cyberlinks received!'
        } else {
            break
        }
    }
    print ''
}

# download particles missing from local cache for followed neurons or the whole graph
export def 'graph-download-missing-particles' [
    --dont_update_parquet
    --whole_graph # download particles for whole graph
] {
    if not $dont_update_parquet {
        graph-update-particles-parquet
    }

    graph-receive-new-links

    let $follow_list = dict-neurons-tags | where tag == follow | get neuron
    let $block_list = dict-neurons-tags | where tag == block | get neuron

    let $particles = graph-links-df
        | if $whole_graph {} else {
            if ($follow_list | is-empty) {
                let $input = $in

                cprint "You don't have any neurons tagged `follow`, so we'll download only missing particles that
                `maxim` (the hot key of `cyber-prophet`). If you want to download all the missing particles for
                the whole cybergraph you can use the command: *graph-download-missing-particles --whole_graph*.
                If you want to add tag `follow` to some neurons you can use the command:
                *'bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8' | dict-neurons-add follow*"

                $input
                | polars filter-with (
                    (polars col neuron)
                    | polars is-in ['bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8']
                )
            } else {
                polars filter-with (
                    (polars col neuron)
                    | polars is-in $follow_list
                )
            }
        }
        | if ($block_list | is-empty) {} else {
            polars filter-with ((polars col neuron) | polars is-in $block_list | polars expr-not)
        }
        | graph-to-particles
        | graph-add-metadata
        | particles-filter-by-type --timeout
        | print-and-pass
        | polars select particle
        | polars into-nu
        | get particle

    $particles | each {queue-cid-add $in}

    cprint --before 1 $'($particles | length) cids are added into queue'

    queue-cids-download
}

# filter system particles out
export def 'graph-filter-system-particles' [
    column = 'particle' # the column to look for system cids
    --exclude
] {
    polars filter-with (
        (polars col $column)
        | polars is-in (system_cids)
        | if $exclude {polars expr-not} else {}
    )
}

# merge two graphs together, add the `source` column
export def 'graph-merge' [
    df2
    --source_a: string = 'a'
    --source_b: string = 'b'
] {
    let $input = if ($in | polars columns | 'source' in $in) { } else {
        polars with-column (polars lit $source_a | polars as source)
    }

    let $df2_st = $df2
        | if ($df2 | polars columns | 'source' in $in) { } else {
            polars with-column (polars lit $source_b | polars as source)
        }

    $input
    | polars join $df2_st [particle_from particle_to neuron] [particle_from particle_to neuron] --full
    | polars with-column (
        polars when ((polars col source) | polars is-null) (polars col source_x)
        | polars when ((polars col source_x) | polars is-null) (polars col source)
        | polars otherwise (polars concat-str '-' [(polars col source) (polars col source_x)])
        | polars as source
    )
    | polars with-column (
        polars when ((polars col particle_from) | polars is-null) (polars col particle_from_x)
        | polars otherwise (polars col particle_from) | polars as particle_from
    )
    | polars with-column (
        polars when ((polars col particle_to) | polars is-null) (polars col particle_to_x)
        | polars otherwise (polars col particle_to) | polars as particle_to
    )
    | polars with-column (
        polars when ((polars col neuron) | polars is-null) (polars col neuron_x)
        | polars otherwise (polars col neuron) | polars as neuron
    )
    | polars with-column (
        polars when ((polars col height) | polars is-null) (polars col height_x)
        | polars otherwise (polars col height) | polars as height
    )
    | polars with-column (
        polars when ((polars col timestamp) | polars is-null) (polars col timestamp_x)
        | polars otherwise (polars col timestamp) | polars as timestamp
    )
    | polars drop particle_from_x particle_to_x neuron_x height_x timestamp_x source_x
}

# Output unique list of particles from piped in cyberlinks table
#
# > cy graph-to-particles --include_global | polars into-nu | first 2 | to yaml
# - index: 0
#   particle: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05T14:11:41
#   init-role: from
#   neuron_global: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height_global: 490
#   timestamp_global: 2021-11-05T14:11:41
#   content_s: cyber|QK3oufV
# - index: 1
#   particle: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05T14:11:41
#   init-role: to
#   neuron_global: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height_global: 490
#   timestamp_global: 2021-11-05T14:11:41
#   content_s: fuckgoogle!|z3YWjy6
export def 'graph-to-particles' [
    --from # Use only particles from the 'from' column
    --to # Use only particles from the 'to' column
    --include_global # Include column with global particles' df (that includes content)
    --include_particle_index # Include local 'particle_index' column
    --cids_only (-c) # Output one column with CIDs only
    # --init_role # Output if particle originally was in 'from' or 'to' column
] {
    let $links = graph-links-df

    let $links_columns = $links | polars columns
    if $to and $from {
        error make {msg: 'you need to use only "to", "from" or none flags at all, none both of them'}
    }

    def graph-to-particles-keep-column [
        c
        --column: string
    ] {
        $links
        | polars rename $'particle_($column)' particle
        | polars drop $'particle_(col-name-reverse $column)'
        | polars with-column [
            (polars lit ($column) | polars as 'init-role'),
        ]
    }

    let $dummy = $links
        | polars rename particle_from particle
        | polars drop particle_to
        | polars with-column (polars lit 'a' | polars as 'init-role')
        | polars fetch 0 # Create dummy polars to have something to appended to

    $dummy
    | if not $to {
        polars append --col (
            graph-to-particles-keep-column $links --column from
        )
    } else {}
    | if not $from {
        polars append --col (
            graph-to-particles-keep-column $links --column to
        )
    } else {}
    | if ('link_local_index' in $links_columns) {
        polars sort-by [link_local_index height]
    } else {
        polars sort-by [height]
    }
    | polars into-lazy
    | polars unique --subset [particle]
    | polars collect
    | if $cids_only {
        polars select particle
    } else {
        if $include_particle_index {
            polars with-column (
                polars arg-where ((polars col height) != 0) | polars as particle_index
            )
        } else {}
        | if $include_global {
            polars join (graph-particles-df) particle particle -s '_global'
        } else {}
    }
}

# In the piped in particles df leave only particles appeared for the first time
export def 'particles-keep-only-first-neuron' [ ] {
    polars join -s '_global' (
        graph-particles-df
        | polars select particle neuron
    ) particle particle
    | polars with-column (($in.neuron) == ($in.neuron_global)) --name 'is_first_neuron'
    | polars filter-with (polars col is_first_neuron)
    | polars drop neuron_global is_first_neuron
}

# Update the 'particles.parquet' file (it includes content of text files)
export def 'graph-update-particles-parquet' [
    --quiet (-q) # Disable informational messages about the saved parquet file
    --all # re-read all downloaded particles
] {
    let $parquet_path = cy-path graph particles.parquet
    let $particles_folder = $env.cy.ipfs-files-folder
    let $all_particles = graph-links-df
        | graph-to-particles
        | graph-add-metadata
        | polars select [particle neuron height timestamp content_s]

    let $particles_wanted = $all_particles
        | if $all {} else {
            particles-filter-by-type --timeout
        }

    if not $quiet {
        cprint $'Cy is updating ($parquet_path). It will take a coulple of minutes.'
    }

    let $particles_on_disk = glob ($particles_folder | path join '*.md') | path basename

    let $particles_to_open = $particles_wanted
        | polars with-column ((polars concat-str '.' [(polars col particle) (polars lit 'md')]) | polars as name)
        | polars join ($particles_on_disk | wrap name | polars into-df) name name
        | polars select name
        | polars into-nu
        | select name

    let $downloaded_particles = $particles_to_open
        | upsert content_s {
            |i| open -r ($particles_folder | path join $i.name)
            | str substring -g 0..160
        }
        | polars into-df
        | polars with-column (
            $in.name
            | polars str-slice 0 -l 46
        )
        | polars rename name particle
        | polars with-column (
            $in.content_s
            | polars str-slice 0 -l 150
            | polars replace-all -p (char nl) -r '⏎'
        )

    $particles_wanted
    | polars drop 'content_s'
    | polars join --left $downloaded_particles particle particle
    | polars with-column (
        $in.content_s
        | polars fill-null 'timeout|'
    )
    | polars collect
    | polars with-column ( # short name to make content_s unique
        $in.particle
        | polars str-slice 39 # last 7 symbols of 46-symbol cid
        | polars rename particle short_cid
    )
    | polars with-column (
        polars concat-str '|' [(polars col content_s) (polars col short_cid)]
    )
    | polars drop short_cid
    | if $all {} else {
        polars append --col (
            $all_particles
            | particles-filter-by-type --exclude --timeout
        )
    }
    | polars sort-by height particle
    | polars save ($parquet_path | backup-and-echo --mv)
    | print $in.0?
}

# Filter the graph to chosen neurons only
export def 'graph-filter-neurons' [
    ...neurons_nicks: string@'nu-complete-neurons-nicks'
] {
    let $links = graph-links-df

    $neurons_nicks
    | polars into-df
    | polars join ( dict-neurons-view --df ) '0' nick
    | polars select neuron
    | polars join ( $links ) neuron neuron
}

# Filter the graph to keep or exclude links from contracts
export def 'graph-filter-contracts' [
    --exclude
] {
    graph-links-df
    | polars filter-with (
        $in.neuron =~ '.{64}'
        | if $exclude {polars not} else {}
    )
}

# Append related cyberlinks to the piped in graph
export def 'graph-append-related' [
    --only_first_neuron (-o)
] {
    let $links_in = graph-keep-standard-columns-only --extra_columns ['link_local_index' 'init-role' 'step']
    let $columns_in = $links_in | polars columns
    let $step = if 'step' in $columns_in {
            $links_in.step | polars max | polars into-nu | get 0.step | ($in // 2) + 1 | ($in * 2) - 1
        } else {
            1
        }

    let $links = $links_in
        | if 'link_local_index' in $columns_in {} else {
            polars with-column [
                (polars arg-where ((polars col height) != 0) | $in + 100_000_000 | polars as link_local_index),
            ]
            | polars with-column (polars concat-str '' [(polars col link_local_index) (polars lit '')])
        }
        | if 'init-role' in $columns_in {} else {
            polars with-column (polars lit 'base' | polars as 'init-role')
        }
        | if 'step' in $columns_in {} else {
            polars with-column (polars lit 0 | polars as 'step')
        }

    def append_related [
        from_or_to: string
        --step: int
    ] {
        $links
        | graph-to-particles
        | if $only_first_neuron {
            particles-keep-only-first-neuron
        } else {}
        | polars select particle link_local_index init-role step
        | polars rename particle $'particle_($from_or_to)'
        | polars join (
            graph-links-df --not_in
            | graph-filter-system-particles particle_from --exclude
        ) $'particle_($from_or_to)' $'particle_($from_or_to)'
        | polars with-column [
            (polars concat-str '-' [
                (polars col 'link_local_index')
                (polars col 'init-role')
                (polars col $'particle_($from_or_to)')
                (polars lit ($from_or_to))
                (polars col $'particle_(col-name-reverse $from_or_to)')
            ]),
            ((polars col step) + (if $from_or_to == from {1} else {-1}))
        ]
    }

    $links
    | polars append --col (append_related from --step ($step))
    | polars append --col (append_related to --step ($step + 1))
    | polars sort-by [link_local_index height]
    | polars into-lazy
    | polars unique --subset [particle_from particle_to]
    | polars collect
}

# Output neurons stats based on piped in or the whole graph
export def 'graph-neurons-stats' [] {
    let $links = graph-links-df
    let $p = graph-particles-df

    let $follows = [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | polars into-df
        | polars join --left $links particle particle_from
        | polars group-by neuron
        | polars agg [
            (polars col timestamp | polars count | polars as 'follows')
        ]
        | polars sort-by follows --reverse [true]

    let $followers = [['particle'];['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx']] # follow
        | polars into-df
        | polars join --left $links particle particle_from
        | polars join $p particle_to particle --suffix '2' # it was working before `polars` 0.94
        | polars with-column (
            $in | polars select content_s | polars replace -p '\|.*' -r ''
        )
        | polars group-by content_s
        | polars agg [
            (polars col timestamp | polars count | polars as 'followers')
        ]
        | polars rename content_s neuron

    let $tweets = [['particle'];['QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx']] # tweet
        | polars into-df
        | polars join --left $links particle particle_from
        | polars group-by neuron
        | polars agg [
            (polars col timestamp | polars count | polars as 'tweets')
        ]

    $links
    | polars group-by neuron
    | polars agg [
        (polars col timestamp | polars count | polars as 'links_count')
        (polars col timestamp | polars min | polars as 'first_link')
        (polars col timestamp | polars max | polars as 'last_link')
    ]
    | polars sort-by links_count --reverse [true] # cygraph neurons activity
    | polars join --left $followers neuron neuron
    | polars join --left $follows neuron neuron
    | polars join --left $tweets neuron neuron
    | polars fill-null 0
    | polars join --left ( dict-neurons-view --df --karma_bar) neuron neuron
    | polars select ($in | polars columns | prepend [nickname links_count last_link] | uniq)
    | polars collect
}

# Output graph stats based on piped in or the whole graph
export def 'graph-stats' [] {
    let $links = graph-links-df | polars with-column (polars lit a | polars as dummyc)
    let $p = graph-particles-df
    let $p2 = $links | graph-to-particles | graph-add-metadata

    def dfr_countrows [] {
        polars with-column (polars lit 1) | polars select literal | polars sum | polars into-nu | get literal.0
    }

    let $n_links_unique = $links
        | polars into-lazy
        | polars unique --subset [particle_from particle_to]
        | polars collect
        | dfr_countrows

    let $n_particles_unique = $p2 | dfr_countrows

    let $n_particles_not_downloaded = $p2
        | particles-filter-by-type --timeout
        | dfr_countrows

    let $n_particles_non_text = $p2
        | polars filter-with ($in.content_s =~ '^"MIME type"')
        | dfr_countrows

    let $follows = $links
        | polars filter-with (
            (polars col particle_from)
            | polars is-in ['QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx'] # follow
        )
        | dfr_countrows

    let $tweets = $links
        | polars filter-with (
            (polars col particle_from)
            | polars is-in ['QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx'] # tweet
        )
        | dfr_countrows

    let $stats_by_source = if ($links | polars columns | 'source' in $in) {
            $links
            | polars group-by source
            | polars agg [(polars col source | polars count | polars as source_count)]
            | polars sort-by source
            | polars into-nu
            | transpose --ignore-titles --as-record --header-row
            | {source: $in}
        } else {{}}

    $links
    | polars group-by dummyc
    | polars agg [
        (polars col neuron | polars n-unique | polars as 'neurons')
        (polars col timestamp | polars count | polars as 'links')
        (polars col timestamp | polars min | polars as 'first')
        (polars col timestamp | polars max | polars as 'last')
    ]
    | polars collect
    | polars into-nu
    | reject dummyc
    | get 0
    | {links: $in}
    | upsert neurons {|i| $i.links.neurons}
    | move neurons --before links
    | reject links.neurons
    | upsert links.unique $n_links_unique
    | upsert links.follows $follows
    | upsert links.tweets $tweets
    | upsert particles.unique $n_particles_unique
    | upsert particles.text ($n_particles_unique - $n_particles_not_downloaded - $n_particles_non_text)
    | upsert particles.nontext $n_particles_non_text
    | upsert particles.not_downloaded $n_particles_not_downloaded
    | merge $stats_by_source
}

# Export a graph into CSV file for import to Gephi
export def 'graph-to-gephi' [] {
    let $links = graph-links-df
    let $particles = $links
        | graph-to-particles --include_global

    let $t1_height_index = $links.height
        | polars append --col $particles.height # Particles might be created before they appear in the filtered graph
        | polars unique
        | polars with-column (
            polars arg-where ((polars col height) != 0) | polars as height_index
        )

    let $height_index_max = $t1_height_index
        | polars shape
        | polars into-nu
        | get rows.0

    $links
    | polars join --left $t1_height_index height height
    | polars with-column (
        polars concat-str '' [
            (polars lit '<[')
            (polars col height_index)
            (polars lit ($',($height_index_max)]>'))
        ]
        | polars as Timeset
    )
    | polars rename [particle_from particle_to] [source target]
    | polars save (cy-path export !gephi_cyberlinks.csv)

    $particles
    | polars join --left $t1_height_index height height
    | polars with-column (
        (polars col particle) | polars as cid
    ) | polars rename [particle content_s] [id label]
    | polars with-column (
        polars concat-str '' [
            (polars lit '<[')
            (polars col height_index)
            (polars lit ($',($height_index_max)]>'))
        ]
        | polars as Timeset
    )
    | polars into-nu
    | move id label cid --before height
    | save -f (cy-path export !gephi_particles.csv)
}

# Logseq export WIP
export def 'graph-to-logseq' [
    # --path: string
] {
    let $links = graph-links-df | print-and-pass
    let $particles = $links
        | graph-to-particles --include_global
        | print-and-pass

    let $path = cy-path export $'logseq_(now-fn)'
    mkdir ($path | path join pages)
    mkdir ($path | path join journals)

    $particles
    | polars into-nu
    | par-each {|p|
        # print $p.particle
        $"author:: [[($p.nick)]]\n\n- (
            do -i {open ($env.cy.ipfs-files-folder | path join $'($p.particle).md')
            | default "timeout"
        } )\n- --- \n- ## cyberlinks from \n" |
        save ($path | path join pages $'($p.particle).md')
    }

    $links
    | polars into-nu
    | each {|c|
        $"\t- [[($links.particle_to)]] ($links.height) [[($links.nick?)]]\n" |
        save -a ($path | path join pages $'($links.particle_from).md')
    }
}

# Output particles into txt formatted feed
export def 'graph-to-txt-feed' [] {
    graph-to-particles
    | particles-keep-only-first-neuron
    | graph-add-metadata
    # | polars filter-with ($in.content_s | polars is-null | polars not)
    | polars sort-by [height]
    | polars into-nu
    | each {|i| echo_particle_txt $i}
}

# Export piped-in graph to a CSV file in cosmograph format
export def 'graph-to-cosmograph' [] {
    graph-add-metadata
    | polars rename timestamp time
    | polars select ($in | polars columns | prepend [content_s_from content_s_to] | uniq)
    | polars into-nu
    | save -f (
        cy-path 'export' $'cybergraph-in-cosmograph(now-fn).csv'
        | print-and-pass {cprint $'You can upload the file to *https://cosmograph.app/run* ($in)'}
    )
}

# Export piped-in graph into graphviz format
export def 'graph-to-graphviz' [
    --options: string = ''
    --preset: string@nu-complete-graphviz-presets = ''
] {
    graph-add-metadata --escape_quotes --new_lines
    | polars select 'content_s_from' 'content_s_to'
    | $in.content_s_from + ' -> ' + $in.content_s_to + ';'
    | polars into-nu
    | rename links
    | get links
    | str join (char nl)
    | "digraph G {\n" + $options + "\n" + $in + "\n}"
    | if $preset == '' { } else {
        let $input = $in
        let $filename = cy-path export $'graphviz_($preset)_(now-fn).svg'

        let $params = ['-Tsvg' $'-o($filename)']

        $input | ^($preset) ...$params
        $filename
    }
}

# Add content_s and neuron's nicknames columns to piped in or the whole graph df
#
# > cy graph-filter-neurons maxim@n6r76m8 | cy graph-add-metadata | dfr into-nu | first 2 | to yaml
# - index: 0
#   nick: maxim@n6r76m8
#   height: 87794
#   content_s_from: tweet|R5V4Rvx
#   content_s_to: '"MIME type" = "image/svg+xml"⏎Size = "79336"⏎|6wZUHYo'
#   timestamp: 2021-11-11 10:36:24
#   particle_to: QmaxuSoSUkgKBGBJkT2Ypk9zWdXor89JEmaeEB66wZUHYo
#   particle_from: QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx
#   neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
# - index: 1
#   nick: maxim@n6r76m8
#   height: 88371
#   content_s_from: avatar|TwBrmTs
#   content_s_to: '"MIME type" = "image/svg+xml"⏎Size = "68266"⏎|95aKr4t'
#   timestamp: 2021-11-11 11:31:54
#   particle_to: QmYnLm5MFGFwcoXo65XpUyCEKX4yV7HbCAZiDZR95aKr4t
#   particle_from: Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs
#   neuron: bostrom1nngr5aj3gcvphlhnvtqth8k3sl4asq3n6r76m8
export def 'graph-add-metadata' [
    --escape_quotes
    --new_lines
] {
    let $links = graph-links-df
        | graph-keep-standard-columns-only --extra_columns [
            'particle', 'link_local_index', 'init-role', 'step'
        ]

    let $p = graph-particles-df
        | polars select particle content_s
        | if $escape_quotes {
            polars with-column (
                $in.content_s
                | polars replace-all --pattern '"' --replace '\"'
                | polars replace-all --pattern '^(.*)$' --replace '"$1"'
            )
        } else {}
        | if $new_lines {
            polars with-column (
                $in.content_s
                | polars replace-all --pattern '⏎' --replace (char nl)
            )
        } else {}

    let $links_columns = $links | polars columns

    $links
    | if 'particle_to' in $links_columns {
        polars join --left $p particle_to particle
        | polars rename content_s content_s_to
    } else {}
    | if 'particle_from' in $links_columns {
        polars join --left $p particle_from particle
        | polars rename content_s content_s_from
    } else {}
    | if 'particle' in $links_columns {
        polars join --left $p particle particle
    } else {}
    | polars fill-null 'timeout|'
    | polars drop height
    | polars append $links.height
    | if 'neuron' in $links_columns {
        polars join --left (
            dict-neurons-view --df
            | polars select neuron nick
        ) neuron neuron
    } else {}
    | polars select ($in | polars columns | reverse)
}

# Output a full graph, or pass piped in graph further
#
# > cy graph-links-df | polars into-nu | first 1 | to yaml
# - index: 0
#   particle_from: QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
#   particle_to: QmbVugfLG1FoUtkZqZQ9WcwTLe1ivmcE9yMVGvuz3YWjy6
#   neuron: bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt
#   height: 490
#   timestamp: 2021-11-05T14:11:41
export def 'graph-links-df' [
    filename?: string@'nu-complete-graph-csv-files' # graph csv filename in the 'cy/graph' folder or a path to the graph
    --not_in # don't catch pipe in
    --exclude_system # exclude system particles in from column (tweet, follow, avatar)
] {
    let $input = $in
    let $cyberlinks_path = set-get-env cyberlinks-csv-table $filename
    let $input_type = $input | describe

    if (
        $not_in or
        not ($filename | is-empty) or
        ($filename | is-empty) and $input_type == 'nothing'
    ) {
        return (graph-open-csv-make-df (cy-path graph $cyberlinks_path))
    }


    let $df = $input
        | if ($input_type =~ '^table') {
            polars into-df
        } else {}

    let $df_columns = $df | polars columns
    let $existing_graph_columns = $df_columns | where $it in [particle_from particle_to neuron]

    if (
        ($existing_graph_columns | length) == 3
        or ('particle' in $df_columns)
    ) {
        $df
    } else if ($existing_graph_columns | length) == 0 {
        print $input
        error make {msg: $'there are no graph columns in ($df_columns)'}
    } else {
        graph-open-csv-make-df (cy-path graph $cyberlinks_path) # fixme - take it out
        | polars join --inner $df $existing_graph_columns $existing_graph_columns
    }
}


export def 'graph-keep-standard-columns-only' [
    standard_columns: list = [particle_from, particle_to, neuron, height, timestamp]
    --extra_columns: list = []
    --out # reject standard columns
] {
    let $input = $in
    let $in_columns = $input | polars columns
    let $out_columns = $in_columns
        | where $it in ($standard_columns | append $extra_columns)

    $input
    | if $out {
        polars drop ...($out_columns)
    } else {
        polars select $out_columns
    }
}

def 'graph-open-csv-make-df' [
    path: path
    --datetime
] {
    polars open $path --infer-schema 10000
    | if $datetime {
        polars with-column (
            $in.timestamp
            | polars as-datetime '%Y-%m-%dT%H:%M:%S' -n
            | polars rename datetime timestamp
        )
    } else {}
}

export def 'graph-particles-df' [] {
    cy-path graph particles.parquet
    | if ($in | path exists) {
        polars open $in
    } else {
        cprint `particles.parquet doesn't exist. Use *graph-update-particles-parquet*`

        first_cyberlink
    }
}

export def 'particles-filter-by-type' [
    --exclude
    --media
    --timeout
] {
    let $input = $in
    let $filter_regex = if $media {
            '"MIME'
        } else {}
        | if $timeout {
            append 'timeout\|'
        } else {}
        | str join '|'
        | '^' + $in

    $input
    | polars filter-with (
        $in.content_s =~ $filter_regex
        | if $exclude {polars not} else {}
    )
}

def 'system_cids' [] {
    [
        'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx',
        'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx',
        'Qmf89bXkJH9jw4uaLkHmZkxQ51qGKfUPtAMxA8rTwBrmTs'
    ]
}

def 'first_cyberlink' [] {
    [
        [index, particle, neuron, height, timestamp, content_s];
        [0, "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV", "bostrom1ymprf45c44rp9k0g2r84w2tjhsq7kalv98rgpt",
        490, "2021-11-05 14:11:41", "cyber|QK3oufV"]
    ]
    | polars into-df
}

### dict

# Output neurons dict
export def 'dict-neurons-view' [
    --df # output as a dataframe
    --path # output path of the dict
    --karma_bar # output karma bar
] {
    let $neurons_tags = dict-neurons-tags --wide

    dict-neurons-bare --path=$path
    | reject -i ...($neurons_tags | columns | where $it != 'neuron')
    | join --outer $neurons_tags neuron
    | if $karma_bar {
        default 0 karma
        | into float karma
        | normalize karma
        | upsert karma_norm_bar {|i| bar $i.karma_norm --width ('karma_norm_bar' | str length)}
        | move karma_norm karma_norm_bar --after karma
    } else {}
    | if $df {
        fill non-exist
        | reject -i addresses # quick fix for failing df conversion
        | to yaml
        | str replace -a 'null' "''" # dataframes errors on `object` type columns (that contains nulls)
        | from yaml
        | polars into-df
    } else { }
}

# Add piped in neurons to YAML-dictionary with tag and category
export def 'dict-neurons-add' [
    tag: string = '' # tag to add to neuron
    --category: string = 'default' # category of tag to write to dict
] {
    let $input = $in
    let $desc = $input | describe
    let $path_csv = cy-path graph neurons_dict_tags.csv

    if $input == null {
        error make {
            msg: 'you should pipe a list, a table or a dataframe containing `neuron` column to this command'
        }
    }

    let $candidate = $input
        | if ($desc == 'list<string>') {
            wrap neuron
        } else if ($desc == 'dataframe') {
            polars into-nu
        } else if ($desc == 'string') {
            [{neuron: $in}]
        } else { }
        | select neuron

    let $validated_neurons = $candidate
        | where (is-neuron $it.neuron)

    $validated_neurons
    | upsert tag $tag
    | upsert category $category
    | upsert timestamp (date now | debug)
    | if ($path_csv | path exists) {
        to csv --noheaders
    } else {
        to csv
    }
    | save --raw --append $path_csv
}

# Output dict-neurons tags
export def 'dict-neurons-tags' [
    --path # return the path of tags file
    --wide # return wide table with categories as columns
    --timestamp # output the timestamp of the last neuron's update
] {
    let $path_csv = cy-path graph neurons_dict_tags.csv
    if $path { return $path_csv }

    if not ($path_csv | path exists) {
        [[neuron, tag, category, timestamp];
        ["bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8", follow, default, (date now | debug)]]
        | if $timestamp {} else {reject -i timestamp}
        | save $path_csv
    }

    open $path_csv
    | if $wide {
        reject -i timestamp
        | uniq-by neuron category
        | group-by category
        | items {|k v| $v | reject category | rename neuron $k}
        | reduce {|i acc| $acc | join --outer $i neuron}
    } else {}
}

# Update neurons YAML-dictionary
export def 'dict-neurons-update' [
    --passport # Update passport data
    --balance # Update balances data
    --karma # Update karma
    --all (-a) # Update passport, balance, karma
    --neurons_from_graph # Update info for neurons from graph, and not from current dict
    --threads (-t) = 30 # Number of threads to use for downloading
    --dont_save # Don't update the file on a disk, just output the results
    --quiet (-q) # Don't output results table
] {
    if $neurons_from_graph {
        graph-links-df
        | polars select neuron
        | polars unique
        | polars join --left (dict-neurons-view --df) neuron neuron
        | polars into-nu
    } else {
        dict-neurons-view
    }
    | filter {|i| is-neuron $i.neuron}
    | if $passport or $all {
        par-each -t $threads {|i|
            $i | merge (passport-get $i.neuron --quiet | reject -i 'owner')
        }
    } else {}
    | if $balance {
        par-each -t $threads {|i|
            $i | merge (
                tokens-balance-get $i.neuron
                | transpose --ignore-titles --as-record --header-row
            )
        }
    } else {}
    | if $karma or $all { # kamra_norm is calculated below
        par-each -t $threads {|i|
            $i | merge (query-rank-karma $i.neuron)
        }
    } else {}
    | par-each {
        upsert nick {|i|
            [
                ($i.my_alias? | if $in in [null ''] {null} else {$in + '_'})
                ($i.nickname?) # no nickname were parsed
                '@'
                ($i.neuron | str substring (-7..))
            ]
            | where $it not-in [null '']
            | str join
        }
    }
    | if $dont_save {} else {
        let $input = $in

        dict-neurons-view
        | prepend $input
        | uniq-by neuron
        | save -f (cy-path graph neurons_dict.yaml | backup-and-echo)

        $input
    }
    | if $quiet { null } else { }
}
