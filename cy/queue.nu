use cy-internals.nu [cy-path]
use std log

export def 'queue-task-add' [
    command: string
    --priority (-o): int = 1
] {
    let $filename = $command
        | to-safe-filename --prefix $'($priority)-' --suffix '.nu.txt'
        | cy-path temp queue_tasks_to_run $in

    $'use (cy-path cy cy-full.nu) *; ($command)'
    | save -f $filename
}

export def --env 'queue-tasks-monitor' [
    --threads: int = 10
    --cids_in_run: int = 10 # a number of files to download in one command run. 0 - means all (default)
] {
    loop {
        glob (cy-path temp queue_tasks_to_run *.nu.txt)
        | sort
        | if ($in | length) == 0 { } else {
            par-each -t $threads {
                |i| queue-execute-task $i
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
        $command + ';' | save -a (cy-path temp queue_tasks_failed ($task_path | path basename))
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
    let $files = ls -s (cy-path temp queue_cids_to_download)

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
    let $path = cy-path temp queue_cids_to_download $cid

    if not ($path | path exists) {
        touch $path
    } else if $symbol != '' {
        $symbol | save -a $path
    }
}

def add-background-task [
    executable
    sub_commands_and_args
] {
    $sub_commands_and_args
    | each { to json } # escape quotes
    | str join ' '
    | prepend $'caching-function --exec ($executable) --force_update ['
    | append '] | to yaml | lines | first 5 | to text'
    | str join
    | queue-task-add -o 2 $in
}

# A wrapper, to cache CLI requests
export def --wrapped 'caching-function' [
    ...rest
    --exec: string = '' # The name of executable
    --cache_validity_duration: duration = 60min # Sets the cache's valid duration.
                                                # No updates initiated during this period.
                                                # set to 0sec to request for
    --cache_stale_refresh: duration # Sets stale cache's usable duration.
                                    # Triggers background update and returns cache results.
                                    # If exceeded, requests immediate data update.
    --force_update
    --disable_update (-U)
    --quiet # Don't output execution's result
    --no_default_params # Don't use default params (like output, chain-id)
    --error # raise error instead of null in case of cli's error
    --retries: int
]: nothing -> record {
    if ($retries != null) {$env.cy.caching-function-max-retries = $retries}

    let $rest = $rest | flatten | flatten | into string

    let $cache_stale_refresh = set-get-env caching-function-cache_stale_refresh $cache_stale_refresh

    if $rest == [] { error make {msg: 'The "caching-function" function needs arguments'} }

    let $executable = if $exec != '' {$exec} else {$env.cy.exec}
    let $sub_commands_and_args = $rest
        | if $no_default_params {} else {
            append (default-node-params)
        }

    let $json_path = generate-cache-path $executable $sub_commands_and_args

    log debug $'json path: ($json_path)'

    let $last_data = if ($json_path | path exists) {
            # use debug here print $json_path
            open $json_path
        } else {
            {'update_time': 0}
        }
        | into datetime update_time

    let $freshness = (date now) - $last_data.update_time

    mut $update = (
        $force_update or
        ($env.cy.caching-function-force-update? | default false) or
        ($freshness > $cache_stale_refresh and not $disable_update)
    )

    if 'error' in ($last_data | columns) {
        log debug $'last update ($freshness) was unsuccessful, requesting for a new one'
        $update = true
    }

    if $update {
        (request-save-output-exec-response $executable $sub_commands_and_args $json_path
            --error=$error --quiet=$quiet --last_data $last_data)
    } else {
        if $freshness > $cache_validity_duration {
            add-background-task $executable $sub_commands_and_args
        }

        $last_data
    }
}

def 'request-save-output-exec-response' [
    executable: string
    sub_commands_and_args: list
    json_path: string
    --error
    --quiet
    --last_data: = {'update_time': 0}
] {
    log debug $'($executable) ($sub_commands_and_args | str join " ")'

    mut $retries = (
        $env.cy?.caching-function-max-retries?
        | default 5
        | $in + 1 # so if we set caching-function-max-retries to 1 only 1 retry would be made
    )

    mut $response = {}

    let $request = {
        ^($executable) ...$sub_commands_and_args
        | complete
        | if $in.exit_code == 0 {
            get stdout
            | from json
            | insert update_time (date now)
        } else {
            {error: $in, update_time: (date now)}
        }
    }

    while $retries > 0 {
        $response = (do $request)

        if $response.error? == null {
            $retries = 0
        } else {
            sleep 2sec
            $retries = $retries - 1
        }
    }

    $response
    | to json -r
    | save --raw --force $json_path

    if 'error' in ($response | columns) {
        if $error {
            error make {msg: ($response.error.stderr | lines | first)}
        } else {
            return
        }
    }

    $last_data
    | if ($in.update_time | into int) != 0 {
        to json -r
        | $'($in)(char nl)'
        | save --append --raw ($json_path | str replace '.json' '_arch.jsonl')
    }

    if not $quiet {$response}
}

def generate-cache-path [
    $executable
    $sub_commands_and_args
] {
    $executable
    | append ($sub_commands_and_args)
    | str join '_'
    | str replace -r '--node.*' ''
    | str trim -c '_'
    | to-safe-filename --suffix '.json'
    | cy-path cache jsonl --file $in
}
