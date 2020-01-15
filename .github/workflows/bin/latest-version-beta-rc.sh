#!/bin/bash

# $1 peco/peco

curl -s https://api.github.com/repos/$1/releases | jq -r '.[]|select((contains({name: "rc"})|not) and (contains({name: "beta"})|not))|.name' | head -n 1
