#!/bin/bash

# $1 peco/peco

curl -s https://api.github.com/repos/$1/releases | jq -r '.[]|.name' | sed 's/Release \|Jo \|jq \|tmux //' | head -n 1
