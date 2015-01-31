#!bin/sh

SERVERS=( 192.168.70.11 192.168.70.12 192.168.70.14 )
COMMAND="ps aux | wc -l"
SHRESHOLD=5
FGRED="$(tput setaf 1)"
FGCYAN="$(tput setaf 6)"
BGBLUE="$(tput setab 4)"
RESET="$(tput sgr0)"


echo_length(){
  char="$1"
  length="$2"
  i=0
  while [ $i -lt $length ]
  do
    echo -e "$char\c"
    i=`expr $i + 1`
  done
}

echo_server(){
  server=$1
  bgcolor=$2
  num=$3
  echo -e "$bgcolor $server $RESET $num\c"
}

metric(){
  server=$1
  num=`ssh $server "$COMMAND"`
  num=`expr $num % 10`

  echo_server $server $BGBLUE $num

  if [ $num -lt ${before_["$server"]} ]; then
    echo_length " " ${before_["$server"]}
    echo_server $server $BGBLUE $num
  fi

  [ $num -lt $SHRESHOLD ] && COLOR="$FGRED" || COLOR="$FGCYAN"
  echo -e "$COLOR\c"
  echo_length "#" $num
  echo -e "$RESET"

  before_["$1"]=$num
}

declare -A before_
while true
do
  for server in ${SERVERS[@]}
  do
    before_["$server"]=0
    metric $server
  done
  sleep 1
  clear
done

