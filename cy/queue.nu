
export def 'queue-task-add' [
    command: string
    --priority (-o): int = 1
] {
    let $filename = $command
        | to-safe-filename --prefix $'($priority)-' --suffix '.nu.txt'
        | cy-path cache queue_tasks_to_run $in

    $'use (cy-path cy.nu) *; ($command)'
    | save -f $filename
}

export def --env 'queue-tasks-monitor' [
    --threads: int = 10
    --cids_in_run: int = 10 # a number of files to download in one command run. 0 - means all (default)
] {
    loop {
        glob (cy-path cache queue_tasks_to_run *.nu.txt)
        | sort
        | if (is-connected-interval 10min) {
            if ($in | length) == 0 { } else {
                par-each -t $threads {
                    |i| queue-execute-task $i
                }
            }
        }
        sleep 1sec
        print -n $"(char cr)⌛(date now | format date '%H:%M:%S') - to exit press `ctrl+c`"
    }
}

export def 'queue-execute-task' [
    task_path: path
] {
    let $command = open $task_path

    let $results = ^nu --config $nu.config-path --env-config $nu.env-path $task_path
        | complete

    $results
    | if $in.exit_code == 0 {
        print -n $'(char nl)🔵 ($command)'
        print -n $'(char nl)($results.stdout)'
    } else {
        print -n $'(char nl)🛑 ($command)'
        $command + ';' | save -a (cy-path cache queue_tasks_failed ($task_path | path basename))
    }
    ^rm -f $task_path
    log debug $'run ($command)'
}


# Check the queue for the new CIDs, and if there are any, safely download the text ones
export def 'queue-cids-download' [
    attempts: int = 0 # limit a number of previous download attempts for cids in queue
    --info # don't download data, just check queue
    --quiet # Disable informational messagesrmation
    --threads: int = 15 # a number of threads to use for downloading
    --cids_in_run: int = 0 # a number of files to download in one command run. 0 - means all (default)
] {
    let $files = ls -s (cy-path cache queue_cids_to_download)

    if ($files | length) == 0 {
        return 'there are no files in queue'
    }

    if not $quiet {
        cprint $'Overall count of files in queue is *($files | length)*'
        cprint $'*($env.cy.ipfs-download-from)* will be used for downloading'
    }

    let $filtered_files = $files
        | where size <= (1 + $attempts | into filesize)
        | sort-by size

    let $filtered_count = $filtered_files | length

    if $filtered_files == [] {
        if not $quiet {
            print $'There are no files, that was attempted to download for less than ($attempts) times.'}
        return
    } else {
        if not $quiet {
            print $'There are ($filtered_count) files that was attempted to be downloaded ($attempts) times already.'

            ($filtered_files | sort-by modified -r | sort-by size | get modified.0 -i)
            | print $'The latest file was added into the queue ($in)'
        }
    }

    if $info {return}

    ($filtered_files | where size < 4b | sort-by modified -r | sort-by size) # new small files first
    | append (
        $filtered_files
        | where size >= 4b
        | where modified < (date now | $in - 5hr)
        | sort-by modified # old files first
    )
    | get name -i
    | if $cids_in_run > 0 {
        first $cids_in_run
    } else {}
    | enumerate
    | par-each -t $threads {
        |i| cid-download $i.item
        | if $nu.is-interactive {
            print -n $'(if ($in == "not found") {'-'} else {'+'})'
            # print -n $"( ansi -e '1000D' )( bar --width 60 --background yellow ($i.index / $filtered_count)) ($i.index):($in)"
        } else {}
    }
}


# Add a CID to the download queue
export def 'queue-cid-add' [
    cid: string
    symbol: string = ''
] {
    let $path = cy-path cache queue_cids_to_download $cid

    if not ($path | path exists) {
        touch $path
    } else if $symbol != '' {
        $symbol | save -a $path
    }
}
