
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
