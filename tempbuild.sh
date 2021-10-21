#/bin/bash
docker kill alpine
docker rm alpine
docker rmi alpine

docker build --no-cache  ./ -t alpine
docker run --name alpine -p 8081:80 alpine  
#docker run -it --entrypoint bash -d --name alpine -p 8081:80 alpine

