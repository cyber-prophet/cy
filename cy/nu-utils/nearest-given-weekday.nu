export def main [
    --hour_24 = 12
    --weekday = 'Tuesday'
    --weeks = 2
] {
    seq date --days 8
    | reverse
    | drop
    | into datetime
    | where {|x| ($x | format date "%A") == $weekday}
    | first
    | $in + ($weeks * 1wk) + ($hour_24 * 1hr)
}
