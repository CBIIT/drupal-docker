#/bin/bash
docker kill alpine
docker rm alpine
docker build --no-cache  ./ -t alpine
docker run -it --name alpine -p 8081:80 --entrypoint bash alpine  
