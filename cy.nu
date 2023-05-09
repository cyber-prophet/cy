# Cy - the nushell wrapper, interface to cyber family blockchains CLIs (Bostrom, Pussy) and go-ipfs (kubo)
# Git: https://github.com/cyber-prophet/cy
#
# Install/update to the latest stable version
# > mkdir ~/cy | http get https://raw.githubusercontent.com/cyber-prophet/cy/main/cy.nu | save ~/cy/cy.nu -f
#
# Use:
# > overlay use ~/cy/cy.nu -p -r

export def main [] { help }

# start with this function
export def check_requirements [] {
    ['ipfs', 'bat', 'curl', 'pueue', 'cyber', 'pussy']
    | each {
        |i| if ((which ($i) | length) == 0) {
            print $'($i) is missing'
        } else {
            print $'($i) is installed'
        }
    }
}

export-env {
    # banner2
    let $config_folder = ("~/.config/cy/" | path expand)
    let $default_cy_folder = ('~/cy/' | path expand)

    mkdir $config_folder

    let $config_file_path = $"($config_folder)/cy_config.toml"

    let $config = (try {
        open $config_file_path
    } catch {
        print "Creating '~/.config/cy/cy_config.toml' with default settings."

        {
            'path': $default_cy_folder
            'ipfs-files-folder': $"($default_cy_folder)/graph/particles/safe/"
            'ipfs-download-from': 'gateway'
        } | save $config_file_path
    })

    let-env cyfolder = ($config | get 'path')

    let-env cy = (
        try {
            $config
            | merge (
                open $"($env.cyfolder)/config/($config | get 'config-name').toml"
            )
            | sort
        } catch {
            $'Cy config file was not found. Run "cy config new"' | cprint -c green_underline
            $nothing
        }
    )
}

# Pin a text particle
#
# cy pin text "cyber"
# QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV
export def 'pin text' [
    text_param?: string
    --only_hash
] {
    let $text = ($in | default $text_param | into string)
    let $text = (if ($text | path exists) {
        open $text
    } else {
        $text
    })

    if (is-cid $text) {
        $text
    } else if $only_hash {
        $text
        | ipfs add -Q --only-hash
        | str replace '\n' ''
    } else {
        let $cid = if (
            ($env.cy.ipfs-storage == 'kubo') or ($env.cy.ipfs-storage == 'both')
        ) {
            $text
            | ipfs add -Q
            | str replace '\n' ''
        }

        if (($env.cy.ipfs-storage == 'cybernode') or ($env.cy.ipfs-storage == 'both')) {
            $text
            | curl --silent -X POST -F file=@- 'https://io.cybernode.ai/add'
            | from json
            | get cid
        } else { $cid }
    }
}

# Pin files from the current folder to the local node and output the cyberlinks table
# cy pin files .
export def 'pin files' [
    ...files: string                # filenames to add into the local ipfs node
    --link_filenames (-n)
    --disable_append (-d)
] {
    let $files = (
        if $files == [] {
            ls | where type == file | get name
        } else {
            $files
        }
    )

    let $cid_table = (
        $files
        | each {|f| ipfs add $f -Q | str replace '\n' ''}
        | wrap to
    )

    let $out_table = (
        if $link_filenames {
            $files
            | each { |it| pin text $it }
            | wrap from
            | merge $cid_table
        } else {
            $cid_table
        }
    )

    if $disable_append {
        $out_table
    } else {
        $out_table
        | tmp append
    }
}

# Add a 2-text cyberlink to the temp table
export def 'link texts' [
    text_from
    text_to
    --disable_append (-d)
] {
    let $cid_from = (pin text $text_from)
    let $cid_to = (pin text $text_to)

    let $out_table = (
        [
            ['from_text' 'to_text' 'from' 'to'];
            [$text_from $text_to $cid_from $cid_to]
        ]
    )

    print $out_table.0

    if $disable_append {
        $out_table
    } else {
        $out_table | tmp append
    }
}

# Add a link chain to the temp table
export def 'link chain' [
    ...rest
] {
    let $count = ($rest | length)
    if $count < 2 {
        return $'($count) particles were submitted. We need 2 or more'
    }

    (
        0..($count - 2) # The number of paris of cids to iterate through
        | each {
            |i| link texts ($rest | get $i) ($rest | get ($i + 1))
        }
    )
}

# Follow a neuron
export def 'follow' [
    neuron
] {
    if not (is-neuron $neuron) {
        print $"($neuron) doesn't look like address"
        return
    }

    link texts 'QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx' 'bostrom1v5x5vl4c0zjua37ymqjy4267fy9m6x8yvzvkfp'
}

# Add a tweet
export def 'tweet' [
    text_to
    --disable_send (-d)
] {
    # let $cid_from = pin text "tweet"
    let $cid_from = 'QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx'
    let $cid_to = (pin text $text_to)

    let $out_table = (
        [
            ['from_text', 'to_text', from, to];
            ['tweet', $text_to, $cid_from, $cid_to]
        ]
    )

    if (not $disable_send) {
        $out_table | tmp send tx
    } else {
        $out_table | tmp append
    }
}

# Add a random chuck norris cyberlink to the temp table
def 'link chuck' [] {
    # let $cid_from = (pin text 'chuck norris')
    let $cid_from = 'QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1'

    let $quote = (
        "> " + (http get https://api.chucknorris.io/jokes/random).value +
        "\n\n" + "via [Chucknorris.io](https://chucknorris.io)"
    )

    $quote | cprint -f "="

    let $cid_to = (pin text $quote)

    let $_table = (
        [
            ['from_text' 'to_text' from to];
            ['chuck norris' $quote $cid_from $cid_to]
        ]
    )

    $_table | tmp append --dont_show_out_table
}

# Add a random quote cyberlink to the temp table
def 'link quote' [] {
    let $json = (
        http get -r https://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json
        | str replace "\\\\" ""
        | from json
    )

    let $quoteAuthor = (
        if $json.quoteAuthor == "" {
            ""
        } else {
            "\n\n>> " + $json.quoteAuthor
        }
    )

    let $quote = (
        "> " + $json.quoteText +
        $quoteAuthor +
        "\n\n" + "via [forismatic.com](https://forismatic.com)"
    )

    $quote | cprint -f '='

    # link texts 'quote' $quote
    link texts 'QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna' $quote
}

def "nu-complete random sources" [] {
    ['chucknorris.io' 'forismatic.com']
}

# Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)
export def 'link random' [
    source?: string@"nu-complete random sources"
    n: int = 1 # Number of links to append
] {
    mut $table = $nothing
    for x in 1..$n {
        if $source == 'forismatic.com' {
            $table = (link quote)
        } else {
            $table = (link chuck)
        }
    }
    $table 
}


# View the temp cyberlinks table
export def 'tmp view' [
    --quiet (-q) # Don't print info
] {
    let $tmp_links = (open $"($env.cyfolder)/cyberlinks_temp.csv")

    let $links_count = ($tmp_links | length)

    if (not $quiet) {
        if $links_count == 0 {
            $"The temp cyberlinks table ($"($env.cyfolder)/cyberlinks_temp.csv") is empty." | cprint -c yellow
            $"You can add cyberlinks to it manually or by using commands like 'cy link texts'" | cprint
        } else {
            $"There are ($links_count) cyberlinks in the temp table:" | cprint -c green_underline
        }
    }

    $tmp_links
}

# Append cyberlinks to the temp table
export def 'tmp append' [
    cyberlinks?             # cyberlinks table
    --dont_show_out_table (-d)
] {
    let $cyberlinks = ($in | default $cyberlinks)

    let $cyberlinks = (
        $cyberlinks
        | upsert date_time (
            date now
            | date format '%y%m%d-%H%M%S'
        )
    )

    (
        tmp view -q
        | append $cyberlinks
        | tmp replace
    )
}

# Replace cyberlinks in the temp table
export def 'tmp replace' [
    cyberlinks?             # cyberlinks table
    --dont_show_out_table (-d)
] {
    let $cyberlinks = ($in | default $cyberlinks)

    (
        $cyberlinks
        | save $"($env.cyfolder)/cyberlinks_temp.csv" --force
    )

    if (not $dont_show_out_table)  {
        tmp view -q
    }
}

# Empty the temp cyberlinks table
export def 'tmp clear' [] {
    backup_fn $"($env.cyfolder)/cyberlinks_temp.csv"

    'from,to,from_text,to_text' | save $"($env.cyfolder)/cyberlinks_temp.csv" --force
    # print "TMP-table is clear now."
}

# Add a text particle into the 'to' column of the temp cyberlinks table
export def 'tmp link to' [
    text: string # a text to upload to ipfs
    # --non-empty # fill non-empty only
] {
    let $in_links = $in
    let $links = ($in_links | default (tmp view -q))

    let $result = (
        $links
        | upsert to (pin text $text)
        | upsert to_text $text
    )

    if ($in_links == null) {
        $result | tmp replace
    } else {
        $result
    }
}

# Add a text particle into the 'from' column of the temp cyberlinks table
export def 'tmp link from' [
    text: string # a text to upload to ipfs
    # --non-empty # fill non-empty only
] {
    let $in_links = $in
    let $links = ($in_links | default (tmp view -q))

    let $result = (
        $links
        | upsert from (pin text $text)
        | upsert from_text $text
    )

    if ($in_links == null) {
        $result | tmp replace
    } else {
        $result
    }
}

# Pin values from a given column to an IPFS node and add a column with their CIDs
export def 'tmp pin col' [
    --column_with_text: string = 'text' # a column name to take values from to upload to IPFS. Default is 'text
    --column_to_write_cid: string = 'from' # a column name to write CIDs to. Default is 'from'
] {
    let $new_text_col_name = ( $column_to_write_cid + '_text' )

    tmp view -q
    | upsert $column_to_write_cid {
        |it| $it | get $column_with_text | pin text
    }
    | rename -c [$column_with_text $new_text_col_name]
    | tmp replace
}

# Check if any of the links in the tmp table exist
# > let $from = 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufA'
# > let $to = 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufB'
# > let $neuron = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
# > cy link-exist $from $to $neuron
# : false
def 'link-exist' [
    from: string
    to: string
    neuron: string
] {
    let $out = (do -i {
        ^($env.cy.exec) query rank is-exist $from $to $neuron --output json --node $env.cy.rpc-address
    } | complete )

    if $out.exit_code == 0 {
        $out.stdout | from json | get "exist"
    } else {
        false
    }
}

# Remove existing cyberlinks from the temp cyberlinks table
export def 'tmp remove existed' [] {
    let $links_with_status = (
        tmp view -q
        | upsert link_exist {
            |row| (link-exist  $row.from $row.to $env.cy.address)
        }
    )

    let $existed_links = (
        $links_with_status
        | filter {|x| $x.link_exist}
    )

    let $existed_links_count = ($existed_links | length)

    if $existed_links_count > 0 {

        $"($existed_links_count) cyberlink(s) was/were already created by ($env.cy.address)" | cprint
        print $existed_links
        "So they were removed from the temp table!" | cprint -c red -a 2

        $links_with_status | filter {|x| not $x.link_exist} | tmp replace
    } else {
        "There are no cyberlinks from the tmp table for the current adress exist in the blockchain" | cprint
    }
}

# Create a custom unsigned cyberlinks transaction
def 'tx json create from cybelinks' [] {
    let $cyberlinks = $in
    let $cyberlinks = (
        $cyberlinks
        | select from to
        | uniq
    )

    let $trans = (
        '{"body":{"messages":[
        {"@type":"/cyber.graph.v1beta1.MsgCyberlink",
        "neuron":"","links":[{"from":"","to":""}]}
        ],"memo":"cy","timeout_height":"0",
        "extension_options":[],"non_critical_extension_options":[]},
        "auth_info":{"signer_infos":[],"fee":
        {"amount":[],"gas_limit":"23456789","payer":"","granter":""}},
        "signatures":[]}' | from json
    )

    $trans
    | upsert body.messages.neuron $env.cy.address
    | upsert body.messages.links $cyberlinks
    | save $"($env.cyfolder)/temp/tx-unsigned.json" --force
}

def 'tx sign and broadcast' [] {
    (
        ^($env.cy.exec) tx sign $"($env.cyfolder)/temp/tx-unsigned.json" --from $env.cy.address
        --chain-id $env.cy.chain-id
        --node $env.cy.rpc-address
        --output-document $"($env.cyfolder)/temp/tx-signed.json"

        | complete
        | if ($in.exit_code != 0) {
            error make {msg: 'Error of signing the transaction!'}
        }
    )

    let $broadcast_complete = (
        ^($env.cy.exec) tx broadcast $"($env.cyfolder)/temp/tx-signed.json"
        --broadcast-mode block
        --output json
        --node $env.cy.rpc-address
        | complete
    )

    if ($broadcast_complete.exit_code != 0 ) {
        error make {
            msg: 'exit code is not 0'
        }
    } else {
        $broadcast_complete.stdout
    }
}

# Create a tx from the temp cyberlinks table, sign and broadcast it
export def 'tmp send tx' [] {
    let $in_cyberlinks = $in

    if not (is-connected) {
        error make {msg: 'there is no internet!'}
    }

    let $cyberlinks = ($in_cyberlinks | default (tmp view -q))

    let $cyberlinks_count = ($cyberlinks | length)

    $cyberlinks | tx json create from cybelinks

    let $_var = (
        tx sign and broadcast
        | from json
        | select raw_log code txhash
    )

    if $_var.code == 0 {
        open $"($env.cyfolder)/cyberlinks_archive.csv"
        | append (
            $cyberlinks
            | upsert neuron $env.cy.address
        )
        | save $"($env.cyfolder)/cyberlinks_archive.csv" --force

        if ($in_cyberlinks == null) {
            tmp clear
        }

        {'cy': $'($cyberlinks_count) cyberlinks should be successfully sent'}
        | merge $_var
        | select cy code txhash

    } else if $_var.code == 2 {
        {'cy': $'Use (ansi yellow)"cy tmp remove existed"(ansi reset)' }
        | merge $_var
    } else {
        $_var
    }
}

# Copy a table from the pipe into the clipboard (in tsv format)
export def 'tsv copy' [] {
    let $_table = $in
    print $_table

    $_table | to tsv | pbcopy
}

# Paste a table from the clipboard to stdin (so it can be piped further)
export def 'tsv paste' [] {
    pbpaste | from tsv
}

# Update cy to the latest version
export def 'update cy' [
    --branch: string@'nu-complete-git-branches' = 'main'
] {

    let $url = $"https://raw.githubusercontent.com/cyber-prophet/($branch)/dev/cy.nu"

    mkdir $env.cyfolder
    | http get $url
    | save $"($env.cyfolder)/cy.nu -f"

}

# Get a passport by providing a neuron's address or nick
export def 'passport get' [
    address_or_nick: string # Name of passport or neuron's address
] {
    let $json = (
        if (is-neuron $address_or_nick) {
            $'{"active_passport": {"address": "($address_or_nick)"}}'
        } else {
            $'{"passport_by_nickname": {"nickname": "($address_or_nick)"}}'
        }
    )

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'
    let $params = ['--node' 'https://rpc.bostrom.cybernode.ai:443' '--output' 'json']
    let $out = (
        do -i {
            ^cyber query wasm contract-state smart $pcontract $json $params
        } | complete
    )

    if $out.exit_code == 0 {
        $out.stdout  | from json | get data
    } else {
        print $"No passport for ($address_or_nick) is found"
        null
    }
}


# Set a passport's particle, data or avatar field for a given nickname
export def 'passport set' [
    particle: string
    nickname?
    --data
    --avatar
] {
    let $nickname = (
        if ($nickname | is-empty) {
            if ($env.cy.passport-nick | is-empty) {
                print "there is no nickname for passport set. To update the fields we need one."
                return
            } else {
                $env.cy.passport-nick
            }
        } else {
            $nickname
        }
    )

    let $particle = (
        if (is-cid $particle) {
            $particle
        } else {
            print $"($particle) doesn't look like cid"
            return
        }
    )

    let $json = (
        if $data {
            $'{"update_data":{"nickname":"($nickname)","data":"($particle)"}}'
        } else if $avatar {
            $'{"update_avatar":{"nickname":"($nickname)","new_avatar":"($particle)"}}'
        } else {
            $'{"update_particle":{"nickname":"($nickname)","particle":"($particle)"}}'
        }
    )

    let $pcontract = 'bostrom1xut80d09q0tgtch8p0z4k5f88d3uvt8cvtzm5h3tu3tsy4jk9xlsfzhxel'

    let $params = [
        '--from' $env.cy.address
        '--node' 'https://rpc.bostrom.cybernode.ai:443'
        '--output' 'json'
        '--yes'
        '--broadcast-mode' 'block'
        '--gas' '23456789'
    ]

    let $out = (
        do -i {
            ^cyber tx wasm execute $pcontract $json $params
        } | complete
    )

    let $results = if $out.exit_code == 0 {
        $out.stdout | from json | select raw_log code txhash
    } else {
        print $"The particle might not be set. Check with (ansi yellow)cy passport get ($nickname)(ansi reset)"
    }

    $results
}

export def-env 'graph load vars' [] {
    if (not ($"($env.cyfolder)/graph/cyberlinks.csv" | path exists)) {
        print "There is no cyberlinks.csv. Download it usin 'cy graph download snapshoot'"
        return
    }
    let $cyberlinks = (dfr open $"($env.cyfolder)/graph/cyberlinks.csv")
    let $particles = (if (not ($"($env.cyfolder)/particles.parquet" | path exists)) {
        (dfr open $"($env.cyfolder)/graph/particles.parquet")
    } else {
        print "there is no 'particles.parquet' file. Create one using the command 'cy graph update particles parquet'"
        null
    })
    let $neurons = (open $"($env.cyfolder)/graph/neurons_dict.json" | fill non-exist $in | dfr into-df)
    let-env cy = (
        $env.cy
        | merge {'cyberlinks': $cyberlinks}
        | merge {'particles': $particles}
        | merge {'neurons': $neurons}
    )
}

# Download a snapshot of cybergraph by graphkeeper
export def-env 'graph download snapshoot' [
    --disable_update_parquet (-d)
] {
    let $path = $"($env.cyfolder)/graph"
    let $cur_data_cid = (passport get graphkeeper | get extension.data -i)
    let $update_info = (open $"($path)/update.toml")
    let $last_data_cid = ($update_info | get -i last_cid)

    if ($last_data_cid == $cur_data_cid) {
        print "no updates found"
        return
    }

    print "Downloading cyberlinks.csv"
    ipfs get $"($cur_data_cid)/graph/cyberlinks.csv" -o $path
    print "Downloading neurons.json"
    ipfs get $"($cur_data_cid)/graph/neurons_dict.json" -o $path
    print "Downloading particles zips"
    ipfs get $"($cur_data_cid)/graph/particles/" -o $"($path)/particles_arch/"

    let $archives = (ls $"($path)/particles_arch/*.zip" | get name)
    let $last_archive = (
        $update_info
        | get -i last_archive
        | default ($archives | first)
    )

    (
        $archives
        | skip until {|x| $x == $last_archive}
        | each {|i| unzip -ojq $i -d $"($path)/particles/safe/"; print $"($i) is unzipped"}
    )

    (
        open $"($path)/update.toml"
        | upsert "last_cid" $cur_data_cid
        | upsert "last_archive" ($archives | last)
        | save $"($path)/update.toml" -f
    )

    print $"The graph data has been downloaded to the '($path)' directory"

    if (not $disable_update_parquet) {
        print 'Updating particles parquet'
        graph update particles parquet
    }
}

def 'cyberlinks_to_particles' [
    cyberlinks?
] {
    let $c = (
        $cyberlinks
        | default (
            dfr open $"($env.cyfolder)/graph/cyberlinks.csv"
        )
        | dfr into-lazy
    )

    (
        $c 
        | dfr rename particle_from particle 
        | dfr drop particle_to
        | dfr append --col (
            $c | dfr rename particle_to particle | dfr drop particle_from
        )
        | dfr into-lazy 
        | dfr sort-by height 
        | dfr unique --subset [particle] 
        | dfr collect
    )
}

export def-env 'graph update particles parquet' [] {

    let $t2_ls = (ls $"($env.cyfolder)/graph/particles/safe");

    let $t3_ls_content = (
        $t2_ls
        | get name
        | each {
            |i| open $i
            | str substring 0..150 -g
            | str trim
            | lines
            | get -i 0
            | default $"!!malformed ($i)"
        }
        | dfr into-df
        | dfr rename '0' content_s
    )

    let $t4_cids = (
        $t2_ls
        | get name
        | each {
            |i| $i
            | path basename
            | str substring 0..46
            | into string
        }
        | dfr into-df
        | dfr rename '0' cid
    )

    let $t5_files_with_content_df = (
        $t2_ls
        | dfr into-df
        | dfr with-column $t3_ls_content
        | dfr with-column $t4_cids
        | dfr drop name modified type
    )

    let $t6_particles_with_content = (
        cyberlinks_to_particles
        | dfr into-df
        | dfr join $t5_files_with_content_df particle cid --left
    )

    let $m2_mask_null = (
        $t6_particles_with_content
        | dfr get content_s
        | dfr is-null
    )

    let $t7_content_filled = (
        $t6_particles_with_content
        | dfr with-column (
            $t6_particles_with_content
            | dfr get content_s
            | dfr set 'timeout' --mask ($m2_mask_null | dfr into-df)
            | dfr rename string content_s
        )
    )

    backup_fn $"($env.cyfolder)/graph/particles.parquet"
    $t7_content_filled | dfr to-parquet $"($env.cyfolder)/graph/particles.parquet" | print $in
    graph load vars
    # $t6_particles_with_content | dfr to-parquet $"($env.cyfolder)/graph/particles.parquet"
}

# Export the entire graph into CSV file for import to Gephi
export def 'graph to-gephi' [
    --cyberlinks = $env.cy.cyberlinks
    --particles = $env.cy.particles
] {
    (
        $cyberlinks
        | dfr into-df
        | dfr rename [particle_from particle_to] [source target]
        | dfr to-csv $"($env.cyfolder)/gephi/!cyberlinks.csv"
    )

    (
        $particles
        | dfr into-lazy
        | dfr with-column (
            (dfr col particle) | dfr as cid
        ) | dfr rename [particle content_s] [id label]
        | dfr collect
        | dfr into-nu
        | reject index
        | move id label cid --before height
        | save $"($env.cyfolder)/gephi/!particles.csv" -f
    )
}

# Export filtered graph into a CSV file for import to Gephi.
export def 'graph to-gephi filter' [
    ...neurons: string@"nu-complete neurons nicks"
    # --cyberlinks?
] {
    let $filtered_nrns = (
        $neurons
        | dfr into-df
        | dfr join $env.cy.neurons '0' nick
        | dfr select neuron
        | dfr join $env.cy.cyberlinks neuron neuron
    )

    let $filtered_prtkls = (
        $filtered_nrns
        | dfr into-df
        | dfr get particle_from
        | dfr rename particle_from particle
        | dfr append -c (
            $filtered_nrns
            | dfr into-df
            | dfr get particle_to
            | dfr rename particle_to particle
            )
        | dfr unique
        | dfr join $env.cy.particles particle particle
    )
    graph to-gephi --cyberlinks $filtered_nrns --particles $filtered_prtkls
    # let $cyberlinks = ($cyberlinks | default $env.cy.cyberlinks )
}

def "nu-complete neurons nicks" [] {
    $env.cy.neurons.nick | dfr into-df | dfr into-nu | get nick
}

# Create a config JSON to set env variables, to use them as parameters in cyber cli
export def-env 'config new' [
    # config_name?: string@'nu-complete-config-names'
] {
    'This wizzard will walk you through the setup of CY.' | cprint -c green_underline -a 2
    'If you skip entering the value - the default will be used.' | cprint -c yellow_italic

    'Choose the name of executable (cyber or pussy). ' | cprint --before 1 --after 0
    'Default: cyber' | cprint -c yellow_italic

    let $_exec = ((input) | if-empty 'cyber')

    let $addr_table = (
        ^($_exec) keys list --output json
        | from json
        | flatten
        | select name address
    )

    if ($addr_table | length) > 0 {
        'Here are the keys that you have:' | cprint -b 1
        print $addr_table
    } else {
        let $error_text = (
            $'There are no addresses in ($_exec). To use CY you need to add one.' +
            $'You can find out how to add one by running the command "($_exec) keys add -h".' +
            $'After adding a key - come back and launch this wizzard again'
        )

        error make -u {msg: $error_text}
    help: $'try "($_exec) keys add -h"'
    }

    let $address_def = ($addr_table | get address.0)

    'Enter the address to send transactions from. ' | cprint --before 1 --after 0
    $'Default: ($address_def)' | cprint -c yellow_italic
    let $address = ((input) | if-empty $address_def)

    let $config_name = (
        $addr_table
        | select address name
        | transpose -r -d
        | get $address
        | $"($in)+($_exec)"
    )

    let $passport_nick = (
        passport get $address
        | get extension.nickname -i
    )

    if (not ($passport_nick | is-empty)) {
        print $"Passport nick (ansi yellow)($passport_nick)(ansi reset) will be used"
    }

    let $chain_id_def = (if ($_exec == 'cyber') {
            'bostrom'
        } else {
            'space-pussy'
        }
    )

    'Enter the chain-id for interacting with the blockchain. ' | cprint --before 1 --after 0
    $'Default: ($chain_id_def)' | cprint -c yellow_italic
    let $chain_id = ((input) | if-empty $chain_id_def)


    let $rpc_def = if ($_exec == 'cyber') {
        'https://rpc.bostrom.cybernode.ai:443'
    } else {
        'https://rpc.space-pussy.cybernode.ai:443'
    }

    'Enter the address of RPC api for interacting with the blockchain. ' | cprint --before 1 --after 0
    $'Default: ($rpc_def)' | cprint -c yellow_italic
    let $rpc_address = ((input) | if-empty $rpc_def)


    'Select the ipfs service to use (kubo, cybernode, both). ' | cprint --before 1 --after 0
    'Default: cybernode' | cprint -c yellow_italic
    let $ipfs_storage = ((input) | if-empty 'cybernode')


    let $temp_env = {
        'config-name': $config_name
        'exec': $_exec
        'address': $address
        'passport-nick': $passport_nick
        'chain-id': $chain_id
        'ipfs-storage': $ipfs_storage
        'rpc-address': $rpc_address
    }


    make_default_folders_fn

    # ipfs files mkdir -p '/cy/cache'

    $temp_env | config save $config_name

    if (
        not ($"($env.cyfolder)/cyberlinks_temp.csv" | path exists)
    ) {
        'from,to' | save $"($env.cyfolder)/cyberlinks_temp.csv"
    }

    if (
        not ($"($env.cyfolder)/cyberlinks_archive.csv" | path exists)
    ) {
        'from,to,address,timestamp,txhash' | save $"($env.cyfolder)/cyberlinks_archive.csv"
    }
}

# View a saved JSON config file
export def 'config view' [
    config_name?: string@'nu-complete-config-names'
] {
    if $config_name == null {
        print "current config is:"
        $env.cy
    } else {
        let $filename = $"($env.cyfolder)/config/($config_name).toml"
        open $filename
    }
}

# Save the piped-in JSON into config file
export def-env 'config save' [
    config_name?: string@'nu-complete-config-names'
    --inactive # Don't activate current config
] {
    let $in_config = $in

    let $dt1 = now_fn

    let $config_name = (
        if $config_name == null {
            "Enter the name of the config file to save. " | cprint --before 1 --after 0
            $"Default: ($dt1)" | cprint -c yellow_italic
            input
        } else {
            $config_name
        }
    )
    let $config_name = ($config_name | if-empty $dt1)

    mut file_name = $"($env.cyfolder)/config/($config_name).toml"

    let $in_config = ($in_config | upsert config-name $config_name)

    if ($file_name | path exists) {
        let $prompt1 = (input $"($file_name) exists. Do you want to overwrite it? \(y/n\) ")

        if $prompt1 == "y" {
            backup_fn $file_name
            $in_config | save $file_name -f
        } else {
            $file_name = $"($env.cyfolder)/config/($dt1).toml"
            $in_config | save $file_name
        }
    } else {
        $in_config | save $file_name -f
    }

    print $"($file_name) is saved"

    if (not $inactive) {
        $in_config | config activate
    }
}

# Activate the config JSON
export def-env 'config activate' [
    config_name?: string@'nu-complete-config-names'
] {
    let $inconfig = $in
    let $config1 = (
        open ('~/.config/cy/cy_config.toml' | path expand)
        | merge (
            $inconfig
            | default (config view $config_name)
        )
    )

    let-env cy = $config1

    "Config is loaded" | cprint -c green_underline
    # $config1 | save $"($env.cyfolder)/config/default.toml" -f
    (
        open ('~/.config/cy/cy_config.toml' | path expand)
        | upsert 'config-name' ($config1 | get 'config-name')
        | save ('~/.config/cy/cy_config.toml' | path expand) -f
    )

    $config1
}

def 'search-sync' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let $cid = if (is-cid $query) {
        $query
    } else {
        (pin text $query --only_hash)
    }

    print $'searching ($env.cy.exec) for ($cid)'

    (
        ^($env.cy.exec) query rank search $cid $page 10 --output json
        | from json
        | get result
        | upsert particle {
            |i| let $particle = (
                ipfs cat $i.particle -l 400
            );
            $particle
            | file -
            | if (
                $in | str contains "/dev/stdin: ASCII text"
            ) {
                $"($particle)\n(ansi grey)($i.particle)(ansi reset)"
            } else {
                $"Non-text particle. Is not supported yet.\n(ansi grey)($i.particle)(ansi reset)"
            }
        }
        | select particle rank
    )
}

def 'search-with-backlinks' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let $cid = if (is-cid $query) {
        print $"searching (cid read or download $query)"
        $query
    } else {
        (pin text $query --only_hash | inspect)
    }

    print $'searching ($env.cy.exec) for ($cid)'

    let $serp = (
        ^($env.cy.exec) query rank search $cid $page $results_per_page --output json
        | from json
        | get result
        | upsert particle {
            |i| cid read or download $i.particle
        }
        | select particle rank
        | upsert source "search"
    )

    let $back = (
        ^($env.cy.exec) query rank backlinks $cid $page $results_per_page --output json
        | from json
        | get result
        | upsert particle {
            |i| cid read or download $i.particle
        }
        | select particle rank
        | upsert source "backlinks"
    )

    let $result = ($serp | append $back)

    $result
}

def 'search-auto-refresh' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
] {
    let $cid = (pin text $query --only_hash)

    print $'searching ($env.cy.exec) for ($cid)'

    let $out = (
        do -i {
            ^($env.cy.exec) query rank search $cid $page $results_per_page --output json
        } | complete
    )

    let $results = if $out.exit_code == 0 {
        $out.stdout | from json
    } else {
        null
    }

    if $results == null {
        print $"there is no search results for ($cid)"
        return
    }

    $results | save $"($env.cyfolder)/cache/search/($cid)-(date now|into int).json"

    clear; print $"Searching ($env.cy.exec) for ($cid)";

    serp1 $results

    watch $"($env.cyfolder)/cache/queue" {|| clear; print $"Searching ($env.cy.exec) for ($cid)"; serp1 $results}
}

def "nu-complete search functions" [] {
    ['search-auto-refresh' 'search-with-backlinks', 'search-sync']
}

# Use the built-in node search function in cyber or pussy
export def 'search' [
    query
    --page (-p) = 0
    --results_per_page (-r) = 10
    --search_type: string@"nu-complete search functions" = 'search-with-backlinks'
] {
    if $search_type == 'search-with-backlinks' {
        search-with-backlinks $query --page $page --results_per_page $results_per_page
    } else if $search_type == 'search-auto-refresh' {
        search-auto-refresh $query --page $page --results_per_page $results_per_page
    } else if $search_type == 'search-sync' {
        search-sync $query --page $page --results_per_page $results_per_page
    }
}

def serp1 [
    results
    --pretty: bool@"nu-complete bool" = false
] {

    let $serp = (
        $results
        | get result
        | upsert particle {
            |i| cid read or download $i.particle
        }
        | select particle rank
    )

    $serp
}

# Obtain cid info
export def 'cid get type gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --to_csv
] {
    let $headers = (
        curl -s -I -m 120 $"($gate_url)($cid)"
        | lines
        | skip 1
        | append "dummy: dummy"   # otherwise it returns list in the end
        | parse "{header}: {value}"
        | transpose -d -r -i
    )
    let $type = ($headers | get -i 'Content-Type')
    let $size = ($headers | get -i 'Content-Length')

    log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '3.downloaded headers'

    if (
        (($type == null) or ($size == null))
        or (($type == 'text/html') and (($size == "157") or ($size == 157))
    )) {
        return null
    }

    {type: $type size: $size}
}

export def log_row_csv [
    --cid: string = ''
    --source: string = ''
    --type: string = ''
    --size: string = ''
    --status: string = ''
    --file: string = $"($env.cyfolder)/cache/MIME_types.csv"
] {
    $"($cid),($source),\"($type)\",($size),($status),(history session)\n" | save -a $file
}

# Add a cid into queue to download asynchronously
export def 'cid download async' [
    cid: string
    --force (-f)
    --source: string # kubo or gateway
    --info_only # Don't download the file by write a card with filetype and size
    --folder: string = $"($env.cy.ipfs-files-folder)"
] {
    let $content = (do -i {open $"($env.cy.ipfs-files-folder)/($cid).md"})
    let $source = ($source | default $env.cy.ipfs-download-from)

    if ($content == null) or ($content == 'timeout') or $force {
        pu-add $"cy cid download ($cid) --source ($source) --info_only ($info_only) --folder '($folder)'"
        print "downloading"
    }
}

# Download cid immediately and mark it in the queue
export def 'cid download' [
    cid: string
    --source: string # kubo or gateway
    --info_only = false # Don't download the file by write a card with filetype and size
    --folder: string = $"($env.cy.ipfs-files-folder)"
] {
    let $source = ($source | default $env.cy.ipfs-download-from)
    let $status = (
        if ($source == 'gateway') {
            cid download gateway $cid --info_only $info_only --folder $folder
        } else {
            cid download kubo $cid --info_only $info_only --folder $folder
        }
    )
}

# Download a cid from kubo (go-ipfs cli) immediately
def 'cid download kubo' [
    cid: string
    --timeout = "300s"
    --folder: string
    --info_only = false # Don't download the file by write a card with filetype and size
] {
    print $"cid to download ($cid)"
    let $type = (
        do -i {
            ipfs cat --timeout $timeout -l 400 $cid
            | file - -I
            | $in + ''
            | str replace '\n' ''
            | str replace '/dev/stdin: ' ''
        }
    )

    if ($type =~ "^empty") {
        return "not found"
    } else if (
        ($type =~ "(text/plain)|(ASCII text)|(Unicode text, UTF-8)|(very short file)") and (not $info_only)
     ) {
        try {
            ipfs get --progress=false --timeout $timeout -o $"($folder)/($cid).md" $cid
            return "text"
        } catch {
            return "not found"
        }
    } else {
        (
            {'MIME type': ($type | split row ";" | get -i 0)}
            | merge (
                do -i {
                    ipfs dag stat $cid --enc json --timeout $timeout | from json
                }
                | default {'Size': null}
            )
            | sort -r
            | to toml
            | save -f $"($folder)/($cid).md"
        )
        return "non_text"
    }

}

# Download a cid from gateway immediately
export def 'cid download gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --folder: string = $"($env.cy.ipfs-files-folder)"
    --info_only: bool = false # Don't download the file by write a card with filetype and size
] {
    let $meta = (cid get type gateway $cid)
    let $type = ($meta | get -i type)
    let $size = ($meta | get -i size)

    if (
        (($type | default "") == 'text/plain; charset=utf-8') and (not $info_only)
    ) {
        http get $"($gate_url)($cid)" -m 120 | save -f $"($folder)/($cid).md"
        log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '4.downloaded file'
    } else if ($type != null) {
        {'MIME type': $type, 'Size': $size} | sort -r | to toml | save -f $"($folder)/($cid).md"
        log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '4.downloaded info'
    } else {
        log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '5.failed'
    }
}

export def 'cid queue add' [
    cid: string
] {
    log_row_csv --cid $cid --status '1.queued'
}

# Read a CID from the cache, and if the CID is absent - add it into the queue
export def 'cid read or download' [
    cid: string
    --attempts = 0
] {
    let $content = (do -i {open $"($env.cy.ipfs-files-folder)/($cid).md"})

    let $content = (
        if $content == null {
            pu-add $"cy cid download ($cid)"
            "downloading"
        } else {
            $content
        }
    )

    (
        $content
        | str substring '0,400'
        | str replace "\n" "↩" --all
        | $"($in)\n(ansi grey)($cid)(ansi reset)"
    )
}

# Watch the queue folder, and if there are updates, request files to download
export def 'watch search folder' [] {
    watch $"($env.cyfolder)/cache/search" {|| queue check }
}

# Check the queue for the new CIDs, and if there are any, safely download the text ones
export def 'queue check' [
    attempts = 0
] {
    let $files = (ls -s $"($env.cyfolder)/cache/queue/")

    if (do -i {pueue status} | complete | $in.exit_code != 0) {
        return "Tasks queue manager it turned off. Launch it with 'brew services start pueue' or 'pueued -d' command"
    }

    if ( ($files | length) == 0 ) {
        return 'there are no files in queue'
    }

    print $"Overall count of files in queue is ($files | length)."

    let $filtered_files = (
        $files
        | sort-by modified -r
        | where size <= (1 + $attempts | into filesize)
    )

    if ($filtered_files == []) {
        return $'There are no files, that was attempted to download for less than ($attempts) times.'
    }

    print $"There are ($filtered_files | length) files that was attempted to be downloaded ($attempts) times already."
    print $"The latest file was added into the queue ($filtered_files | get modified.0 -i)"

    (
        $filtered_files
        | get name -i
        | each {
            |i| pu-add $"cy cid download ($i)"
        }
    )
}

# Clear the cache folder
export def 'cache clear' [] {
    backup_fn $"($env.cyfolder)/cache"
    make_default_folders_fn
}

export def 'get-balance' [
    address: string
] {
    if not (is-neuron $address) {
        print $"($address) doesn't look like address"
        return
    }

    cyber query bank balances $address --output json
    | from json
    | get balances
    | upsert amount {
        |b| $b.amount
        | into int
    }
    | transpose -i -r
    | into record
}

# Check the balances for the keys added to the active CLI
export def 'balances' [
    ...name: string@'nu-complete keys values'
] {

    let $keys0 = (
        ^($env.cy.exec) keys list --output json
        | from json
        | select name address
    )

    let $keys1 = (
        if ($name | is-empty) {
            $keys0
        } else {
            $keys0 | where name in $name
        }
    )

    let $balances = (
        $keys1
        | par-each {
            |i| get-balance $i.address
            | merge $i
        }
    )

    let $dummy1 = (
        $balances | columns | prepend "name" | uniq
        | reverse | prepend ["address"] | uniq
        | reverse | reduce -f {} {|i acc| $acc | merge {$i : 0}}
    )

    let $out = ($balances | each {|i| $dummy1 | merge $i} | sort-by name)

    if ($name | is-empty) or (($name | length) > 1) {
        $out
    } else {
        $out | into record
    }
}

# Add the cybercongress node to bootstrap nodes
export def 'ipfs bootstrap add congress' [] {
    ipfs bootstrap add '/ip4/135.181.19.86/tcp/4001/p2p/12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY'
    print "check if bootstrap node works by executing commands:"

    print 'ipfs routing findpeer 12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY'
    ipfs routing findpeer 12D3KooWNMcnoQynAY9hyi4JxzSu64BsRGcJ9z7vKghqk8sTrpqY

    print 'ipfs routing findpeer QmUgmRxoLtGERot7Y6G7UyF6fwvnusQZfGR15PuE6pY3aB'
    ipfs routing findpeer QmUgmRxoLtGERot7Y6G7UyF6fwvnusQZfGR15PuE6pY3aB
}

# Check IBC denoms
export def 'ibc denoms' [] {
    let $bank_total = (
        cyber query bank total --output json
        | from json # here we obtain only the first page of report
    )

    let $denom_trace1 = (
        $bank_total
        | get supply
        | where denom =~ "^ibc"
        | upsert ibc_hash {|i| $i.denom | str replace "ibc/" ""}
        | upsert temp_out {
            |i| cyber query ibc-transfer denom-trace $i.ibc_hash --output json
            | from json
            | get denom_trace
        }
    )

    $denom_trace1.temp_out | merge $denom_trace1 | reject ibc_hash temp_out | sort-by path --natural
}

# Dump the peers connected to the given node to the comma-separated `persistent_peers` list
export def 'validator generate persistent peers string' [
    node_address: string = $'($env.cy.rpc-address)'
] {
    if $node_address == $env.cy.rpc-address {
        print $"Nodes list for ($env.cy.rpc-address)\n"
    }

    let $peers = (http get $'($node_address)/net_info' | get result.peers)

    print $"($peers | length) peers found\n"

    $peers
    | each {|i| $i 
    | get node_info.id remote_ip node_info.listen_addr} 
    | each {
        |i| $'($i.0)@($i.1):($i.2 | split row ":" | last)'
    } 
    | str join ',' 
    | $'persistent_peers = "($in)"'
}

# An ordered list of cy commands
export def 'help' [
    --to_md (-m) # export table as markdown
] {
    let $text = (
        open $"($env.cyfolder)/cy.nu" --raw
        | parse -r "(\n(# )(?<desc>.*?)(?:\n#[^\n]*)*\nexport (def|def.env) '(?<command>.*)')"
        | select command desc
        | upsert command {|row index| ('cy ' + $row.command)}
    )

    if $to_md {
        $text | to md
    } else {
        $text
    }
}

def 'banner' [] {
    print $"
     ____ _   _
    / ___\) | | |
   \( \(___| |_| |
    \\____)\\__  |   (ansi yellow)cy(ansi reset) nushell module is loaded
         \(____/    have fun"
}

def 'banner2' [] {
    print $"(ansi yellow)cy(ansi reset) is loaded"
}


def is-cid [particle: string] {
    ($particle =~ '^Qm\w{44}$')
}

def is-neuron [particle: string] {
    ($particle =~ '^bostrom1\w{38}$') or ($particle =~ '^bostrom1\w{58}$')
}

def is-connected []  {
    (do -i {http get https://duckduckgo.com/} | describe) == 'raw input'
}

def make_default_folders_fn [] {
    mkdir $"($env.cyfolder)/temp/"
    mkdir $"($env.cyfolder)/backups/"
    mkdir $"($env.cyfolder)/config/"
    mkdir $"($env.cyfolder)/graph/particles/safe/"
    mkdir $"($env.cyfolder)/gephi/"
    mkdir $"($env.cyfolder)/scripts/"
    mkdir $"($env.cyfolder)/cache/search/"
    mkdir $"($env.cy.ipfs-files-folder)/"
    mkdir $"($env.cyfolder)/cache/queue/"
    mkdir $"($env.cyfolder)/cache/cli_out/"

    touch $"($env.cyfolder)/graph/update.toml"
}

# Print string colourfully
def 'cprint' [
    ...args
    --color (-c): string@'nu-complete colors' = 'default'
    --frame (-f): string
    --before (-b): int = 0
    --after (-a): int = 1
] {
    let $text = if ($args == []) {
        $in
    } else {
        $args | str join ' '
    }

    let $text = (
        if $frame != null {
            let $width = (term size | get columns | $in - 2 | [$in 1] | math max) # term size gives 0 in tests
            (
                (" " | fill -a r -w $width -c $frame) + "\n" +
                ( $text ) + "\n" +
                (" " | fill -a r -w $width -c $frame)
            )
        } else {
            $text
        }
    )

    seq 1 $before | each {|i| print ""}
    $text | print $"(ansi $color)($in)(ansi reset)" -n
    seq 1 $after | each {|i| print ""}
}

def 'if-empty' [
    alternative: any
] {
    let value = $in
     (
         if ($value | is-empty) {
             $alternative
         } else {
             $value
         }
     )
 }

def 'now_fn' [
    --pretty (-P)
] {
    if $pretty {
        date now | date format '%Y-%m-%d-%H:%M:%S'
    } else {
        date now | date format '%Y%m%d-%H%M%S'
    }
}

def 'backup_fn' [
    filename
] {
    let $basename1 = ($filename | path basename)
    let $path2 = $"($env.cyfolder)/backups/(now_fn)($basename1)"

    if (
        $filename
        | path exists
    ) {
        ^mv $filename $path2
        # print $"Previous version of ($filename) is backed up to ($path2)"
    } else {
        print $"($filename) does not exist"
    }
}

def 'pu-add' [
    command: string
] {
    pueue add -p $"nu -c \"($command)\" --config \"($nu.config-path)\" --env-config \"($nu.env-path)\""
}

def "nu-complete colors" [] {
    ansi --list | get name | each while {|it| if $it != 'reset' {$it} }
}

def "nu-complete-config-names" [] {
    ls $"($env.cyfolder)/config/" -s
    | sort-by modified -r
    | get name
    | parse '{short}.{ext}'
    | where ext == "toml"
    | get short
}

def "nu-complete-git-branches" [] {
    ['main', 'dev']
}

# cyber keys in a form of table
def "nu-complete keys table" [] {
    cyber keys list --output json | from json | select name address
}

# Helper function to use addresses for completions in --from parameter
def "nu-complete keys values" [] {
    (nu-complete keys table).name | zip (nu-complete keys table).address | flatten
}

def "nu-complete bool" [] {
    [true, false]
}

def do-async [commands: string] {
    bash -c $"nu -c '($commands)' &"
}

def do-bash [commands: string] {
    bash -c $"'($commands)' &"
}

def 'fill non-exist' [
    tbl
    --value_to_replace = null
] {
    let $cols = ($tbl | each {|i| $i | columns} | flatten | uniq | reduce --fold {} {|i acc| $acc | merge {$i: $value_to_replace}})

    $tbl | each {|i| $cols | merge $i}
}

# A wrapper, to cache CLI requests
export def-env 'ber' [
    ...rest
    --seconds: int = 86400
    --exec: string
    --abci: string
    --absolutetimeouts
    --account: string
    --accountnumber (-a): string
    --address: string
    --admin: string
    --algo: string
    --allowedmessages: string
    --allowedvalidators: string
    --amino
    --amount: string
    --ascii
    --b64
    --bech: string
    --broadcastmode (-b): string
    --chainid: string
    --cointype: string
    --commission
    --commissionmaxchangerate: string
    --commissionmaxrate: string
    --commissionrate: string
    --computegpu
    --consensuscreate_empty_blocks
    --consensuscreate_empty_blocks_interval: string
    --consensusdouble_sign_check_height: string
    --counttotal
    --cpuprofile: string
    --db_backend: string
    --db_dir: string
    --delayed
    --denom: string
    --denyvalidators: string
    --deposit: string
    --depositor: string
    --description: string
    --details: string
    --device (-d)
    --dryrun
    --events: string
    --expiration: string
    --fast_sync
    --feeaccount: string
    --fees: string
    --force (-f)
    --forzeroheight
    --from: string
    --gas: string
    --gasadjustment: string
    --gasprices: string
    --generateonly
    --genesis_hash: string
    --genesistime: string
    --gentxdir: string
    --grpcaddress: string
    --grpcenable
    --grpconly
    --grpcwebaddress: string
    --grpcwebenable
    --haltheight: string
    --halttime: string
    --hdpath: string
    --height: string
    --help (-h)
    --hex
    --hex (-x)
    --home: string
    --iavldisablefastnode
    --identity: string
    --index: string
    --instantiateeverybody: string
    --instantiatenobody: string
    --instantiateonlyaddress: string
    --interactive (-i)
    --interblockcache
    --invcheckperiod: string
    --ip: string
    --jailallowedaddrs: string
    --keepaddrbook
    --keyringbackend: string
    --keyringdir: string
    --label: string
    --latestheight
    --ledger
    --limit: string
    --listnames (-n)
    --log_format: string
    --log_level: string
    --long
    --maxmsgs: string
    --minimumgasprices: string
    --minretainblocks: string
    --minselfdelegation: string
    --moniker: string
    --msgtype: string
    --multisig: string
    --multisigthreshold: string
    --newmoniker: string
    --noadmin
    --noautoincrement
    --nobackup
    --node (-n): string
    --node: string
    --nodedaemonhome: string
    --nodedirprefix: string
    --nodeid: string
    --nosort
    --note: string
    --offline
    --offset: string
    --output (-o): string
    --output: string
    --outputdir (-o): string
    --outputdocument: string
    --overwrite
    --overwrite (-o)
    --p2pexternaladdress: string
    --p2pladdr: string
    --p2ppersistent_peers: string
    --p2ppex
    --p2pprivate_peer_ids: string
    --p2pseed_mode
    --p2pseeds: string
    --p2punconditional_peer_ids: string
    --p2pupnp
    --packettimeoutheight: string
    --packettimeouttimestamp: string
    --page: string
    --pagekey: string
    --period: string
    --periodlimit: string
    --poolcoindenom: string
    --priv_validator_laddr: string
    --proposal: string
    --prove
    --proxy_app: string
    --pruning: string
    --pruninginterval: string
    --pruningkeepevery: string
    --pruningkeeprecent: string
    --pubkey: string
    --recover
    --reserveacc: string
    --reverse
    --rpcgrpc_laddr: string
    --rpcladdr: string
    --rpcpprof_laddr: string
    --rpcunsafe
    --runas: string
    --searchapi
    --securitycontact: string
    --sequence (-s): string
    --sequences: string
    --signatureonly
    --signmode: string
    --spendlimit: string
    --startingipaddress: string
    --statesyncsnapshotinterval: string
    --statesyncsnapshotkeeprecent: string
    --status: string
    --timeoutheight: string
    --title: string
    --trace
    --tracestore: string
    --transport: string
    --type: string
    --unarmoredhex
    --unsafe
    --unsafeentropy
    --unsafeskipupgrades: string
    --upgradeheight: string
    --upgradeinfo: string
    --v: string
    --vestingamount: string
    --vestingendtime: string
    --vestingstarttime: string
    --voter: string
    --wasmmemory_cache_size: string
    --wasmquery_gas_limit: string
    --wasmsimulation_gas_limit: string
    --website: string
    --withtendermint
    --xcrisisskipassertinvariants
    --yes (-y)
] {
    let $flags_nu = [
        $absolutetimeouts, $amino, $ascii, $b64, $commission, $computegpu,
        $consensuscreate_empty_blocks, $counttotal, $delayed, $device,
        $dryrun, $fast_sync, $force, $forzeroheight, $generateonly,
        $grpcenable, $grpconly, $grpcwebenable, $help, $hex, $iavldisablefastnode,
        $interactive, $interblockcache, $keepaddrbook, $latestheight, $ledger, $listnames,
        $long, $noadmin, $noautoincrement, $nobackup, $nosort, $offline, $overwrite,
        $p2ppex, $p2pseed_mode, $p2pupnp, $prove, $recover, $reverse, $rpcunsafe,
        $searchapi, $signatureonly, $trace, $unarmoredhex, $unsafe, $unsafeentropy,
        $withtendermint, $xcrisisskipassertinvariants, $yes
    ]
    let $flags_cli = [
        "--absolute-timeouts", "--amino", "--ascii", "--b64", "--commission", "--compute-gpu",
        "--consensus.create_empty_blocks", "--count-total", "--delayed", "--device",
        "--dry-run", "--fast_sync", "--for-zero-height", "--force", "--generate-only",
        "--grpc-only", "--grpc-web.enable", "--grpc.enable", "--help", "--hex", "--iavl-disable-fastnode",
        "--inter-block-cache", "--interactive", "--keep-addr-book", "--latest-height", "--ledger", "--list-names",
        "--long", "--no-admin", "--no-auto-increment", "--no-backup", "--nosort", "--offline", "--overwrite",
        "--p2p.pex", "--p2p.seed_mode", "--p2p.upnp", "--prove", "--recover", "--reverse", "--rpc.unsafe",
        "--search-api", "--signature-only", "--trace", "--unarmored-hex", "--unsafe", "--unsafe-entropy",
        "--with-tendermint", "--x-crisis-skip-assert-invariants", "--yes"
    ]
    let $options_nu = [
        $abci, $account, $accountnumber, $address, $admin, $algo, $allowedmessages,
        $allowedvalidators, $amount, $bech, $broadcastmode, $chainid, $cointype,
        $commissionmaxchangerate, $commissionmaxrate, $commissionrate,
        $consensuscreate_empty_blocks_interval, $consensusdouble_sign_check_height,
        $cpuprofile, $db_backend, $db_dir, $denom, $denyvalidators, $deposit, $depositor,
        $description, $details, $events, $expiration, $feeaccount, $fees, $from, $gas,
        $gasadjustment, $gasprices, $genesis_hash, $genesistime, $gentxdir, $grpcaddress,
        $grpcwebaddress, $haltheight, $halttime, $hdpath, $height, $home, $identity, $index,
        $instantiateeverybody, $instantiatenobody, $instantiateonlyaddress, $invcheckperiod,
        $ip, $jailallowedaddrs, $keyringbackend, $keyringdir, $label, $limit, $log_format,
        $log_level, $maxmsgs, $minimumgasprices, $minretainblocks, $minselfdelegation,
        $moniker, $msgtype, $multisig, $multisigthreshold, $newmoniker, $node, $nodedaemonhome,
        $nodedirprefix, $nodeid, $note, $offset, $output, $outputdir, $outputdocument,
        $p2pexternaladdress, $p2pladdr, $p2ppersistent_peers, $p2pprivate_peer_ids, $p2pseeds,
        $p2punconditional_peer_ids, $packettimeoutheight, $packettimeouttimestamp, $page,
        $pagekey, $period, $periodlimit, $poolcoindenom, $priv_validator_laddr, $proposal,
        $proxy_app, $pruning, $pruninginterval, $pruningkeepevery,
        $pruningkeeprecent, $pubkey, $reserveacc, $rpcgrpc_laddr, $rpcladdr, $rpcpprof_laddr,
        $runas, $securitycontact, $sequence, $sequences, $signmode, $spendlimit, $startingipaddress,
        $statesyncsnapshotinterval, $statesyncsnapshotkeeprecent, $status, $timeoutheight, $title,
        $tracestore, $transport, $type, $unsafeskipupgrades, $upgradeheight, $upgradeinfo, $v,
        $vestingamount, $vestingendtime, $vestingstarttime, $voter, $wasmmemory_cache_size,
        $wasmquery_gas_limit, $wasmsimulation_gas_limit, $website
    ]
    let $options_cli = [
        "--abci", "--account", "--account-number", "--address", "--admin", "--algo", "--allowed-messages",
        "--allowed-validators", "--amount", "--bech", "--broadcast-mode", "--chain-id", "--coin-type",
        "--commission-max-change-rate", "--commission-max-rate", "--commission-rate",
        "--consensus.create_empty_blocks_interval", "--consensus.double_sign_check_height",
        "--cpu-profile", "--db_backend", "--db_dir", "--denom", "--deny-validators", "--deposit", "--depositor",
        "--description", "--details", "--events", "--expiration", "--fee-account", "--fees", "--from", "--gas",
        "--gas-adjustment", "--gas-prices", "--genesis-time", "--genesis_hash", "--gentx-dir",
        "--grpc-web.address", "--grpc.address", "--halt-height", "--halt-time", "--hd-path", "--height", "--home", "--identity", "--index",
        "--instantiate-everybody", "--instantiate-nobody", "--instantiate-only-address", "--inv-check-period",
        "--ip", "--jail-allowed-addrs", "--keyring-backend", "--keyring-dir", "--label", "--limit", "--log_format",
        "--log_level", "--max-msgs", "--min-retain-blocks", "--min-self-delegation", "--minimum-gas-prices",
        "--moniker", "--msg-type", "--multisig", "--multisig-threshold", "--new-moniker", "--node", "--node-daemon-home",
        "--node-dir-prefix", "--node-id", "--note", "--offset", "--output", "--output-dir", "--output-document",
        "--p2p.external-address", "--p2p.laddr", "--p2p.persistent_peers", "--p2p.private_peer_ids", "--p2p.seeds",
        "--p2p.unconditional_peer_ids", "--packet-timeout-height", "--packet-timeout-timestamp", "--page",
        "--page-key", "--period", "--period-limit", "--pool-coin-denom", "--priv_validator_laddr", "--proposal",
        "--proxy_app", "--pruning", "--pruning-interval", "--pruning-keep-every",
        "--pruning-keep-recent", "--pubkey", "--reserve-acc", "--rpc.grpc_laddr", "--rpc.laddr", "--rpc.pprof_laddr",
        "--run-as", "--security-contact", "--sequence", "--sequences", "--sign-mode", "--spend-limit", "--starting-ip-address",
        "--state-sync.snapshot-interval", "--state-sync.snapshot-keep-recent", "--status", "--timeout-height", "--title",
        "--trace-store", "--transport", "--type", "--unsafe-skip-upgrades", "--upgrade-height", "--upgrade-info", "--v",
        "--vesting-amount", "--vesting-end-time", "--vesting-start-time", "--voter", "--wasm.memory_cache_size",
        "--wasm.query_gas_limit", "--wasm.simulation_gas_limit", "--website"
    ]

    let $list_flags_out = (
        $flags_nu
        | enumerate
        | reduce -f [] {
            |i acc| if $i.item {
                $acc
                | append ($flags_cli | get $i.index)
            } else {
                $acc
            }
        }
    )

    let $list_options_out = (
        $options_nu
        | enumerate
        | reduce -f [] {
            |i acc| if not ($i.item | is-empty) {
                $acc
                | append ($options_cli | get $i.index)
                | append $i.item
            } else {
                $acc
            }
        }
    )
    # print $list_flags_out

    let $exec = ($exec | default $env.cy.exec)

    let $important_options = (
        $list_options_out
        | enumerate
        | reduce -f "" {
            |i acc| if ($i.item in ['--page', '--height', '--events']) {
                [$acc $i.item ($list_options_out | get ($i.index + 1))] | str join ""
            } else {
                $acc
            }
        } | "+" + $in
    )

    let $cfolder = $"($env.cyfolder)/cache/cli_out/"
    let $command = $"($exec)_($rest | str join '_')($important_options | str replace "/" "")"
    let $ts1 = (date now | into int)

    # print $important_options
    let $filename = $"($cfolder)($command)-($ts1).json"

    let $cache_ls = (ls $cfolder)

    # print "cached_files"
    let $cached_file = (
        if $cache_ls != null {
            # print "$cache_ls != null"

            let $a1 = (
                $cache_ls
                | where name =~ $"($command)"
                | inspect
            )

            if ($a1 | length) == 0 {
                # print "here is null"
                null
            } else {
                $a1
                | sort-by modified --reverse
                | where modified > (date now | into int | $in - $seconds | into datetime)
                | get -i name.0
            }
        } else {
            # print "null"
            null
        }
    )

    let $content = (
        if ($cached_file != null) {
            print "cached used"
            open $cached_file
        } else  {
            print $"request command from cli, saving to ($filename)"
            print $"($exec) ($rest) --output json ($list_flags_out)"
            # let $out = (^($exec) $rest --output json $list_options_out $list_flags_out | from json)
            pu-add $"($exec) ($rest | str join ' ') --output json ($list_options_out | str join ' ') ($list_flags_out | str join ' ') | save -r ($filename)"
            # let $out1 = do -i {^($exec) $rest --output json $list_flags_out | from json}
            # let $out = (^($exec) $rest --output json $list_options_out $list_flags_out | from json)
            # if $out != null {$out | save $filename}
            # $out

        }
    )

    $content
}
