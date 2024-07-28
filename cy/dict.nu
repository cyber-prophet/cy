use cy-internals.nu *

# Output neurons dict
export def 'dict-neurons-view' [
    --df # output as a dataframe
    --path # output path of the dict
    --karma_bar # output karma bar
] {
    let $neurons_tags = dict-neurons-tags --wide

    cy-path graph neurons_dict.yaml
    | if $path {
        return $in
    } else {}
    | if ($in | path exists) {
        open
    } else { [[neuron nickname];
        ['bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8' 'maxim']] }
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
