#/bin/bash
docker kill alpine
docker rm alpine
docker build --no-cache  ./ -t alpine
docker run --rm -d --name alpine -p 8081:80 alpine  
