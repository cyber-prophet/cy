use to-number-format.nu

export def main [
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
        | if $thousands_delim_length > 0 {
                $in * ((3 + $thousands_delim_length) / 3 - 0.001) | math floor
        } else {}
        | append (
            $column_name | str length
            | $in - $decimal_digits - $thousands_delim_length - ($denom | str length --grapheme-clusters)
        )
        | math max
    )


    $input
    | upsert $column_name {
        |i| (
            to-number-format ($i | get $column_name)
            --denom $denom --decimal_digits $decimal_digits
            --thousands_delim $thousands_delim --whole_part_length $whole_part_length
        )
    }
}