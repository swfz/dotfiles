#!/bin/bash

# $1 peco/peco
# 3.7c のような英字付きや 3.8-rc のようなプレリリースは除き、数字のみのバージョンを対象にする

curl -s https://api.github.com/repos/"$1"/releases | jq -r '.[]|.name' | sed 's/Release v\|Jo \|jq \|tmux //' | grep -E '^[0-9]+(\.[0-9]+)*$' | head -n 1
