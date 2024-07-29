export def main [
    --hour_24 = 12
    --weekday = 'Tuesday'
    --weeks = 2
] {
    # find the specified weekday in the next 7 days, to start counting from it
    seq date --days 8 | reverse | drop | into datetime
    | where {|x| ($x | format date "%A") == $weekday}
    | first
    | $in + ($weeks * 1wk) + ($hour_24 * 1hr) - (date now)
    | into int
    | $in / 1_000_000_000
    | math round
}