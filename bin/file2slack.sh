#!/bin/bash

API_URL="https://slack.com/api/files.upload"
CHANNEL="#swfz"

# curl -F content="$(cat -)" -F channels=#swfz -F token=${TOKEN} ${API_URL}
# curl -F file=@${1} -F channels=#swfz -F token=${TOKEN} ${API_URL}

post2slack(){
  echo ${FILE}

  if [ -n "${FILE}" ]; then
    curl -F file=@${FILE} -F channels=${CHANNEL} -F token=${SLACK_WEB_API_TOKEN} ${API_URL}
  else
    curl -F content="$(cat -)" -F channels=${CHANNEL} -F token=${SLACK_WEB_API_TOKEN} ${API_URL}
  fi
}

_usage(){
cat << EOS
usage:
  ./file2slack.sh

  environment SLACK_WEB_API_TOKEN is required.
  prease set SLACK_WEB_API_TOKEN

  export SLACK_WEB_API_TOKEN=*****

options)
  -f : filename (if this option is not exist, to post the stdin.)
  -c : post channel
EOS
  exit 1
}

main(){
  while getopts hc:f:u: opt
  do
    case ${opt} in
      h)
        _usage;;
      c)
        CHANNEL=${OPTARG};;
      f)
        FILE=${OPTARG};;
      :|\?) _usage;;
    esac
  done

  post2slack
}

main $@


