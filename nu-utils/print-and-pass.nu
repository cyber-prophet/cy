export def main [
    callback?: closure
] {
    let $input = $in

    if $callback == null {
        print $input
    } else {
        do $callback $input
    }

    $input
}
