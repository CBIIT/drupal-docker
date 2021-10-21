#/bin/bash
docker kill alpine
docker rm alpine
docker rmi alpine

docker build --no-cache  ./ -t alpine
docker run --name alpine -p 8081:80 -e sitename=webteam -e dbhost=192.168.0.178 -e dbuser=root -e dbpass=password -e dbname=webteam -e user=admin -e pass=1234 alpine
#docker run -it --entrypoint bash -d --name alpine -p 8081:80 alpine

