#/bin/bash
docker kill alpine
docker rm alpine
docker build --no-cache  ./ -t alpine
docker run --name alpine -p 8081:80 alpine  
