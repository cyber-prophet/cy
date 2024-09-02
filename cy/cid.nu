use queue.nu [queue-task-add]

# Obtain cid info
#
# > cy cid-get-type-gateway QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV | to yaml
# type: text/plain; charset=utf-8
# size: '5'
export def 'cid-get-type-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --to_csv
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

    log_row_csv --cid $cid --source $gate_url --type $type --size $size --status '3.downloaded headers'

    {type: $type size: $size}
}


# Read a CID from the cache, and if the CID is absent - add it into the queue
export def 'cid-read-or-download' [
    cid: string
    --full # output full text of a particle
] {
    $env.cy.ipfs-files-folder | path join $'($cid).md'
    | if ($in | path exists) {
        open
    } else {
        queue-task-add $'cid-download ($cid)'
        'downloading'
    }
    | if $full {} else {
        str substring 0..400
        | str replace (char nl) '↩' --all
        | $'($in)(char nl)(ansi grey)($cid)(ansi reset)'
    }
}

# Add a cid into queue to download asynchronously
export def 'cid-download-async' [
    cid: string
    --force (-f)
    --source: string # kubo or gateway
    --info_only # Don't download the file by write a card with filetype and size
    --folder: string
] {
    let $folder = $folder | default $'($env.cy.ipfs-files-folder)'
    let $content = do -i {open ($env.cy.ipfs-files-folder | path join $'($cid).md')}
    let $source = $source | default $env.cy.ipfs-download-from

    let $task = $'cid-download ($cid) --source ($source) --info_only=($info_only) --folder "($folder)"'

    if $content == null or $content == 'timeout' or $force {
        queue-task-add $task
        print 'downloading'
    }
}

# Download cid immediately and mark it in the queue
export def 'cid-download' [
    cid: string
    --source: string # kubo or gateway
    --info_only # Generates a card with the specified filetype and size instead of downloading the file
    --folder: path # Folder path to save the file
] {
    let $folder = $folder | default $env.cy.ipfs-files-folder
    let $source = $source | default $env.cy.ipfs-download-from
    let $status = match $source {
        'gateway' => {cid-download-gateway $cid --info_only=$info_only --folder $folder}
        'kubo' => {cid-download-kubo $cid --info_only=$info_only --folder $folder}
    }

    if ($status) in ['text' 'non_text'] {
        rm --force (cy-path temp queue_cids_to_download $cid)
        'downloaded'
    } else if $status == 'not found' {
        queue-cid-add $cid '-'
        'not found'
        # error make {msg: $'($cid) is not found'}
    }
}

# Download a cid from kubo (go-ipfs cli) immediately
def 'cid-download-kubo' [
    cid: string
    --timeout = '300s'
    --folder: path # Folder path to save the file
    --info_only # # Generates a card with the specified filetype and size instead of downloading the file
] {
    log debug $'cid to download ($cid)'
    let $file_path = $folder | default $env.cy.ipfs-files-folder | path join $'($cid).md'
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
        | save -f $file_path

        return 'non_text'
    }
}

# Download a cid from gateway immediately
def 'cid-download-gateway' [
    cid: string
    --gate_url: string = 'https://gateway.ipfs.cybernode.ai/ipfs/'
    --folder: string
    --info_only # Don't download the file by write a card with filetype and size
] {
    let $file_path = $folder | default $env.cy.ipfs-files-folder | path join $'($cid).md'
    let $meta = cid-get-type-gateway $cid

    if (
        ($meta.type? | default '') == 'text/plain; charset=utf-8' and not $info_only
    ) {
        # to catch response body closed before all bytes were read
        # {http get -e https://gateway.ipfs.cybernode.ai/ipfs/QmdnSiS36vggN6gHbeeoJUBSUEa7B1xTJTcVR8F92vjTHK
        # | save -f temp/test.md}
        try {
            http get -e $'($gate_url)($cid)' -m 120
            | if ($in | str contains '<head><title>502 Bad Gateway</title></head>') {
                return 'not found'
            } else {}
            | save -f $file_path
        } catch {
            return 'not found'
        }
        return 'text'
    } else if ($meta.type? != null) {
        {'MIME type': $meta.type, 'Size': $meta.size?}
        | sort -r
        | to toml
        | save -f $file_path

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
