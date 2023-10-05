# Format big numbers nicely
export def main [
    num                             # Number to format
    --thousands_delim (-t) = '_'    # Thousands delimiter: number-format 1000 -t ': 1'000
    --whole_part_length (-w) = 0    # Length of padding whole-part digits: number-format 123 -w 6:    123
    --decimal_digits (-d) = 0       # Number of digits after decimal delimiter: number-format 1000.1234 -d 2: 1000.12
    --denom (-D) = ''               # Denom `--denom "Wt": number-format 1000 --denom 'Wt': 1000Wt
] {

    let parts = (
        $num
        | into string
        | split row "."
    )

    let $whole_part = (
        $parts.0
        | split chars
        | reverse
        | enumerate
        | reduce -f [] { |it, acc|
            $acc
            | append $it.item
            | if ((($it.index + 1) mod 3) == 0) {
                append $thousands_delim
            } else { }
        }
        | reverse
        | if ($in | first) == $thousands_delim {
            skip 1
        } else { }
        | str join ''
        | if $whole_part_length == 0 { } else {
            fill -w $whole_part_length -c ' ' -a r
        }
    )

    let dec_part = (
        if ($parts | length) == 1 { # i.e. there are no symbols after '.' in the given number
            "0"
        } else {
            $parts.1
        }
    )

    let dec_part2 = (
        if $decimal_digits == 0 {
            ''
        } else {
            $".($dec_part)"
            | fill -w ($decimal_digits + 1) -c '0' -a l
        }
    )

    $"(ansi green)($whole_part)($dec_part2)(ansi reset)(ansi green_bold)($denom)(ansi reset)"
}

export def number-col-format [
    column_name: string
    --thousands_delim (-t) = '_'    # Thousands delimiter: number-format 1000 -t ': 1'000
    --decimal_digits (-d) = 0       # Number of digits after decimal delimiter: number-format 1000.1234 -d 2: 1000.12
    --denom (-D) = ''               # Denom `--denom "Wt": number-format 1000 --denom 'Wt': 1000Wt
] {
    let $input = $in

    if $column_name not-in ($input | columns) {
        error make {'msg': $'There is no ($column_name) in columns'}
    }

    # let $whole_part_length = (
    #     $input
    #     | get $column_name
    #     | math max
    #     | number-format $in --denom $denom --decimal_digits $decimal_digits --thousands_delim $thousands_delim
    #     | inspect
    #     | str length --grapheme-clusters
    #     | append ($column_name | str length)
    #     | math max
    #     | $in - $decimal_digits - ($thousands_delim | str length) - ($denom | str length)
    # )

    # let $whole_part_length = (
    #     $input
    #     | get $column_name
    #     | math max
    #     | into string
    #     | split row '.'
    #     | get 0
    #     | str length
    #     | number-format $in --denom $denom --decimal_digits $decimal_digits --thousands_delim $thousands_delim
    #     | inspect
    #     | str length --grapheme-clusters
    #     | append ($column_name | str length)
    #     | math max
    #     | $in - $decimal_digits - ($thousands_delim | str length) - ($denom | str length)
    # )

    let $thousands_delim_length = ($thousands_delim | str length --grapheme-clusters)

    let $whole_part_length = (
        $input
        | get $column_name
        | math max
        | split row '.'
        | get 0
        | str length
        | inspect
        | if $thousands_delim_length > 0 {
                $in * ((3 + $thousands_delim_length) / 3 - 0.001) | math floor
        } else {}
        | inspect
        | append (
            $column_name | str length
            | $in - $decimal_digits - $thousands_delim_length - ($denom | str length --grapheme-clusters)
        )
        | math max
    )


    $input
    | upsert $column_name {
        |i| (
            number-format ($i | get $column_name)
            --denom $denom --decimal_digits $decimal_digits
            --thousands_delim $thousands_delim --whole_part_length $whole_part_length
        )
    }
}