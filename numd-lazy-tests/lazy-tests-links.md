```nushell
> overlay use ~/cy/cy -pr
> $env.config.table.abbreviated_row_count = 10000
> cy help-cy
> cy help-cy | length
> $env.IPFS_PATH = /Users/user/.ipfs_blank
> cy pin-text 'cyber'
> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
> cy pin-text 'linkfilestest/cyber.txt'
> cy pin-text ([linkfilestest cyber.txt] | path join) --follow_file_path
> cy link-texts "cyber" "bostrom"
> cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom"
> cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --ignore_cid
> cy set-cy-setting ipfs-upload-with-no-confirm 'true'
> cy link-chain bostrom cyber superintelligence
> cy set-links-table-name lazy-tests-links-1
> cd linkfilestest
> cy link-files --link_filenames --yes --include_extension
> cy link-files --link_filenames --yes --include_extension bostrom.txt
> cd ..
> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only
> cy links-clear
> cy tweet 'cyber-prophet is cool' --disable_send
> cy set-links-table-name lazy-tests-links-2
> [{from_text: 'cyber' to_text: 'bostrom'}] | cy links-replace
> cy links-pin-columns | reject timestamp -i
> cy links-view | reject timestamp -i
> cy links-link-all 'cy testing script'
> cy links-view | reject timestamp -i
> cy config-activate 42gboot+cyber
> cy link-random 3 | to yaml
> cy link-random 3 --source forismatic.com | to yaml
> cy link-random 3 --source chucknorris.io | to yaml
> cy links-remove-existed-1by1
```
