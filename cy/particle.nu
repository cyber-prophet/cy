use cy-internals.nu [cy-path]
use queue.nu [
    queue-task-add
    queue-db-cid-add
    queue-db-cid-in-progress
    queue-db-cid-request-completed
    queue-db-cid-request-failed
]

# Obtain cid info
#
# > cy particle-get-type-gateway QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV | to yaml
# type: text/plain; charset=utf-8
# size: '5'
export def 'particle-get-type-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
] {
    let $headers = ^curl -s -I -m 120 $'($gate_url)($cid)'
        | lines
        | skip 1
        | append 'dummy: dummy' # otherwise it returns list in the end
        | parse '{header}: {value}'
        | transpose -d -r -i

    let $type = $headers | get -i 'Content-Type'
    let $size = $headers | get -i 'Content-Length'

    if (
        $type == null
        or $size == null
        or ($type == 'text/html') and ($size == '157') # missing pages
    ) {
        return null
    }

    {type: $type size: $size}
}

export def 'particle-read' [
    cid
] {
    cy-path graph particles.db
    | open
    | query db $"SELECT content FROM particles WHERE cid = ?" -p [$cid]
    | get -i content.0
}

export def 'particle-store-db' [
    cid: string
    content: string
] {
    cy-path graph particles.db
    | open
    | query db "insert into particles VALUES (?, ?)" -p [$cid $content]
}

export def 'particle-store-file' [
    cid: string
    content: string
] {
    $content | save (particle-path $cid)
}

export def 'particle-store' [
    cid: string
    content: string
] {
    particle-store-file $cid $content
    particle-store-db $cid $content
}

# Read a CID from the cache, and if the CID is absent - add it into the queue
export def 'particle-read-or-download' [
    cid: string
    --full # output full text of a particle
] {
    let $content = particle-read $cid

    if $content == null {
        queue-db-cid-add $cid
        return 'added into queue'
    }

    $content
    | if $full {} else {
        str substring 0..400
        | str replace (char nl) '↩' --all
        | $'($in)(char nl)(ansi grey)($cid)(ansi reset)'
    }
}

# Download cid immediately and mark it in the queue
export def 'particle-download' [
    cid: string
    --source: string # kubo or gateway
    --info_only # Generates a card with the specified filetype and size instead of downloading the file
] {
    let $source = $source | default $env.cy.ipfs-download-from
    let $status = match $source {
        'gateway' => {particle-download-gateway $cid --info_only=$info_only}
        'kubo' => {particle-download-kubo $cid --info_only=$info_only}
    }

    if ($status) in ['text' 'non_text'] {
        queue-db-cid-request-completed $cid
        'downloaded'
    } else if $status == 'not found' {
        queue-db-cid-request-failed $cid
        'not found'
    }
}

# Download a cid from kubo (go-ipfs cli) immediately
def 'particle-download-kubo' [
    cid: string
    --timeout = '300s'
    --info_only # # Generates a card with the specified filetype and size instead of downloading the file
] {
    log debug $'cid to download ($cid)'
    let $file_path = particle-path $cid
    let $type = ^ipfs cat --timeout $timeout -l 400 $cid
        | complete
        | if $in == null or $in.exit_code == 1 {
            'empty'
        } else {
            get stdout
            | file - --mime
            | $in + ''
            | str replace (char nl) ''
            | str replace '/dev/stdin: ' ''
        }

    if ($type =~ '^empty') {
        return 'not found'
    } else if (
        $type =~ '(text/plain|ASCII text|Unicode text, UTF-8|very short file)' and not $info_only
     ) {
        if (
            ipfs get --progress=false --timeout $timeout -o $file_path $cid
            | complete # complete here is to hide ipfs get err output, as it sends there information
            | $in.exit_code == 0
        ) {
            particle-store-db $cid (open $file_path) # file was saved earlier
            return 'text'
        } else {
            return 'not found'
        }
    } else {
        do -i {
            ^ipfs dag stat $cid --enc json --timeout $timeout | from json
        }
        | default {'Size': null}
        | merge {'MIME type': ($type | split row ';' | get -i 0)}
        | sort -r
        | to toml
        | particle-store $cid $in

        return 'non_text'
    }
}

export def 'particle-path' [
    cid: string
    --no_mkdir
] {
    let $folder_path = $env.cy.ipfs-files-folder
        | path join ($cid | str substring ..3)
        | str downcase

    if not $no_mkdir {
        mkdir $folder_path
    }

    $folder_path
    | path join $'($cid).md'
}

# Download a cid from gateway immediately
def 'particle-download-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --info_only # Don't download the file by write a card with filetype and size
] {
    let $meta = particle-get-type-gateway $cid

    if (
        $'($meta.type?)' == 'text/plain; charset=utf-8' and not $info_only
    ) {
        # to catch response body closed before all bytes were read
        # {http get -e https://gateway.ipfs.cybernode.ai/ipfs/QmdnSiS36vggN6gHbeeoJUBSUEa7B1xTJTcVR8F92vjTHK
        # | save -f temp/test.md}
        try {
            let $content = http get --allow-errors $'($gate_url)($cid)' --max-time 120

            if '<head><title>502 Bad Gateway</title></head>' in $content {
                return 'not found'
            } else {}

            particle-store $cid $content

            return 'text'
        } catch {
            return 'not found'
        }
    } else if ($meta.type? != null) {

        {'MIME type': $meta.type, 'Size': $meta.size?}
        | to toml
        | particle-store $cid $in

        return 'non_text'
    } else {
        return 'not found'
    }
}

# remove from queue CIDs with many attempts
export def 'cache-clean-cids-queue' [
    attempts: int = 15 # limit a number of previous download attempts for cids in queue
] {
    let $files = ls (cy-path temp queue_cids_to_download)
    let $files_dead = cy-path temp queue_cids_dead

    $files
    | where size > ($attempts | into filesize)
    | get name
    | each {|i|
        try {
            mv $i $files_dead
        } catch {
            open $i | save -a (cy-path temp queue_cids_dead ($i | path basename))
            rm $i
        }
    }
}
