#!/bin/bash

# $1 peco/peco

curl -s https://api.github.com/repos/$1/releases | jq -r '.[]|.name' | sed 's/v//' | head -n 1
