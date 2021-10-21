#/bin/bash
docker kill alpine
docker rm alpine

if [[ -z $1 ]]; then
  docker run --name alpine -p 8081:80 alpine
else
  docker run --name alpine -p 8081:80 -e sitename=$1 -e dbname=$2 alpine
fi


