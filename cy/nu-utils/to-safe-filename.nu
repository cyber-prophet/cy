export def main [
    --prefix: string = ''
    --suffix: string = ''
    --regex: string = '[^A-Za-z0-9_А-Яа-я+]' # symbols to keep
    --timestamp
    --hash # add hash to filenames longer than 220 symbols
]: string -> string {
    str replace -ra $regex '_'
    | str replace -ra '__+' '_'
    | if (($in | str length) > 220) {
        str substring ..220
        | if $hash and not $timestamp {
            $'($in)($in | hash sha256 | str substring ..10)' # make string uniq
        } else {}
    } else {}
    | if $timestamp {
        $'(date now | format date "%Y%m%d_%H%M%S")+($in)' # make string uniq
    } else {}
    | $'($prefix)($in)($suffix)'
}
