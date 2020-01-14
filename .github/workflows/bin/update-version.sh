#!/bin/bash

# require jq yq
# $1 peco
# $2 peco/peco

echo $1
echo $2

# got=`cat ./ansible/versions_vars.yml | jq --yaml-input --yaml-output ".$1_version" `
got=`yq r ./ansible/versions_vars.yml $1_version`
latest=`curl -s https://api.github.com/repos/$2/releases | jq -r '.[]|select(contains({name: "v"}))|.name' | head -n 1`

echo "got: $got"
echo "latest: $latest"

if [[ "$got" != "$latest" ]]; then
  echo "found ahead versions"
  # cat ./ansible/versions_vars.yml | jq --yaml-input --yaml-output ".$1_version=\"$latest\"" > ./ansible/versions_vars.yml 2>&1
  yq w -i ./ansible/versions_vars.yml $1_version $latest
fi

if [[ -z "$(git status ./ansible/versions_vars.yml --porcelain)" ]]; then
  echo "$1 is latest version"
else
  branch="versionup/$1-$latest"
  git config --global user.email sawafuji.09@gmail.com
  git config --global user.name swfz
  git checkout -b ${branch}
  git add ./ansible/versions_vars.yml
  git commit -m "[versionup] $1 $got to $latest"
  git push https://${GITHUB_USER_NAME}:${GITHUB_TOKEN}@github.com/swfz/dotfiles.git HEAD:${branch}
fi
