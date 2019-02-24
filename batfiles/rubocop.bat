@echo off
wsl ~/.anyenv/envs/rbenv/shims/rubocop $^(echo '%*' ^| sed -e 's^|\\^|/^|g' -e 's^|\^([A-Za-z]\^)\:/\^(.*\^)^|/mnt/\L\1\E/\2^|g'^)
@echo on
