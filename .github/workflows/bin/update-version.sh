#!/bin/bash -e

# require jq yq
# $1 peco
# $2 peco/peco
# $3 normal : latest-version-extract type

echo $1
echo $2

got=`yq r ./ansible/versions_vars.yml $1_version`
latest=`./.github/workflows/bin/latest-version-$3.sh $2`

echo "got: $got"
echo "latest: $latest"

if [[ "$got" != "$latest" ]]; then
  echo "found ahead versions"
  yq w -i ./ansible/versions_vars.yml $1_version $latest
fi

if [[ -z "$(git status ./ansible/versions_vars.yml --porcelain)" ]]; then
  echo "$1 is latest version"
else
  branch="versionup/$1-$latest"

  git fetch
  if [[ -z "$(git branch -a | grep ${branch})" ]]; then
    git config --global user.email sawafuji.09@gmail.com
    git config --global user.name swfz
    git checkout -b ${branch}
    git add ./ansible/versions_vars.yml
    git commit -m "[versionup] $1 $got to $latest"
    git push https://${GITHUB_USER_NAME}:${GITHUB_TOKEN}@github.com/swfz/dotfiles.git HEAD:${branch}
    # ./.github/workflows/bin/create_pr.sh ${branch}
  else
    echo "${branch} is exist."
  fi
fi
