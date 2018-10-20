#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR
mynet=$1

if [ "${mynet}" == "" ]; then
  printf "FAIL: network not provided\n";
  exit 1;
else
  printf "deleting network: ${mynet}\n";
fi

tmpfile=$(mktemp /tmp/docker.network.inspect.XXXXXX)

x=1
while [ $x -le 3 ]; do
  x=$(( $x + 1 ))
  docker network inspect ${mynet} --format='{{range $i, $c := .Containers}} {{$i}} {{end}}' | tr ' ' '\n' | sed 's/ //g;/^$/d' > $tmpfile
  if [ -f "$tmpfile" ] && [ -s "$tmpfile" ]; then
    while read p; do
      printf "removing container: $p\n";
      docker stop "$p";
      docker rm "$p";
    done < $tmpfile
    rm -rf $tmpfile;
  else
    printf "no live containers found\n";
    rm -rf $tmpfile;
    printf "removing container network: ${mynet}\n";
    docker network rm ${mynet}
    exit 0;
  fi
done
exit 0;
