export def main [
    --version (-v): int = 1 #version of shortening
    --prefix: string = ''
    --suffix: string = ''
] {
    $in
    | if $version == 1 {
        str replace -r -a '[^A-Za-z0-9_А-Яа-я]' '_'
        | str replace -r -a '_+' '_'
        | if (($in | str length) > 220) {
            $'($in | str substring ..220)($in | hash sha256 | str substring ..10)' # make string uniq
        } else {}
        | $'($prefix)($in)($suffix)'
    } else {
        error make {msg: $'($version) is unknown'}
    }
}
