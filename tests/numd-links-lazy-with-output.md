```nushell
> if (ps | where name =~ ipfs | is-empty) {wezterm cli spawn -- /Users/user/.cargo/bin/nu -c "$env.IPFS_PATH = '/Users/user/.ipfs_blank'; ipfs daemon"}
19
> overlay use ~/cy/cy -pr
> $env.config.table.abbreviated_row_count = 10000
> cy help-cy
╭─#──┬────────────────command─────────────────┬────────────────────────────────────────────────────────desc─────────────────────────────────────────────────────────╮
│ 0  │ cy pin-text                            │ Pin a text particle                                                                                                 │
│ 1  │ cy link-texts                          │ Add a 2-texts cyberlink to the temp table                                                                           │
│ 2  │ cy link-chain                          │ Add a link chain to the temp table                                                                                  │
│ 3  │ cy link-files                          │ Pin files from the current folder to the local node and append their cyberlinks to the temp table                   │
│ 4  │ cy link-folder                         │ Create cyberlinks to hierarchies (if any) `parent_folder - child_folder`, `folder - filename`, `filename - content` │
│ 5  │ cy follow                              │ Create a cyberlink according to `following a neuron` semantic convention                                            │
│ 6  │ cy tweet                               │ Add a tweet and send it immediately (unless of `--disable_send`)                                                    │
│ 7  │ cy link-random                         │ Make a random cyberlink from different APIs (chucknorris.io, forismatic.com)                                        │
│ 8  │ cy links-view                          │ View the temp cyberlinks table                                                                                      │
│ 9  │ cy links-append                        │ Append piped-in table to the temp cyberlinks table                                                                  │
│ 10 │ cy links-replace                       │ Replace the temp table with piped-in table                                                                          │
│ 11 │ cy links-swap-from-to                  │ Swap columns `from` and `to`                                                                                        │
│ 12 │ cy links-clear                         │ Empty the temp cyberlinks table                                                                                     │
│ 13 │ cy links-link-all                      │ Add the same text particle into the 'from' or 'to' column of the temp cyberlinks table                              │
│ 14 │ cy links-pin-columns                   │ Pin values of 'from_text' and 'to_text' columns to an IPFS node and fill `from` and `to` with their CIDs            │
│ 15 │ cy links-remove-existed-1by1           │ Remove existing in cybergraph cyberlinks from the temp table                                                        │
│ 16 │ cy links-remove-existed-using-snapshot │ Remove existing links using graph snapshot data                                                                     │
│ 17 │ cy links-publish                       │ Publish all links from the temp table to cybergraph                                                                 │
│ 18 │ cy set-links-table-name                │ Set a custom name for the temp links csv table                                                                      │
│ 19 │ cy config-new                          │ Create a config JSON to set env variables, to use them as parameters in cyber cli                                   │
│ 20 │ cy config-view                         │ View a saved JSON config file                                                                                       │
│ 21 │ cy config-save                         │ Save the piped-in JSON into a config file inside of `cy/config` folder                                              │
│ 22 │ cy config-activate                     │ Activate the config JSON                                                                                            │
╰─#──┴────────────────command─────────────────┴────────────────────────────────────────────────────────desc─────────────────────────────────────────────────────────╯

> cy help-cy | length
23

> $env.IPFS_PATH = '/Users/user/.ipfs_blank'
> cy set-cy-setting ipfs-download-from kubo

> cy pin-text 'cyber'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV'
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy pin-text 'QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV' --ignore_cid
QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F

> cy pin-text 'linkfilestest/cyber.txt'
QmafiM9MqvpAh4eZJrB7KJ3BAaEqphJGS9EDpLnMePKCPn

> cy pin-text ([linkfilestest cyber.txt] | path join) --follow_file_path
QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV

> cy link-texts "cyber" "bostrom"
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ cyber                                          │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom"
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --only_hash
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ bostrom                                        │
│ from      │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to        │                                                │
╰───────────┴────────────────────────────────────────────────╯

> cy link-texts "QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV" "bostrom" --ignore_cid
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ to_text   │ bostrom                                        │
│ from      │ QmcDUZon6VQLR3gjAvSKnudSVQ2RbGXUtFFV8mR6zHZK8F │
│ to        │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰───────────┴────────────────────────────────────────────────╯

> cy set-cy-setting ipfs-upload-with-no-confirm 'true'

> cy link-chain bostrom cyber superintelligence
temp files saved to a local directory
/Users/user/cy/temp/ipfs_upload/20240823-145137-654484000
╭─#─┬─from_text─┬──────to_text──────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ bostrom   │ cyber             │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ 1 │ cyber     │ superintelligence │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmRMMbTqFQ3o2NmHNYzLoS5fjT5WE3h9Sn21MvmEcsvJ8M │
╰─#─┴─from_text─┴──────to_text──────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy link-chain '1483' '982' '1471' '195' '1427' '2054' '1642' '358' '1712' '1419' '219' '767' '1419' '1126' '577' '756' '141' '622' '1169' '1932' '407' '1880' '659' '871' '1161' '1651' '1845' '1506' '1446' '751' '1064' '704' '1255' '199' '309' '982' '290' '2011' '211'
temp files saved to a local directory
/Users/user/cy/temp/ipfs_upload/20240823-145137-731717000
╭─#──┬─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0  │ 1483      │ 982     │ QmP1cSbc8ZC11DWMLBW5GC7qqNSfqhVgJ4aqtdZ284Ykau │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │
│ 1  │ 982       │ 1471    │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │ QmUKENavbrxPeBa2krN7jiozBSszbXRENB59qqbGJtx5cR │
│ 2  │ 1471      │ 195     │ QmUKENavbrxPeBa2krN7jiozBSszbXRENB59qqbGJtx5cR │ QmYTkmKghJGoBcQmupqFwMTFZZXwzRKuE9EGtZZmHGAX7T │
│ 3  │ 195       │ 1427    │ QmYTkmKghJGoBcQmupqFwMTFZZXwzRKuE9EGtZZmHGAX7T │ QmZuyMxDLKQMET3XTDzDYjquse89xn47PdRmqE6ziFCzA1 │
│ 4  │ 1427      │ 2054    │ QmZuyMxDLKQMET3XTDzDYjquse89xn47PdRmqE6ziFCzA1 │ QmVXFuHgp6P9WGRWTvAhvThbBipkzQNDHM2gcryB4E5fFi │
│ 5  │ 2054      │ 1642    │ QmVXFuHgp6P9WGRWTvAhvThbBipkzQNDHM2gcryB4E5fFi │ QmcAQHNBXh9pVNucRuozaqxBYJTAvML8n2h7gGigXZKdKK │
│ 6  │ 1642      │ 358     │ QmcAQHNBXh9pVNucRuozaqxBYJTAvML8n2h7gGigXZKdKK │ QmQgpSPrG7SCntyzZCS6ibQQew3ctztctrLPVzRA6PqZyq │
│ 7  │ 358       │ 1712    │ QmQgpSPrG7SCntyzZCS6ibQQew3ctztctrLPVzRA6PqZyq │ QmNQQCmT8Z2EgDN5nnGe3PwJJXz7xyzhacmCfYgxrQG7cN │
│ 8  │ 1712      │ 1419    │ QmNQQCmT8Z2EgDN5nnGe3PwJJXz7xyzhacmCfYgxrQG7cN │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │
│ 9  │ 1419      │ 219     │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │ QmZd18vhFadcESQQb5jGt8Yone64jF6BMEhnfKPCD9PVdz │
│ 10 │ 219       │ 767     │ QmZd18vhFadcESQQb5jGt8Yone64jF6BMEhnfKPCD9PVdz │ QmaWEi25WdRQwmkT45NBKd17YQBNVebiiXYy1KE5h34d4a │
│ 11 │ 767       │ 1419    │ QmaWEi25WdRQwmkT45NBKd17YQBNVebiiXYy1KE5h34d4a │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │
│ 12 │ 1419      │ 1126    │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │ QmZgTTh22WKZ4pEdEptWfBwh7faeGKhuwwwZt6PaiQtUKi │
│ 13 │ 1126      │ 577     │ QmZgTTh22WKZ4pEdEptWfBwh7faeGKhuwwwZt6PaiQtUKi │ QmfX9pDq46g5QqJYqe6EWEDLMaTG6P5mw4xhGzsqnQBaU8 │
│ 14 │ 577       │ 756     │ QmfX9pDq46g5QqJYqe6EWEDLMaTG6P5mw4xhGzsqnQBaU8 │ QmRGDCLgUCh3UfGEJKADr9wKkvXuarTimqxG8fQtwJ7U7R │
│ 15 │ 756       │ 141     │ QmRGDCLgUCh3UfGEJKADr9wKkvXuarTimqxG8fQtwJ7U7R │ QmYJgdru3bAq7xFeQsk5ywG1MnBeEc2jKzqQnvEtYmpcYP │
│ 16 │ 141       │ 622     │ QmYJgdru3bAq7xFeQsk5ywG1MnBeEc2jKzqQnvEtYmpcYP │ QmQFbhWRKtJdpZY7vuVv3m3hgrE2cLr33C9QSU5ZZcNFgW │
│ 17 │ 622       │ 1169    │ QmQFbhWRKtJdpZY7vuVv3m3hgrE2cLr33C9QSU5ZZcNFgW │ QmbXqs56bvnKbDm3AysmqSaZc97HBpcdhqWnpTLtzaE8Wm │
│ 18 │ 1169      │ 1932    │ QmbXqs56bvnKbDm3AysmqSaZc97HBpcdhqWnpTLtzaE8Wm │ QmQDaeGY9SAjMc9NWXA2pWR5iTUGkg35FY43GxNz3UJqZL │
│ 19 │ 1932      │ 407     │ QmQDaeGY9SAjMc9NWXA2pWR5iTUGkg35FY43GxNz3UJqZL │ QmVtvUZPa7hUd84oaTZe3ftQdLJCNPo2bHCKebXKqxex51 │
│ 20 │ 407       │ 1880    │ QmVtvUZPa7hUd84oaTZe3ftQdLJCNPo2bHCKebXKqxex51 │ Qmf3g1SM3yod9hA48nghhGdJNY6Wa9akxpnTfv4Nv1YYra │
│ 21 │ 1880      │ 659     │ Qmf3g1SM3yod9hA48nghhGdJNY6Wa9akxpnTfv4Nv1YYra │ QmagFXW5vFowXc1AXsW2afZxr6xPuRr1u1qkBPRVtComF5 │
│ 22 │ 659       │ 871     │ QmagFXW5vFowXc1AXsW2afZxr6xPuRr1u1qkBPRVtComF5 │ QmZBpypZ6SpaY7BtLZAa3XSrwcU3qGomeLkjjAZ221FSLs │
│ 23 │ 871       │ 1161    │ QmZBpypZ6SpaY7BtLZAa3XSrwcU3qGomeLkjjAZ221FSLs │ QmVYr4ZeHCZug4AKVkYdKi3N9TYndFEbqE7GFTNjptWeRG │
│ 24 │ 1161      │ 1651    │ QmVYr4ZeHCZug4AKVkYdKi3N9TYndFEbqE7GFTNjptWeRG │ QmfSVoUJ3ZjywMGpdqiepnzfRZ84xmSXYNY2M94nbp4zhG │
│ 25 │ 1651      │ 1845    │ QmfSVoUJ3ZjywMGpdqiepnzfRZ84xmSXYNY2M94nbp4zhG │ QmY4BkaEgajwLvmm672Ev1kMQYXu4oEuPmZhqjzz5bW6w8 │
│ 26 │ 1845      │ 1506    │ QmY4BkaEgajwLvmm672Ev1kMQYXu4oEuPmZhqjzz5bW6w8 │ QmWYNJKezVCN49bDZYkMbvUe12PBf6CT6xVtmuYqBNnQUB │
│ 27 │ 1506      │ 1446    │ QmWYNJKezVCN49bDZYkMbvUe12PBf6CT6xVtmuYqBNnQUB │ QmUxDFPZk6fVxuRT994YXw4Gsw9xxKR8JrY9deXFFW6CEY │
│ 28 │ 1446      │ 751     │ QmUxDFPZk6fVxuRT994YXw4Gsw9xxKR8JrY9deXFFW6CEY │ QmbDvi7Ltb632Lf88huDC2P9fTBs1mmhbgtXPyMSTn5rW4 │
│ 29 │ 751       │ 1064    │ QmbDvi7Ltb632Lf88huDC2P9fTBs1mmhbgtXPyMSTn5rW4 │ QmfCgoLmb927aTosmKF9YT8CDxYRaYX4p4FXMbRzQ2Rtmw │
│ 30 │ 1064      │ 704     │ QmfCgoLmb927aTosmKF9YT8CDxYRaYX4p4FXMbRzQ2Rtmw │ QmYh56iuccfPWBCzy7nFtEWSukVi9GP5iRtieJe1Zq9Nd6 │
│ 31 │ 704       │ 1255    │ QmYh56iuccfPWBCzy7nFtEWSukVi9GP5iRtieJe1Zq9Nd6 │ QmSiGjUtv2Kw5ZZWyBxsRvrXU68oFUSQqNF5zcX3wTQvSq │
│ 32 │ 1255      │ 199     │ QmSiGjUtv2Kw5ZZWyBxsRvrXU68oFUSQqNF5zcX3wTQvSq │ QmbJRpuxjX8PkoPfAb2Q9JsWwt57KwLUyfLRky1Hk81fwL │
│ 33 │ 199       │ 309     │ QmbJRpuxjX8PkoPfAb2Q9JsWwt57KwLUyfLRky1Hk81fwL │ QmYpjTnNRy357rb2QFKaSzzy7ypmdTkJ7MAhvPfrLyv5wS │
│ 34 │ 309       │ 982     │ QmYpjTnNRy357rb2QFKaSzzy7ypmdTkJ7MAhvPfrLyv5wS │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │
│ 35 │ 982       │ 290     │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │ Qmdv5gEJBLwHCebimVuZ2tvZBP2wvWGi7x85TnUUUMQa3B │
│ 36 │ 290       │ 2011    │ Qmdv5gEJBLwHCebimVuZ2tvZBP2wvWGi7x85TnUUUMQa3B │ QmQBMDnoj7mUEbjFrAxXqRQJyHAztoJTbh4nssTqGyNUHF │
│ 37 │ 2011      │ 211     │ QmQBMDnoj7mUEbjFrAxXqRQJyHAztoJTbh4nssTqGyNUHF │ QmUYbmykeoBsaYjtxi8PtJ79rW3YazTVdDDHoPqYzaVyRM │
╰─#──┴─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy set-links-table-name lazy-tests-links-1

> cd linkfilestest

> cy link-files --link_filenames --yes --include_extension
╭─#─┬──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ 1 │ cyber.txt   │ pinned_file:cyber.txt   │ QmXLmkZxEyRk5XELoGpxhQJDBj798CkHeMdkoCKYptSCA6 │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
╰─#─┴──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy link-files --link_filenames --yes --include_extension bostrom.txt
╭─#─┬──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─#─┴──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy link-files --link_filenames --yes --include_extension --disable_append bostrom.txt
╭─#─┬──from_text──┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ bostrom.txt │ pinned_file:bostrom.txt │ QmPtV5CU9v3u7MY7hMgG3z9kTno8o7JHJD1e6f3NLfZ86k │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─#─┴──from_text──┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-clear

> cy link-folder
╭─#─┬───from_text───┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ linkfilestest │ bostrom                 │ QmRetYSHe7E9eNuduiu9pebrMyPC7HYKfYqu9wQqAEuqKR │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ 1 │ bostrom       │ pinned_file:bostrom.txt │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ 2 │ linkfilestest │ cyber                   │ QmRetYSHe7E9eNuduiu9pebrMyPC7HYKfYqu9wQqAEuqKR │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
│ 3 │ cyber         │ pinned_file:cyber.txt   │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
╰─#─┴───from_text───┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy link-folder --no_content
╭─#─┬───from_text───┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ linkfilestest │ bostrom │ QmRetYSHe7E9eNuduiu9pebrMyPC7HYKfYqu9wQqAEuqKR │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ 1 │ linkfilestest │ cyber   │ QmRetYSHe7E9eNuduiu9pebrMyPC7HYKfYqu9wQqAEuqKR │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
╰─#─┴───from_text───┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy link-folder --no_folders
╭─#─┬─from_text─┬─────────to_text─────────┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ bostrom   │ pinned_file:bostrom.txt │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
│ 1 │ cyber     │ pinned_file:cyber.txt   │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │
╰─#─┴─from_text─┴─────────to_text─────────┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cd ..

> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │
│ to_text   │ bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 │
│ from      │ QmPLSA5oPqYxgc8F7EwrM8WS9vKrr1zPoDniSRFh8HSrxx │
│ to        │ QmYwEKZimUeniN7CEAfkBRHCn4phJtNoNJxnZXEAhEt3af │
╰───────────┴────────────────────────────────────────────────╯

> cy follow bostrom1h29u0h2y98rkhdrwsx0ejk5eq8wvslygexr7p8 --use_local_list_only

> cy links-clear

> cy tweet 'cyber-prophet is cool' --disable_send
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ to_text   │ cyber-prophet is cool                          │
│ from      │ QmbdH2WBamyKLPE5zu4mJ9v49qvY8BFfoumoVPMR5V4Rvx │
│ to        │ QmWm9pmmz66cq41t1vtZWoRz5xmHSmoKCrrgdP9adcpoZK │
╰───────────┴────────────────────────────────────────────────╯

> cy set-links-table-name lazy-tests-links-2

> [{from_text: 'cyber' to_text: 'bostrom'}] | cy links-replace
╭─#─┬─from_text─┬─to_text─╮
│ 0 │ cyber     │ bostrom │
╰─#─┴─from_text─┴─to_text─╯

> cy links-pin-columns | reject timestamp -i
╭─#─┬─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─#─┴─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-view | reject timestamp -i
There are 1 cyberlinks in the temp table:
╭─#─┬─from_text─┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ cyber     │ bostrom │ QmRX8qYgeZoYM3M5zzQaWEpVFdpin6FvVXvp6RPQK3oufV │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─#─┴─from_text─┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-link-all 'cy testing script'
╭─#─┬─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─#─┴─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy links-view | reject timestamp -i
There are 1 cyberlinks in the temp table:
╭─#─┬─────from_text─────┬─to_text─┬──────────────────────from──────────────────────┬───────────────────────to───────────────────────╮
│ 0 │ cy testing script │ bostrom │ QmdMy9SGd3StRUXoEX4BZQvGsgW6ejn4gMCT727GypSeZx │ QmU1Nf2opJGZGNWmqxAa9bb8X6wVSHRBDCY6nbm3RmVXGb │
╰─#─┴─────from_text─────┴─to_text─┴──────────────────────from──────────────────────┴───────────────────────to───────────────────────╯

> cy config-activate 42gboot+cyber

> cy link-random 3 | to yaml
empty answer:
[]
empty answer:
[]
- from_text: quote
  to_text: |
    text: The trouble with most people is that they think with their hopes or fears or wishes rather than with their minds.
    author: Will Durant
    source: https://forismatic.com
  from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
  to: QmSfsJYQLtMS844kPPcvc9DsRSRhRdpMfZg9yVreUBbTEX

> cy link-random 3 --source forismatic.com | to yaml
- from_text: quote
  to_text: |
    text: Things do not change; we change.
    author: Henry Thoreau
    source: https://forismatic.com
  from: QmR7zZv2PNo477ixpKBVYVUoquxLVabsde2zTfgqgwNzna
  to: QmYy2TLDaqvqFmEamkfaF5SuKJRUr2tHUCj3cghfQpDsL5

> cy link-random 3 --source chucknorris.io | to yaml
- from_text: chuck norris
  to_text: |
    text: As a polite act of courtesy, Chuck Norris always brings his own Molotov to his neighborhood cocktail parties.
    source: https://chucknorris.io
  from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
  to: QmYDQw98gdphPFdECmzgWDwUx6Sm1Gon9Ua2NrAM6WMxt9
- from_text: chuck norris
  to_text: |
    text: Chuck Norris can gag you with a horrendous stinch simply by typing the word "fart" on his computer keyboard.
    source: https://chucknorris.io
  from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
  to: Qmf8h8kjT8KFihHCWsowpRyupwjHdaTxJ14XHFUSZarGay
- from_text: chuck norris
  to_text: |
    text: In the DC comics, the only known thing to break a panel's lines is the beard of Chuck Norris.
    source: https://chucknorris.io
  from: QmXL2fdBAWHgpot8BKrtThUFvgJyRmCWbnVbbYiNreQAU1
  to: QmNMmExyeUr6HB4pU57L2iLUX8PJVfDEwiKNEuWZdVHtSh

> cy links-remove-existed-1by1
3 2 5 4 6 0 7 8 1 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44
38 cyberlinks was/were already created by
bostrom166tas63rcdezv35jycr8mlfr0qgjdm7rgpzly5
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1483                                           │
│ from      │ QmP1cSbc8ZC11DWMLBW5GC7qqNSfqhVgJ4aqtdZ284Ykau │
│ to_text   │ 982                                            │
│ to        │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 982                                            │
│ from      │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │
│ to_text   │ 1471                                           │
│ to        │ QmUKENavbrxPeBa2krN7jiozBSszbXRENB59qqbGJtx5cR │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1471                                           │
│ from      │ QmUKENavbrxPeBa2krN7jiozBSszbXRENB59qqbGJtx5cR │
│ to_text   │ 195                                            │
│ to        │ QmYTkmKghJGoBcQmupqFwMTFZZXwzRKuE9EGtZZmHGAX7T │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 195                                            │
│ from      │ QmYTkmKghJGoBcQmupqFwMTFZZXwzRKuE9EGtZZmHGAX7T │
│ to_text   │ 1427                                           │
│ to        │ QmZuyMxDLKQMET3XTDzDYjquse89xn47PdRmqE6ziFCzA1 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1427                                           │
│ from      │ QmZuyMxDLKQMET3XTDzDYjquse89xn47PdRmqE6ziFCzA1 │
│ to_text   │ 2054                                           │
│ to        │ QmVXFuHgp6P9WGRWTvAhvThbBipkzQNDHM2gcryB4E5fFi │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 2054                                           │
│ from      │ QmVXFuHgp6P9WGRWTvAhvThbBipkzQNDHM2gcryB4E5fFi │
│ to_text   │ 1642                                           │
│ to        │ QmcAQHNBXh9pVNucRuozaqxBYJTAvML8n2h7gGigXZKdKK │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1642                                           │
│ from      │ QmcAQHNBXh9pVNucRuozaqxBYJTAvML8n2h7gGigXZKdKK │
│ to_text   │ 358                                            │
│ to        │ QmQgpSPrG7SCntyzZCS6ibQQew3ctztctrLPVzRA6PqZyq │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 358                                            │
│ from      │ QmQgpSPrG7SCntyzZCS6ibQQew3ctztctrLPVzRA6PqZyq │
│ to_text   │ 1712                                           │
│ to        │ QmNQQCmT8Z2EgDN5nnGe3PwJJXz7xyzhacmCfYgxrQG7cN │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1712                                           │
│ from      │ QmNQQCmT8Z2EgDN5nnGe3PwJJXz7xyzhacmCfYgxrQG7cN │
│ to_text   │ 1419                                           │
│ to        │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1419                                           │
│ from      │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │
│ to_text   │ 219                                            │
│ to        │ QmZd18vhFadcESQQb5jGt8Yone64jF6BMEhnfKPCD9PVdz │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 219                                            │
│ from      │ QmZd18vhFadcESQQb5jGt8Yone64jF6BMEhnfKPCD9PVdz │
│ to_text   │ 767                                            │
│ to        │ QmaWEi25WdRQwmkT45NBKd17YQBNVebiiXYy1KE5h34d4a │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 767                                            │
│ from      │ QmaWEi25WdRQwmkT45NBKd17YQBNVebiiXYy1KE5h34d4a │
│ to_text   │ 1419                                           │
│ to        │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1419                                           │
│ from      │ QmZMz6rXmqTfB2YD3DwCgfWPQdKdy6F4TBFvu6RfNn2pXz │
│ to_text   │ 1126                                           │
│ to        │ QmZgTTh22WKZ4pEdEptWfBwh7faeGKhuwwwZt6PaiQtUKi │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1126                                           │
│ from      │ QmZgTTh22WKZ4pEdEptWfBwh7faeGKhuwwwZt6PaiQtUKi │
│ to_text   │ 577                                            │
│ to        │ QmfX9pDq46g5QqJYqe6EWEDLMaTG6P5mw4xhGzsqnQBaU8 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 577                                            │
│ from      │ QmfX9pDq46g5QqJYqe6EWEDLMaTG6P5mw4xhGzsqnQBaU8 │
│ to_text   │ 756                                            │
│ to        │ QmRGDCLgUCh3UfGEJKADr9wKkvXuarTimqxG8fQtwJ7U7R │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 756                                            │
│ from      │ QmRGDCLgUCh3UfGEJKADr9wKkvXuarTimqxG8fQtwJ7U7R │
│ to_text   │ 141                                            │
│ to        │ QmYJgdru3bAq7xFeQsk5ywG1MnBeEc2jKzqQnvEtYmpcYP │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 141                                            │
│ from      │ QmYJgdru3bAq7xFeQsk5ywG1MnBeEc2jKzqQnvEtYmpcYP │
│ to_text   │ 622                                            │
│ to        │ QmQFbhWRKtJdpZY7vuVv3m3hgrE2cLr33C9QSU5ZZcNFgW │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 622                                            │
│ from      │ QmQFbhWRKtJdpZY7vuVv3m3hgrE2cLr33C9QSU5ZZcNFgW │
│ to_text   │ 1169                                           │
│ to        │ QmbXqs56bvnKbDm3AysmqSaZc97HBpcdhqWnpTLtzaE8Wm │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1169                                           │
│ from      │ QmbXqs56bvnKbDm3AysmqSaZc97HBpcdhqWnpTLtzaE8Wm │
│ to_text   │ 1932                                           │
│ to        │ QmQDaeGY9SAjMc9NWXA2pWR5iTUGkg35FY43GxNz3UJqZL │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1932                                           │
│ from      │ QmQDaeGY9SAjMc9NWXA2pWR5iTUGkg35FY43GxNz3UJqZL │
│ to_text   │ 407                                            │
│ to        │ QmVtvUZPa7hUd84oaTZe3ftQdLJCNPo2bHCKebXKqxex51 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 407                                            │
│ from      │ QmVtvUZPa7hUd84oaTZe3ftQdLJCNPo2bHCKebXKqxex51 │
│ to_text   │ 1880                                           │
│ to        │ Qmf3g1SM3yod9hA48nghhGdJNY6Wa9akxpnTfv4Nv1YYra │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1880                                           │
│ from      │ Qmf3g1SM3yod9hA48nghhGdJNY6Wa9akxpnTfv4Nv1YYra │
│ to_text   │ 659                                            │
│ to        │ QmagFXW5vFowXc1AXsW2afZxr6xPuRr1u1qkBPRVtComF5 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 659                                            │
│ from      │ QmagFXW5vFowXc1AXsW2afZxr6xPuRr1u1qkBPRVtComF5 │
│ to_text   │ 871                                            │
│ to        │ QmZBpypZ6SpaY7BtLZAa3XSrwcU3qGomeLkjjAZ221FSLs │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 871                                            │
│ from      │ QmZBpypZ6SpaY7BtLZAa3XSrwcU3qGomeLkjjAZ221FSLs │
│ to_text   │ 1161                                           │
│ to        │ QmVYr4ZeHCZug4AKVkYdKi3N9TYndFEbqE7GFTNjptWeRG │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1161                                           │
│ from      │ QmVYr4ZeHCZug4AKVkYdKi3N9TYndFEbqE7GFTNjptWeRG │
│ to_text   │ 1651                                           │
│ to        │ QmfSVoUJ3ZjywMGpdqiepnzfRZ84xmSXYNY2M94nbp4zhG │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1651                                           │
│ from      │ QmfSVoUJ3ZjywMGpdqiepnzfRZ84xmSXYNY2M94nbp4zhG │
│ to_text   │ 1845                                           │
│ to        │ QmY4BkaEgajwLvmm672Ev1kMQYXu4oEuPmZhqjzz5bW6w8 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1845                                           │
│ from      │ QmY4BkaEgajwLvmm672Ev1kMQYXu4oEuPmZhqjzz5bW6w8 │
│ to_text   │ 1506                                           │
│ to        │ QmWYNJKezVCN49bDZYkMbvUe12PBf6CT6xVtmuYqBNnQUB │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1506                                           │
│ from      │ QmWYNJKezVCN49bDZYkMbvUe12PBf6CT6xVtmuYqBNnQUB │
│ to_text   │ 1446                                           │
│ to        │ QmUxDFPZk6fVxuRT994YXw4Gsw9xxKR8JrY9deXFFW6CEY │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1446                                           │
│ from      │ QmUxDFPZk6fVxuRT994YXw4Gsw9xxKR8JrY9deXFFW6CEY │
│ to_text   │ 751                                            │
│ to        │ QmbDvi7Ltb632Lf88huDC2P9fTBs1mmhbgtXPyMSTn5rW4 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 751                                            │
│ from      │ QmbDvi7Ltb632Lf88huDC2P9fTBs1mmhbgtXPyMSTn5rW4 │
│ to_text   │ 1064                                           │
│ to        │ QmfCgoLmb927aTosmKF9YT8CDxYRaYX4p4FXMbRzQ2Rtmw │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1064                                           │
│ from      │ QmfCgoLmb927aTosmKF9YT8CDxYRaYX4p4FXMbRzQ2Rtmw │
│ to_text   │ 704                                            │
│ to        │ QmYh56iuccfPWBCzy7nFtEWSukVi9GP5iRtieJe1Zq9Nd6 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 704                                            │
│ from      │ QmYh56iuccfPWBCzy7nFtEWSukVi9GP5iRtieJe1Zq9Nd6 │
│ to_text   │ 1255                                           │
│ to        │ QmSiGjUtv2Kw5ZZWyBxsRvrXU68oFUSQqNF5zcX3wTQvSq │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 1255                                           │
│ from      │ QmSiGjUtv2Kw5ZZWyBxsRvrXU68oFUSQqNF5zcX3wTQvSq │
│ to_text   │ 199                                            │
│ to        │ QmbJRpuxjX8PkoPfAb2Q9JsWwt57KwLUyfLRky1Hk81fwL │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 199                                            │
│ from      │ QmbJRpuxjX8PkoPfAb2Q9JsWwt57KwLUyfLRky1Hk81fwL │
│ to_text   │ 309                                            │
│ to        │ QmYpjTnNRy357rb2QFKaSzzy7ypmdTkJ7MAhvPfrLyv5wS │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 309                                            │
│ from      │ QmYpjTnNRy357rb2QFKaSzzy7ypmdTkJ7MAhvPfrLyv5wS │
│ to_text   │ 982                                            │
│ to        │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 982                                            │
│ from      │ QmQ3x5GTpxofn1aJbarQGQxEfUjiGzA8hm6mf6tjkFkuq1 │
│ to_text   │ 290                                            │
│ to        │ Qmdv5gEJBLwHCebimVuZ2tvZBP2wvWGi7x85TnUUUMQa3B │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 290                                            │
│ from      │ Qmdv5gEJBLwHCebimVuZ2tvZBP2wvWGi7x85TnUUUMQa3B │
│ to_text   │ 2011                                           │
│ to        │ QmQBMDnoj7mUEbjFrAxXqRQJyHAztoJTbh4nssTqGyNUHF │
╰───────────┴────────────────────────────────────────────────╯
╭───────────┬────────────────────────────────────────────────╮
│ from_text │ 2011                                           │
│ from      │ QmQBMDnoj7mUEbjFrAxXqRQJyHAztoJTbh4nssTqGyNUHF │
│ to_text   │ 211                                            │
│ to        │ QmUYbmykeoBsaYjtxi8PtJ79rW3YazTVdDDHoPqYzaVyRM │
╰───────────┴────────────────────────────────────────────────╯
So they were removed from the temp table!

╭─#──┬──from_text───┬─────────────────────────────────────────────────────────to_text─────────────────────────────────────────────────────────┬───────────from───────────┬─to─┬─timestamp─┬link_exist╮
│ 38 │ quote        │ text: The trouble with most people is that they think with their hopes or fears or wishes rather than with their minds. │ QmR7zZv2PNo477ixpKBVY... │ .. │ 202408... │ false    │
│    │              │ author: Will Durant                                                                                                     │                          │    │           │          │
│    │              │ source: https://forismatic.com                                                                                          │                          │    │           │          │
│    │              │                                                                                                                         │                          │    │           │          │
│ 39 │ quote        │ text: Things do not change; we change.                                                                                  │ QmR7zZv2PNo477ixpKBVY... │ .. │ 202408... │ false    │
│    │              │ author: Henry Thoreau                                                                                                   │                          │    │           │          │
│    │              │ source: https://forismatic.com                                                                                          │                          │    │           │          │
│    │              │                                                                                                                         │                          │    │           │          │
│ 40 │ quote        │ text: Things do not change; we change.                                                                                  │ QmR7zZv2PNo477ixpKBVY... │ .. │ 202408... │ false    │
│    │              │ author: Henry Thoreau                                                                                                   │                          │    │           │          │
│    │              │ source: https://forismatic.com                                                                                          │                          │    │           │          │
│    │              │                                                                                                                         │                          │    │           │          │
│ 41 │ quote        │ text: Things do not change; we change.                                                                                  │ QmR7zZv2PNo477ixpKBVY... │ .. │ 202408... │ false    │
│    │              │ author: Henry Thoreau                                                                                                   │                          │    │           │          │
│    │              │ source: https://forismatic.com                                                                                          │                          │    │           │          │
│    │              │                                                                                                                         │                          │    │           │          │
│ 42 │ chuck norris │ text: As a polite act of courtesy, Chuck Norris always brings his own Molotov to his neighborhood cocktail parties.     │ QmXL2fdBAWHgpot8BKrtT... │ .. │ 202408... │ false    │
│    │              │ source: https://chucknorris.io                                                                                          │                          │    │           │          │
│    │              │                                                                                                                         │                          │    │           │          │
│ 43 │ chuck norris │ text: Chuck Norris can gag you with a horrendous stinch simply by typing the word "fart" on his computer keyboard.      │ QmXL2fdBAWHgpot8BKrtT... │ .. │ 202408... │ false    │
│    │              │ source: https://chucknorris.io                                                                                          │                          │    │           │          │
│    │              │                                                                                                                         │                          │    │           │          │
│ 44 │ chuck norris │ text: In the DC comics, the only known thing to break a panel's lines is the beard of Chuck Norris.                     │ QmXL2fdBAWHgpot8BKrtT... │ .. │ 202408... │ false    │
│    │              │ source: https://chucknorris.io                                                                                          │                          │    │           │          │
│    │              │                                                                                                                         │                          │    │           │          │
╰─#──┴──from_text───┴─────────────────────────────────────────────────────────to_text─────────────────────────────────────────────────────────┴───────────from───────────┴─to─┴─timestamp─┴─link_exi─╯

> cy links-publish
2 links from initial data were removed, because they were obsolete
╭─#─┬────────────────────cy────────────────────┬──────────────────────────────txhash──────────────────────────────╮
│ 0 │ 5 cyberlinks should be successfully sent │ 2DB181831E9CA7A31249E71AFF36CFA90004CFA772C6657B85447A4BC5B23FBB │
╰─#─┴────────────────────cy────────────────────┴──────────────────────────────txhash──────────────────────────────╯
```
