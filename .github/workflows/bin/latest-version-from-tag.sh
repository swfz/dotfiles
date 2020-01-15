#!/bin/bash

# $1 peco/peco

curl -s https://api.github.com/repos/$1/tags | jq -r '.[]|select((contains({name: "rc"})|not) and (contains({name: "test"})|not) and (contains({name: "real"})|not))|.name' | head -n 1
