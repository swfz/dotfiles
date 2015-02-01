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
  echo -e "$bgcolor $server $RESET $num\t\c"
}

metric(){
  server=$1
  num=`ssh $server "$COMMAND"`
  num=`expr $num % 10`

  echo -e "\033[K\c"
  echo_server $server $BGBLUE $num

  [ $num -lt $SHRESHOLD ] && COLOR="$FGRED" || COLOR="$FGCYAN"
  echo -e "$COLOR\c"
  echo_length "#" $num
  echo -e "$RESET"

}

clear
while true
do
  for server in ${SERVERS[@]}
  do
    metric $server
  done
  sleep 1
  echo -e "\033[0;0H\c"
  # clear
done

