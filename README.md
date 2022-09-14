# How to use
## docker run
To use docker run execute the following command with variables that reflect your current setup.
```sh
docker run -d --name alpine -p 8081:80 -e sitename=webteam -e dbhost=192.168.0.178 -e dbport=3306 -e dbuser=root -e dbpass=password -e dbname=webteam -e user=admin -e pass=1234 alpine
```

## docker-compose
Modify the docker-compose.yml file to add environment variables that reflect your current setup.

To start a brand new site (note: running this command will remove the existing container if it exists so be careful):
```sh
docker-compose up
```

To start an existing site:
```sh
docker-compose start
```

To sopo an existing site:
```sh
docker-compose stop
```
