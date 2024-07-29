export def main [
    --prefix: string
    --suffix: string
    --parent_dir: string
]: path -> path {
    path parse
    | upsert stem {|i| $'($prefix)($i.stem)($suffix)'}
    | if $parent_dir != null {
        upsert parent {|i|
            $i.parent
            | path join $parent_dir
            | $'(mkdir $in)($in)' # The author doesn't like that, but tee in 0.91 somehow consumes and produces list here
        }
    } else {}
    | path join
}
