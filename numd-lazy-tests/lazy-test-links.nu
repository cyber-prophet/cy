# this script was generated automatically using numd
# https://github.com/nushell-prophet/numd

const init_numd_pwd_const = '/Users/user/cy/numd-lazy-tests'

"```nushell" | print
"> if (ps | where name =~ ipfs | is-empty) {wezterm cli spawn -- /Users/user/.cargo/bin/nu -c \"$env.IPFS_PATH = '/Users/user/.ipfs_blank'; ipfs daemon\"}" | nu-highlight | print

if (ps | where name =~ ipfs | is-empty) {wezterm cli spawn -- /Users/user/.cargo/bin/nu -c "$env.IPFS_PATH = '/Users/user/.ipfs_blank'; ipfs daemon"}

"> overlay use ~/cy/cy -pr" | nu-highlight | print

overlay use ~/cy/cy -pr

"> $env.config.table.abbreviated_row_count = 10000" | nu-highlight | print

$env.config.table.abbreviated_row_count = 10000

"> cy help-cy" | nu-highlight | print

cy help-cy | table --width 200 | print; print ''

"> cy help-cy | length" | nu-highlight | print

cy help-cy | length | table --width 200 | print; print ''

"> $env.IPFS_PATH = '/Users/user/.ipfs_blank'" | nu-highlight | print

$env.IPFS_PATH = '/Users/user/.ipfs_blank'

"> cy set-cy-setting ipfs-download-from kubo" | nu-highlight | print

cy set-cy-setting ipfs-download-from kubo | table --width 200 | print; print ''

"> cy pin-text 'cyber'" | nu-highlight | print

cy pin-text 'cyber' | table --width 200 | print; print ''

"> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'" | nu-highlight | print

cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' | table --width 200 | print; print ''

"> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid" | nu-highlight | print

cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid | table --width 200 | print; print ''

"> cy pin-text 'linkfilestest/cyber.txt'" | nu-highlight | print

cy pin-text 'linkfilestest/cyber.txt' | table --width 200 | print; print ''

"> cy pin-text ([linkfilestest cyber.txt] | path join) --follow_file_path" | nu-highlight | print

cy pin-text ([linkfilestest cyber.txt] | path join) --follow_file_path | table --width 200 | print; print ''

"> cy link-texts \"cyber\" \"bostrom\"" | nu-highlight | print

cy link-texts "cyber" "bostrom" | table --width 200 | print; print ''

"> cy link-texts \"QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV\" \"bostrom\"" | nu-highlight | print

cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" | table --width 200 | print; print ''

"> cy link-texts \"QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV\" \"bostrom\" --only_hash" | nu-highlight | print

cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --only_hash | table --width 200 | print; print ''

"> cy link-texts \"QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV\" \"bostrom\" --ignore_cid" | nu-highlight | print

cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --ignore_cid | table --width 200 | print; print ''

"> cy set-cy-setting ipfs-upload-with-no-confirm 'true'" | nu-highlight | print

cy set-cy-setting ipfs-upload-with-no-confirm 'true' | table --width 200 | print; print ''

"> cy link-chain bostrom cyber superintelligence" | nu-highlight | print

cy link-chain bostrom cyber superintelligence | table --width 200 | print; print ''

"> cy link-chain '1483' '982' '1471' '195' '1427' '2054' '1642' '358' '1712' '1419' '219' '767' '1419' '1126' '577' '756' '141' '622' '1169' '1932' '407' '1880' '659' '871' '1161' '1651' '1845' '1506' '1446' '751' '1064' '704' '1255' '199' '309' '982' '290' '2011' '211'" | nu-highlight | print

cy link-chain '1483' '982' '1471' '195' '1427' '2054' '1642' '358' '1712' '1419' '219' '767' '1419' '1126' '577' '756' '141' '622' '1169' '1932' '407' '1880' '659' '871' '1161' '1651' '1845' '1506' '1446' '751' '1064' '704' '1255' '199' '309' '982' '290' '2011' '211' | table --width 200 | print; print ''

"> cy set-links-table-name lazy-tests-links-1" | nu-highlight | print

cy set-links-table-name lazy-tests-links-1 | table --width 200 | print; print ''

"> cd linkfilestest" | nu-highlight | print

cd linkfilestest | table --width 200 | print; print ''

"> cy link-files --link_filenames --yes --include_extension" | nu-highlight | print

cy link-files --link_filenames --yes --include_extension | table --width 200 | print; print ''

"> cy link-files --link_filenames --yes --include_extension bostrom.txt" | nu-highlight | print

cy link-files --link_filenames --yes --include_extension bostrom.txt | table --width 200 | print; print ''

"> cy link-files --link_filenames --yes --include_extension --disable_append bostrom.txt" | nu-highlight | print

cy link-files --link_filenames --yes --include_extension --disable_append bostrom.txt | table --width 200 | print; print ''

"> cy links-clear" | nu-highlight | print

cy links-clear | table --width 200 | print; print ''

"> cy link-folder" | nu-highlight | print

cy link-folder | table --width 200 | print; print ''

"> cy link-folder --no_content" | nu-highlight | print

cy link-folder --no_content | table --width 200 | print; print ''

"> cy link-folder --no_folders" | nu-highlight | print

cy link-folder --no_folders | table --width 200 | print; print ''

"> cd .." | nu-highlight | print

cd .. | table --width 200 | print; print ''

"> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8" | nu-highlight | print

cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 | table --width 200 | print; print ''

"> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only" | nu-highlight | print

cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only | table --width 200 | print; print ''

"> cy links-clear" | nu-highlight | print

cy links-clear | table --width 200 | print; print ''

"> cy tweet 'cyber-prophet is cool' --disable_send" | nu-highlight | print

cy tweet 'cyber-prophet is cool' --disable_send | table --width 200 | print; print ''

"> cy set-links-table-name lazy-tests-links-2" | nu-highlight | print

cy set-links-table-name lazy-tests-links-2 | table --width 200 | print; print ''

"> [{from_text: 'cyber' to_text: 'bostrom'}] | cy links-replace" | nu-highlight | print

[{from_text: 'cyber' to_text: 'bostrom'}] | cy links-replace | table --width 200 | print; print ''

"> cy links-pin-columns | reject timestamp -i" | nu-highlight | print

cy links-pin-columns | reject timestamp -i | table --width 200 | print; print ''

"> cy links-view | reject timestamp -i" | nu-highlight | print

cy links-view | reject timestamp -i | table --width 200 | print; print ''

"> cy links-link-all 'cy testing script'" | nu-highlight | print

cy links-link-all 'cy testing script' | table --width 200 | print; print ''

"> cy links-view | reject timestamp -i" | nu-highlight | print

cy links-view | reject timestamp -i | table --width 200 | print; print ''

"> cy config-activate 42gboot+cyber" | nu-highlight | print

cy config-activate 42gboot+cyber | table --width 200 | print; print ''

"> cy link-random 3 | to yaml" | nu-highlight | print

cy link-random 3 | to yaml | table --width 200 | print; print ''

"> cy link-random 3 --source forismatic.com | to yaml" | nu-highlight | print

cy link-random 3 --source forismatic.com | to yaml | table --width 200 | print; print ''

"> cy link-random 3 --source chucknorris.io | to yaml" | nu-highlight | print

cy link-random 3 --source chucknorris.io | to yaml | table --width 200 | print; print ''

"> cy links-remove-existed-1by1" | nu-highlight | print

cy links-remove-existed-1by1 | table --width 200 | print; print ''

"> cy links-publish" | nu-highlight | print

cy links-publish | table --width 200 | print; print ''

"```" | print
